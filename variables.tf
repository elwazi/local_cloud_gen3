variable "storage_node_flavour" {
  type        = string
  description = "OpenStack flavour for storage node"
  default     = "ilifu-C"
}

variable "storage_node_disk_size_gib" {
  type        = number
  description = "Size in GiB of the Cinder volume attached to the storage node"
  default     = 100
}

variable "garage_rpc_secret" {
  type        = string
  description = "Garage RPC secret (hex string, generate with: openssl rand -hex 32)"
  sensitive   = true
}

variable "garage_access_key" {
  type        = string
  description = "Garage S3 access key ID (hex string, generate with: openssl rand -hex 16)"
  sensitive   = true
}

variable "garage_secret_key" {
  type        = string
  description = "Garage S3 secret key (hex string, generate with: openssl rand -hex 32)"
  sensitive   = true
}
