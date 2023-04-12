// variables.pkr.hcl
// Packer Variables

variable "admin_user" {
  type = string
  description = "Login name for admin user"
  default = "ubuntu"
}

variable "base_image_name" {
  type = string
  description = "Name to use for Base image"
}

variable "base_image_source" {
  type = string
  description = "Source URL for base image"
}

variable "base_image_source_format" {
  type = string
  description = "Image format of base image (qcow2 / raw / …)"
}

variable "build_image_flavour" {
  type = string
  description = "Virtual Image Flavour to be used when building images"
}

variable "database_image_name" {
  type = string
  description = "Name to give the database image"
}

variable "database_node_name" {
  type = string
  description = "Database node's hostname"
}

variable "load_balancer_image_name" {
  type = string
  description = "Name to give the load balancer image"
}

variable "load_balancer_node_name" {
  type = string
  description = "Load balancer's hostname"
}

variable "rancher_rke2_server_image_name" {
  type = string
  description = "Name to give the rke2 server image"
}

variable "rancher_rke2_worker_image_name" {
  type = string
  description = "Name to give the rke2 worker image"
}

variable "rancher_rke2_worker_node_name" {
  type = string
  description = "rke2 worker node's base hostname"
}

variable "rancher_rke2_worker_node_count" {
  type = number
  description = "Number of rke2 worker nodes to create"
}

variable "rancher_hostname" {
  type = string
  description = "name of rancher host"
}

variable "floating_ip_network_id" {
  description = "The name of the Floating IP network in your OpenStack"
  type = string
}

variable "network_ids" {
  type = list(string)
  description = "Name of networks to be used when building images"
}

variable "security_groups" {
  type = list(string)
  description = "Security groups to be used (this should include an incoming ssh rule…)"
}

variable "timezone" {
  type = string
  description = "Timezone to be used in machines"
}

variable "rancher_rke2_version" {
  type = string
  description = "Rancher RKE version to use"
}

// Terraform Variables

variable "database_node_flavour" {
  type = string
  description = "OpenStack VM flavour to use for the database node"
}

variable "database_node_disk_size_gib" {
  type = number
  description = "Disk size in GiB for the database node"
}

variable "gen3_hostname" {
  type = string
  description = "Hostname for the gen3 deployment"
}

variable "gen3_user" {
  type = string
  description = "Login name for gen3 user"
}

variable "rancher_rke2_server_node_flavour" {
  type = string
  description = "OpenStack VM flavour to use for the rke2 server nodes"
}

variable "rancher_rke2_worker_node_flavour" {
  type = string
  description = "OpenStack VM flavour to use for the rke2 worker nodes"
}

variable "rancher_rke2_worker_node_disk_size_gib" {
  type = number
  description = "Disk size in GiB for the rke2 worker nodes"
}

variable "rancher_rke2_server_node_disk_size_gib" {
  type = number
  description = "Disk size in GiB for the rke2 server nodes"
}

variable "load_balancer_node_flavour" {
  type = string
  description = "OpenStack VM flavour to use for the database node"
}

variable "rancher_rke2_server_node_name" {
  type = string
  description = "Rancher management node's hostname"
}

variable "rancher_rke2_server_node_count" {
  type = number
  description = "Number of rancher management nodes to create"
}

variable "floating_ip_pool_name" {
  type = string
  description = "OpenStack Floating IP address pool name"
}

variable "name_prefix" {
  type = string
  description = "Name used in terraform infrastructure"
}

variable "ssh_public_key" {
  type = string
  description = "Your ssh public key"
}

// variables used in ansible configuration

variable "google_client_id" {
  type        = string
  description = "Google client id"
}

variable "google_client_secret" {
  type        = string
  description = "Google client secret"
  sensitive   = true
}

variable "awsAccessKeyId" {
  type        = string
  description = "AWS access key id"
}

variable "awsSecretAccessKey" {
  type        = string
  description = "AWS secret access key"
  sensitive   = true
}

variable "postgres_user" {
  type = string
  description = "Main postgres username"
  default = "postgres"
}

variable "postgres_password" {
  type = string
  description = "Main postgres user password"
  sensitive = true
}

variable "postgres_fence_user" {
  type = string
  description = "fence user postgres username"
  default = "fence_user"
}

variable "postgres_fence_password" {
  type = string
  description = "fence user postgres password"
  sensitive = true
}

variable "postgres_peregrine_user" {
  type = string
  description = "peregrine user postgres username"
  default = "peregrine_user"
}

variable "postgres_peregrine_password" {
  type = string
  description = "peregrine user postgres password"
  sensitive = true
}

variable "postgres_sheepdog_user" {
  type = string
  description = "sheepdog user postgres username"
  default = "sheepdog_user"
}

variable "postgres_sheepdog_password" {
  type = string
  description = "sheepdog user postgres password"
  sensitive = true
}

variable "postgres_indexd_user" {
  type = string
  description = "indexd user postgres username"
  default = "indexd_user"
}

variable "postgres_indexd_password" {
  type = string
  description = "indexd user postgres password"
  sensitive = true
}

variable "postgres_arborist_user" {
  type = string
  description = "arborist user postgres username"
  default = "arborist_user"
}

variable "postgres_arborist_password" {
  type = string
  description = "arborist user postgres password"
  sensitive = true
}
