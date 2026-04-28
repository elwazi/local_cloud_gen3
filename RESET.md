# Gen3 Reset & Restart Procedures

Operations are ordered from least to most destructive.

**Key facts:**
- **Database** — PostgreSQL on a dedicated OpenStack VM (`gen3-database.genemap`). Not containerised.
- **Object storage** — Garage (S3-compatible) on a separate VM. One active bucket: `genemap.ilifu.ac.za-data-bucket`.
- **`gen3-db-creds`** — Kubernetes Secret applied by Ansible, not managed by ArgoCD. Must be re-applied after any namespace delete or the dbcreate jobs will fail.

---

## Non-destructive

### Restart a single service

```bash
bin/kubectl rollout restart deployment/<name>-deployment -n gen3
# e.g. fence-deployment, portal-deployment, peregrine-deployment
```

### Restart all gen3 pods

```bash
bin/kubectl rollout restart deployment -n gen3
```

### Force ArgoCD sync

```bash
bin/kubectl -n argocd patch application gen3 --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

Or with the ArgoCD CLI:

```bash
argocd app sync gen3
```

### Update the ArgoCD Application manifest

Required after changing `roles/gen3/templates/argocd-application.yaml.j2` (e.g. adding
a new values file). ArgoCD does not manage this manifest — Ansible applies it.

```bash
ansible-playbook -i inventory.yaml gen3.yml
```

### Force a usersync run

```bash
bin/kubectl create job -n gen3 --from=cronjob/usersync usersync-manual-$(date +%s)
```

---

## Namespace reset — keeps database and S3

Use when pods are broken but data is intact. ArgoCD self-heal recreates all
Helm-managed resources, but `gen3-db-creds` is Ansible-managed so `gen3.yml` must
re-apply it after the namespace is gone.

```bash
# 1. Delete the gen3 namespace
bin/kubectl delete namespace gen3 --wait

# 2. Re-apply gen3-db-creds and trigger ArgoCD sync
ansible-playbook -i inventory.yaml gen3.yml
```

To also reinstall ArgoCD:

```bash
bin/kubectl delete namespace gen3 argocd --wait
ansible-playbook -i inventory.yaml argocd.yml gen3.yml
```

---

## Full reset — drops database, keeps S3

Use for a clean slate. Drop databases **after** deleting the namespace — active
connections block `DROP DATABASE`.

```bash
# 1. Delete namespaces
bin/kubectl delete namespace gen3 argocd --wait

# 2. Drop all gen3 databases
ansible -i inventory.yaml database_nodes -m shell -b \
  -a "sudo -u postgres psql -tc \
      \"SELECT 'DROP DATABASE IF EXISTS ' || quote_ident(datname) || ';' \
        FROM pg_database WHERE datname LIKE '%\_gen3'\" \
      | sudo -u postgres psql"

# 3. Drop all gen3 roles
ansible -i inventory.yaml database_nodes -m shell -b \
  -a "sudo -u postgres psql -tc \
      \"SELECT 'DROP ROLE IF EXISTS ' || quote_ident(rolname) || ';' \
        FROM pg_roles WHERE rolname LIKE '%\_gen3'\" \
      | sudo -u postgres psql"

# 4. Redeploy
ansible-playbook -i inventory.yaml argocd.yml gen3.yml

# 5. Watch db-create jobs before checking other pods
bin/kubectl get jobs -n gen3 -w
```

---

## Nuclear reset — drops database and S3

All data is lost.

```bash
# 1–4. Same as full reset above

# 5. Wipe the data bucket (run on the gen3 host as the gen3 user)
s3cmd del --recursive --force s3://genemap.ilifu.ac.za-data-bucket/

# 6. Redeploy
ansible-playbook -i inventory.yaml argocd.yml gen3.yml
```
