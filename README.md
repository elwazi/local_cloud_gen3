# eLwazi / GeneMap Gen3

Infrastructure-as-code for deploying eLwazi/GeneMap Gen3 — a private genomic data management platform on OpenStack. The deployment pipeline is Packer (image building) → Terraform (cloud provisioning) → Ansible (service configuration), with ArgoCD providing GitOps-based continuous reconciliation of Gen3 services.

# Setting up the infrastructure on OpenStack

## Software requirements

Install [Packer](https://developer.hashicorp.com/packer/install) and [Terraform](https://developer.hashicorp.com/terraform/install) using your OS package manager or the official binaries.

Install Ansible and the OpenStack client via pip:

```shell
pip install ansible python-openstackclient
```

### Initialise Packer plugins

Run once to install the OpenStack plugin:

```shell
packer init images.openstack.pkr.hcl
```

## OpenStack credentials

Download the `*-openrc.sh` file from your OpenStack dashboard (top-right dropdown → OpenStack RC File). Source it before running any cloud operations:

```shell
source eLwazi-openrc.sh
```

You will be prompted for your OpenStack password. All subsequent Packer, Terraform, and Ansible commands require this environment to be set.

## Setting up variables

Two files must be created from their templates before deploying.

### Packer and Terraform (`variables.auto.hcl`)

```shell
cp variables.auto.hcl.template variables.auto.hcl
```

Symlinks `gen3.auto.tfvars` and `gen3.auto.pkrvars.hcl` point at this file so both Packer and Terraform pick it up automatically.

Edit `variables.auto.hcl` with values for your environment. All variables are defined in `variables.hcl`. The variables to configure are:

**Infrastructure**
* `admin_user` — login name for the admin user
* `image_suffix` — suffix appended to all built image names
* `base_image_source` — source URL for the base Ubuntu 24.04 image
* `base_image_source_format` — image format (`qcow2`)
* `build_image_flavour` — VM flavour used when building images with Packer
* `floating_ip_network_id` — OpenStack floating IP network ID
* `floating_ip_pool_name` — OpenStack floating IP pool name
* `network_ids` — list of OpenStack network IDs to attach nodes to
* `security_groups` — list of security group IDs
* `name_prefix` — prefix applied to all infrastructure names
* `node_suffix` — suffix appended to node hostnames
* `timezone` — timezone for all VMs (e.g. `Africa/Johannesburg`)
* `ssh_public_key` — SSH public key for admin access

**Node sizing**
* `database_node_flavour` — VM flavour for the PostgreSQL node
* `database_node_disk_size_gib` — database node volume size (default: 40)
* `rancher_rke2_server_node_count` — number of RKE2 server nodes (default: 3)
* `rancher_rke2_worker_node_count` — number of RKE2 worker nodes (default: 2)
* `rancher_rke2_server_node_flavour` — VM flavour for RKE2 server nodes
* `rancher_rke2_worker_node_flavour` — VM flavour for RKE2 worker nodes
* `rancher_rke2_server_node_disk_size_gib` — RKE2 server volume size (default: 80)
* `rancher_rke2_worker_node_disk_size_gib` — RKE2 worker volume size (default: 160)
* `load_balancer_node_flavour` — VM flavour for the load balancer node
* `storage_node_flavour` — VM flavour for the Garage S3 storage node
* `storage_node_disk_size_gib` — Garage storage volume size (default: 500)

**Gen3**
* `gen3_hostname` — public hostname for the Gen3 deployment
* `gen3_user` — Linux user account for Gen3 (default: `gen3`)
* `gen3_admin_email` — admin email address

**Authentication**
* `google_client_id` / `google_client_secret` — Google OIDC credentials

**PostgreSQL**
* `postgres_user` / `postgres_password` — master PostgreSQL credentials
* `postgres_fence_password`, `postgres_peregrine_password`, `postgres_sheepdog_password`, `postgres_indexd_password`, `postgres_arborist_password`, `postgres_metadata_password`, `postgres_guppy_password`, `postgres_audit_password`, `postgres_wts_password` — per-service database passwords

**Garage S3 storage**
* `garage_rpc_secret` — Garage cluster RPC secret (generate: `openssl rand -hex 32`)
* `garage_access_key` — Garage S3 access key (generate: `openssl rand -hex 16`)
* `garage_secret_key` — Garage S3 secret key (generate: `openssl rand -hex 32`)

**Portal branding** (all have defaults)
* `gen3_portal_appName`, `gen3_portal_navigation_title`
* `gen3_portal_index_introduction_heading`, `gen3_portal_index_introduction_text`
* `gen3_portal_login_title`, `gen3_portal_login_subtitle`, `gen3_portal_login_text`, `gen3_portal_login_email`
* `gen3_portal_logo_base64_png` — portal logo as a base64-encoded PNG

### Ansible (`group_vars/all`)

```shell
cp group_vars/all.template group_vars/all
```

Edit `group_vars/all` and set:

* `argocd_repo_url` — the remote URL of this git repository (used by ArgoCD to pull `gitops/gen3/`)
* `argocd_repo_token` — a GitHub personal access token with read access, if the repository is private; leave empty for public repos

## Build and deploy

### 1. Build OpenStack images

```shell
./build.sh
```

Checks for existing images before building — safe to re-run.

### 2. Provision infrastructure

```shell
terraform init
terraform apply
```

This creates the network, security groups, and VMs, and generates `inventory.yaml` which Ansible uses. Do not edit `inventory.yaml` manually.

### 3. Configure all services

```shell
./deploy.sh
```

`deploy.sh` runs Ansible playbooks in the following order:

| Step | Playbooks | Mode |
|------|-----------|------|
| 1 | `common.yml` | sequential |
| 2 | `database.yml`, `storage.yml`, `load_balancer.yml`, `rancher.yml` | parallel |
| 3 | `argocd.yml` | sequential — installs ArgoCD on the RKE2 cluster |
| 4 | `gen3.yml` | sequential — creates Kubernetes secrets and applies the ArgoCD Application |

Logs for the parallel step are written to `logs/`.

## GitOps updates

After the first deploy, Gen3 service configuration is managed via ArgoCD. Changes to `gitops/gen3/values.yaml` are applied automatically when pushed to the remote — no need to re-run Ansible.

To update Gen3 configuration:

```shell
# Edit gitops/gen3/values.yaml
git commit -am "chore: update gen3 values"
git push
# ArgoCD detects the change and syncs automatically
```
