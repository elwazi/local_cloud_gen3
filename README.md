# eLwazi / GeneMap Gen3

Infrastructure-as-code for deploying a private genomic data management platform on OpenStack. The deployment pipeline is Packer (image building) → Terraform (cloud provisioning) → Ansible (service configuration), with ArgoCD providing continuous reconciliation of Gen3 services inside the RKE2 Kubernetes cluster.

## Requirements

Install [Packer](https://developer.hashicorp.com/packer/install) and [Terraform](https://developer.hashicorp.com/terraform/install).

Install Python dependencies (Ansible, OpenStack client):

```shell
uv sync
```

## First-time setup

### 1. OpenStack credentials

Download the `*-openrc.sh` file from your OpenStack dashboard (top-right dropdown → OpenStack RC File). Source it before any cloud operations:

```shell
source eLwazi-openrc.sh
```

### 2. Packer/Terraform configuration (`variables.auto.hcl`)

```shell
cp variables.auto.hcl.template variables.auto.hcl
```

The repo includes symlinks `variables.auto.tfvars` and `variables.auto.pkrvars.hcl` pointing at this file so Terraform and Packer both pick it up automatically. Edit it with values for your environment:

**Infrastructure**
- `admin_user` — VM login name
- `base_image_source` / `base_image_source_format` — source Ubuntu 24.04 image
- `build_image_flavour` — VM flavour used during Packer builds
- `floating_ip_network_id` / `floating_ip_pool_name` — OpenStack floating IP settings
- `network_ids` / `security_groups` — OpenStack network/security group IDs
- `name_prefix` / `node_suffix` / `image_suffix` — naming conventions
- `timezone` — e.g. `Africa/Johannesburg`
- `ssh_private_key_file` — path to the SSH private key file; the public key is derived from `ssh_private_key_file.pub`

**Node sizing**
- `database_node_flavour` / `database_node_disk_size_gib`
- `rancher_rke2_server_node_count` / `rancher_rke2_server_node_flavour` / `rancher_rke2_server_node_disk_size_gib`
- `rancher_rke2_worker_node_count` / `rancher_rke2_worker_node_flavour` / `rancher_rke2_worker_node_disk_size_gib`
- `load_balancer_node_flavour`
- `storage_node_flavour` / `storage_node_disk_size_gib`

**Gen3**
- `gen3_hostname` — public hostname
- `gen3_user` — Linux account for Gen3 (default: `gen3`)
- `gen3_admin_email`

**Authentication & secrets**
- `google_client_id` / `google_client_secret` — Google OIDC credentials
- `postgres_user` / `postgres_password`
- `garage_rpc_secret` — generate: `openssl rand -hex 32`
- `garage_access_key` — generate: `openssl rand -hex 16`
- `garage_secret_key` — generate: `openssl rand -hex 32`

### 3. Ansible configuration (`group_vars/all`)

```shell
cp group_vars/all.template group_vars/all
```

This file is gitignored. Edit it to set:

**Users** — identities with access to the platform:

```yaml
gen3_users:
  - email: user@example.com
    name: User Name
    groups: [data_submitters, data_readers, indexd_admins]
    policies: [SickleInAfrica_submitter]
```

See `group_vars/all.template` for the full field reference.

**Portal branding:**

```yaml
gen3_portal:
  appName: "My Data Commons"
  nav_title: "MyCommons"
  heading: "Welcome"
  intro_text: "Browse and submit genomic datasets."
  login_title: "My Data Commons"
  login_subtitle: "Supporting genomic research"
  login_text: "Please log in with your institutional Google account."
  logo_file: my_logo.png        # file in roles/gen3/files/portal/
  css: |
    .nav-bar { background-color: #C52D3A !important; }
  sponsors:
    - file: sponsor.svg
      href: https://example.org
      alt: Sponsor Name
```

Portal image assets (logo, favicon, createdby, sponsor logos) live in `roles/gen3/files/portal/`. Drop a file there, reference it by filename in `group_vars/all`, and redeploy.

### 4. Initialise Packer plugins (once)

```shell
packer init images.openstack.pkr.hcl
```

## Deploy

### Build OpenStack images

```shell
./build.sh
```

Safe to re-run — checks for existing images before building.

### Provision infrastructure

```shell
terraform init   # first time only
terraform apply
```

Generates `inventory.yaml` for Ansible. Do not edit it manually.

### Configure all services

```shell
./deploy.sh
```

Runs Ansible playbooks in order:

| Step | Playbooks | Mode |
|------|-----------|------|
| 1 | `common.yml` | sequential |
| 2 | `database.yml`, `storage.yml`, `load_balancer.yml`, `rancher.yml` | parallel |
| 3 | `argocd.yml` | sequential |
| 4 | `gen3.yml` | sequential |

Logs for the parallel step are written to `logs/`.

## Routine updates

After the initial deploy, use `update.sh` for day-to-day changes — it re-uploads `user.yaml` to S3 and re-applies the ArgoCD Application:

```shell
./update.sh
```

Scope it further with tags:

```shell
./update.sh --tags user    # users only (re-upload user.yaml)
./update.sh --tags argocd  # Helm values / portal branding only
./update.sh --check        # dry run
```

## Managing users

Edit `gen3_users` in `group_vars/all`, then:

```shell
./update.sh --tags user
```

Fence's usersync job polls the S3 bucket on a schedule and applies changes.

## Creating programs and projects

Before data can be submitted, at least one program and project must exist in Sheepdog. Download a credentials JSON from the Gen3 portal (Profile → Create API key), then:

```shell
# Check your admin access
uv run python create_gen3_project.py --endpoint https://<gen3_hostname> whoami

# List existing programs and projects
uv run python create_gen3_project.py --endpoint https://<gen3_hostname> list

# Create a program, then a project within it
uv run python create_gen3_project.py --endpoint https://<gen3_hostname> create --program MyProgram
uv run python create_gen3_project.py --endpoint https://<gen3_hostname> create --program MyProgram --project MyProject
```

By default the script looks for credentials at `~/.gen3/credentials.json`. Pass `--credentials /path/to/creds.json` to override.

## Checking ArgoCD sync status

```shell
kubectl get application gen3 -n argocd
kubectl get application gen3 -n argocd -o jsonpath='{.status.sync.status} {.status.health.status}{"\n"}'
```
