locals {
#  database_node_name = "gen3-database.${var.node_suffix}"
  rancher_node_name = "gen3-rancher.${var.node_suffix}"
}

resource "openstack_compute_keypair_v2" "gen3_ssh_key" {
  name       = "${var.name_prefix}-sshkey"
  public_key = var.ssh_public_key
}

resource "local_file" "hosts_cfg" {
  content = templatefile("templates/inventory.yaml.tpl",
    {
      admin_user = var.admin_user

      database_node = openstack_compute_instance_v2.database_node
      database_node_ip = openstack_compute_instance_v2.database_node.access_ip_v4
      database_node_name = local.database_node_name

      ec2_credentials = openstack_identity_ec2_credential_v3.ec2_credentials

      gen3_admin_email = var.gen3_admin_email
      gen3_hostname = var.gen3_hostname
      gen3_user = var.gen3_user

      google_client_id = var.google_client_id
      google_client_secret = var.google_client_secret

      load_balancer_float_ip = openstack_networking_floatingip_v2.load_balancer_float_ip.address  # todo: change back to this
      load_balancer_node = openstack_compute_instance_v2.load_balancer_node

      postgres_user = var.postgres_user
      postgres_password = var.postgres_password

      rancher_rke2_server_nodes = [for node in openstack_compute_instance_v2.rancher_rke2_server_nodes.*: node ]
      rancher_rke2_worker_nodes = [for node in openstack_compute_instance_v2.rancher_rke2_worker_nodes.*: node ]

      s3_host_server = var.s3_host_server
      s3_host_port   = var.s3_host_port

      timezone = var.timezone
    }
  )
  filename = "inventory.yaml"
}

#resource "local_file" "group_vars_all" {
#  content = templatefile("templates/group_vars.all.tpl",
#    {
#
#
##      awsAccessKeyId = var.awsAccessKeyId
##      awsSecretAccessKey = var.awsSecretAccessKey
#      gen3_hostname = var.gen3_hostname
#      gen3_user = var.gen3_user
#      gen3_admin_email = var.gen3_admin_email
#      ec2_credentials = openstack_identity_ec2_credential_v3.ec2_credentials
#      s3_host_server = var.s3_host_server
#      s3_host_port   = var.s3_host_port
##      rancher_hostname = var.rancher_hostname
#
#      database_node_name = local.database_node_name
#      postgres_user = var.postgres_user
#      postgres_password = var.postgres_password
#
#    }
#  )
#  filename = "group_vars/all"
#}
