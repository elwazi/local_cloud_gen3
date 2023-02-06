# eLwazi
Repository for keeping track of eLwazi private openstack gen3 infrastructure and
documentation.

[Installing gen3 on existing machines](#setting-up-the-infrastructure-on-existing-machines-using-ansible)

# Setting up the infrastructure on OpenStack using Packer, Terraform and Ansible
The infrastructure is managed with a set of scripts that make use of
[Packer](https://www.packer.io/) (for creating the OpenStack virtual machine images
that are used), [Terraform](https://www.terraform.io/) (for deploying  infrastructure
on OpenStack), and finally [Ansible](https://www.ansible.com/) for configuring the
infrastructure — largely using the [gen3 helm charts](https://github.com/uc-cdis/gen3-helm)

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
`inventory` file which can be used with ansible.

## Infrastructure Configuration
Finally the infrastructure can be configured using ansible. The `inventory` file generated
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
