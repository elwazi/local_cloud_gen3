# eLwazi
Repository for keeping track of eLwazi private openstack gen3 infrastructure and
documentation.

[Installing gen3 on existing machines](#setting-up-the-infrastructure-on-existing-machines-using-ansible)

# Setting up the infrastructure on OpenStack using Packer, Terraform and Ansible
The infrastructure is managed with a set of scripts that make use of
[Packer](https://www.packer.io/) (for creating the OpenStack virtual machine images
that are used), [Terraform](https://www.terraform.io/) (for deploying  infrastructure
on OpenStack), and finally [Ansible](https://www.ansible.com/) for configuring the
infrastructure — largely using the [gen3 helm charts](https://github.com/uc-cdis/gen3-helm).

## Installing software requirements on your machine
You will need to install [Packer](https://learn.hashicorp.com/tutorials/packer/get-started-install-cli)
and [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) in
addition to setting up a python virtual environment. Packer and Terraform can be
installed by setting up the appropriate repositories and installing using your OS's
package manager. The python virtual environment is ideally set up using pipenv by
running the `pipenv sync` command. Alternatively ensure you have a python virtual
environment with both the `python-openstackclient` and `ansible` packages installed.
Remember to activate your virtual environment (with `pipenv shell` or `. ./.venv/bin/activate`).

### Initialising packer
It is important to run `packer init images.openstack.pkr.hcl` once in your environment. This
will ensure that the packer OpenStack plugin is installed.

## Get your OpenStack.rc file
Connect to your OpenStack dashboard, switch to the correct project then download the
`*-openrc.sh` file for your project (from the top-right dropdown menu). Before running most
of the commands here you will need to have "sourced" this file so that the environmental
variables are set so that packer/terraform can connect to your openstack infrastructure.
In otherwords once you have the `*-openrc.sh` file you will need to run
`source your-openrc.sh` and then the subsequent commands will work. Note you will need
your OpenStack login details at the time of sourcing.

## Setting up variables
There are only two files that should need configuring for this installation and these
contain the variables that Packer/Terraform and Ansible use.

### Packer and Terraform
The Packer and Terraform variables should be in a file named `variables.auto.hcl` and this
can be made by copying the template file, i.e. `cp variables.auto.hcl.template variables.auto.hcl`.
Note that there are symbolic link files (`gen3.auto.tfvars` and
`gen3.auto.pkrvars.hcl`) that point at `variables.auto.hcl` and are auto-loaded by Packer
and Terraform. A description of the required variables can be found in the file `variables.hcl`.
Edit the contents in order to both personalise your gen3 instance and ensure that both
Packer and Terraform will use the correct values for your OpenStack, e.g. you will almost
certainly need to change the values of: `build_image_flavour`, `database_node_flavour` and
`docker_node_flavour` so that appropriate OpenStack Virtual Machine flavours are used.
The variables to be set are:
* `admin_user`: Login name for admin user
* `base_image_name`: Name to use for Base image
* `base_image_source`: Source URL for base image
* `base_image_source_format`: Image format of base image (qcow2 / raw / …)
* `build_image_flavour`: Virtual Image Flavour to be used when building images
* `database_image_name`: Name to give the database image
* `database_node_name`: Database node's hostname
* `k8s_image_name`: Name to give the k8s image
* `k8s_control_plane_node_name`: k8s control plane's node's hostname
* `k8s_node_name`: k8s node's base hostname
* `k8s_node_count`: Number of k8s nodes to create
* `floating_ip_network_id`: The name of the Floating IP network in your OpenStack
* `network_ids`: Name of networks to be used when building images
* `security_groups`: Security groups to be used (this should include an incoming ssh rule…)
* `timezone`: Timezone to be used in machines
* `database_node_flavour`: OpenStack VM flavour to use for the database node
* `gen3_hostname`: Hostname for the gen3 deployment
* `k8s_control_plane_node_flavour`: OpenStack VM flavour to use for the k8s control plane
* `k8s_node_flavour`: OpenStack VM flavour to use for the k8s nodes
* `floating_ip_pool_name`: OpenStack Floating IP address pool name
* `name_prefix`: Name used in terraform infrastructure
* `ssh_public_key`: Your ssh public key
* `google_client_id`: Google client id
* `google_client_secret`: Google client secret
* `awsAccessKeyId`: AWS access key id
* `awsSecretAccessKey`: AWS secret access key
* `postgres_user`: Main postgres username
* `postgres_password`: Main postgres user password
* `postgres_fence_user`: fence user postgres username
* `postgres_fence_password`: fence user postgres password
* `postgres_peregrine_user`: peregrine user postgres username
* `postgres_peregrine_password`: peregrine user postgres password
* `postgres_sheepdog_user`: sheepdog user postgres username
* `postgres_sheepdog_password`: sheepdog user postgres password
* `postgres_indexd_user`: indexd user postgres username
* `postgres_indexd_password`: indexd user postgres password
* `postgres_arborist_user`: arborist user postgres username
* `postgres_arborist_password`: arborist user postgres password

### Ansible
Ansible requires some of its own variables and these can be created by setting up the
`group_vars/all` by using the template, i.e. `cp group_vars/all.template group_vars/all`
and then updating the contents.
You can modify the ansible `group_vars/all` file to reflect some settings such as:
* `timezone`: This is the time zone setting for all the virtual machines.

### MinIO Object Storage
MinIO is a High Performance, S3 compatible object storage system. In this project, it provides a scalable and resilient storage backend for various Gen3 services and can be used for storing user data, application data, and other artifacts.

The MinIO deployment is managed via Ansible and deployed as a Helm chart within the Kubernetes cluster.

**Enabling/Disabling MinIO:**
The deployment of MinIO can be controlled by the `gen3_minio_enabled` Ansible variable. Set this to `true` to deploy MinIO or `false` to skip its deployment.

**Configuration Variables:**
Key configuration options for MinIO are defined as Ansible variables in `roles/gen3/defaults/main.yml`. You can override these in your `group_vars/all` or other inventory files. For sensitive values like access and secret keys, it is strongly recommended to use Ansible Vault.

Important variables include:
*   `gen3_minio_enabled`: (boolean) Enable or disable MinIO deployment.
*   `gen3_minio_access_key`: (string) The access key for MinIO. Default: `minioadmin`. **Change this and store in Vault.**
*   `gen3_minio_secret_key`: (string) The secret key for MinIO. Default: `minioadmin`. **Change this and store in Vault.**
*   `gen3_minio_namespace`: (string) The Kubernetes namespace where MinIO will be deployed. Default: `gen3`.
*   `gen3_minio_chart_version`: (string) Specific version of the MinIO Helm chart to deploy. If empty, the latest stable version is used.
*   `gen3_minio_image_tag`: (string) Docker image tag for MinIO.
*   `gen3_minio_persistence_size`: (string) Size of the persistent volume for MinIO storage (e.g., `10Gi`).
*   `gen3_minio_persistence_storage_class`: (string) Storage class for MinIO's persistent volume. Leave empty for default.
*   `gen3_minio_service_port`: (integer) Port number for the MinIO service. Default: `9000`.
*   `gen3_minio_service_type`: (string) Kubernetes service type for MinIO. Default: `ClusterIP`.

**Service Details:**
*   **Service Name:** `minio`
*   **Namespace:** `{{ gen3_minio_namespace }}` (typically `gen3`)
*   **Port:** `{{ gen3_minio_service_port }}` (typically `9000`)

**Accessing MinIO from within Kubernetes:**
Applications running within the same Kubernetes cluster can typically access MinIO using its internal service endpoint:
`http://minio.{{ gen3_minio_namespace }}.svc.cluster.local:{{ gen3_minio_service_port }}`

## Building the images
Once the variables have been configured (the `build_image_flavour` is probably the most
important as this often varies from system to system) the images can be built. This
can be done with the command:
```shell
$ ./build.sh
```
The script checks for the existence of the target images on OpenStack. If they already
exist, nothing happens. Otherwise, the images are built.

## Deploying with Terraform
The machines are first deployed with terraform. Firstly the environment must be
initialised with `terraform init`. Afterwards `terraform plan` and `terraform apply`
can be used to actually create the infrastructure including: the network and subnetwork;
the security groups; the docker node; the database node. This will also create an
`inventory.ini` file which can be used with ansible.

## Infrastructure Configuration
Finally the infrastructure can be configured using ansible. The `inventory.ini` file generated
in the previous should be updated — specifically the passwords should be updated – these can
easily be found by searching for the `TODO:CONFIGURE_ME` text.

Then the playbook should be run with the command: `ansible-playbook -i inventory site.yml`.
This will connect to the nodes and finalise the configuration of services on the nodes.

# Setting up the infrastructure on existing machines using Ansible
The first method which starts off using packer and terraform is useful if you have access
to OpenStack cloud infrastructure, however if you simply have access to some Ubuntu machines
(or virtual machines) then you can use the ansible scripts to install the infrastucture. The
main difficulty is configuring the inventory and variables files so that the ansible scripts
know what to do where.

## Setting up your inventory

## Setting up your variables

## Running the ansible scripts
