# Gen3 Deployment Debug Notes

## fence CrashLoopBackOff — JWT key write permission error

### Symptom

`fence-deployment` and `presigned-url-fence-deployment` pods crash immediately with:

```
/bin/bash: line 2: /var/www/fence/fence-config.yaml: Read-only file system
/bin/bash: line 4: /fence/keys/key/jwt_public_key.pem: Permission denied
```

Full traceback ends with:

```
File "/fence/fence/jwt/keys.py", line 165, in from_directory
    with open(pub_filepath, "w") as f:
PermissionError: [Errno 13] Permission denied: '/fence/keys/key/jwt_public_key.pem'
```

### Root cause

Affects **gen3 chart 0.1.34** (and earlier). The chart auto-generates the `fence-jwt-keys`
Secret containing **only** `jwt_private_key.pem`, then mounts it directly at
`/fence/keys/key/` (read-only). The `fence` image derives the RSA public key at startup
and unconditionally tries to write it to `/fence/keys/key/jwt_public_key.pem` — which
always fails because Secret volume mounts are read-only.

Confirmed:

```bash
bin/kubectl get secret fence-jwt-keys -n gen3 -o jsonpath='{.data}' \
  | python3 -c "import sys,json; print(list(json.load(sys.stdin).keys()))"
# ['jwt_private_key.pem']   <-- only the private key, public key missing
```

### Fix — upgrade the chart (recommended)

Upstream fixed this in **fence chart 0.1.67** (gen3 chart ≥ 0.3.x, released Dec 2025).
The new chart version no longer mounts the Secret at `/fence/keys/key/`. Instead it mounts
the Secret read-only at `/tmp/keys/readonly/` and the container's startup script copies
and derives the public key into a writable path:

```bash
mkdir -p /fence/keys/key
cp /tmp/keys/readonly/jwt_private_key.pem /fence/keys/key/jwt_private_key.pem
openssl rsa -in /fence/keys/key/jwt_private_key.pem -pubout > /fence/keys/key/jwt_public_key.pem
```

No volume patching or ArgoCD workarounds are needed.

**Steps:**

1. Update `gitops/gen3/Chart.yaml` dependency version from `"0.1.34"` to `"0.3.36"` (or
   latest — check https://github.com/uc-cdis/gen3-helm/releases).
2. Run `helm dependency update gitops/gen3/` to pull the new chart.
3. Commit and push; ArgoCD will sync and redeploy.

### Workaround — if stuck on chart 0.1.34

If upgrading is not immediately possible, patch the Deployment to give fence a writable
keys directory and prevent ArgoCD from reverting the patch.

**Part 1 — patch fence-deployment** (run on the gen3 host):

```bash
bin/kubectl get deployment fence-deployment -n gen3 -o json \
  | python3 -c "
import sys, json
d = json.load(sys.stdin)
spec = d['spec']['template']['spec']

spec['volumes'].append({'name': 'fence-keys-writable', 'emptyDir': {}})

spec.setdefault('initContainers', []).append({
  'name': 'fence-keys-init',
  'image': 'busybox:latest',
  'command': ['sh', '-c', 'cp /keys-secret/jwt_private_key.pem /keys-writable/'],
  'volumeMounts': [
    {'name': 'fence-jwt-keys', 'mountPath': '/keys-secret', 'readOnly': True},
    {'name': 'fence-keys-writable', 'mountPath': '/keys-writable'}
  ]
})

for c in spec['containers']:
  if c['name'] == 'fence':
    for vm in c['volumeMounts']:
      if vm['name'] == 'fence-jwt-keys':
        vm['name'] = 'fence-keys-writable'
        vm.pop('readOnly', None)

print(json.dumps(d))
" | bin/kubectl apply -f -
```

Apply the same patch to `presigned-url-fence-deployment`.

**Part 2 — add `ignoreDifferences` to the ArgoCD Application** so self-healing doesn't revert the patch.

In `roles/gen3/templates/argocd-application.yaml.j2`, add after `syncPolicy`:

```yaml
  ignoreDifferences:
    - group: apps
      kind: Deployment
      namespace: gen3
      jqPathExpressions:
        - .spec.template.spec.volumes
        - .spec.template.spec.initContainers
        - '.spec.template.spec.containers[] | select(.name=="fence") | .volumeMounts'
```

---

## Other issues encountered during initial deployment

### `dbcreated` key missing in fence-dbcreds

```
Warning  Failed  24m  kubelet  Error: couldn't find key dbcreated in Secret gen3/fence-dbcreds
```

Harmless warning — fence-init's `fence-create migrate` still completes successfully and the DB migration runs fine.

### fence-jwt-keys FailedMount on first start

```
Warning  FailedMount  kubelet  MountVolume.SetUp failed for volume "fence-jwt-keys":
  failed to sync secret cache: timed out waiting for the condition
```

Transient — resolves on retry. Not the root cause of CrashLoopBackOff.

### useryaml job CrashLoopBackOff

The `useryaml` Job (runs `fence-create sync` to load user.yaml into fence DB) also crashes because it depends on fence being healthy. Fix fence first; useryaml should succeed once fence is up.

---

## Reset procedure

```bash
# 1. Delete namespaces
bin/kubectl delete namespace gen3 argocd --wait

# 2. Drop postgres roles (databases must be dropped first)
ansible -i inventory.yaml database_nodes -m shell \
  -a "sudo -u postgres psql -c 'DROP DATABASE IF EXISTS fence_gen3' \
      -c 'DROP DATABASE IF EXISTS arborist_gen3' \
      -c 'DROP DATABASE IF EXISTS indexd_gen3'" -b

ansible -i inventory.yaml database_nodes -m shell \
  -a "sudo -u postgres psql -c 'DROP ROLE IF EXISTS fence_gen3, arborist_gen3, indexd_gen3;'" -b

# 3. Redeploy
ansible-playbook -i inventory.yaml argocd.yml gen3.yml

# 4. Watch db-create jobs
bin/kubectl get jobs -n gen3 -w
```
