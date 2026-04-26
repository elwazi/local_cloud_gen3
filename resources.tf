locals {
  #  database_node_name = "gen3-database.${var.node_suffix}"
  rancher_node_name = "gen3-rancher.${var.node_suffix}"
}

resource "openstack_compute_keypair_v2" "gen3_ssh_key" {
  name       = "${var.name_prefix}-sshkey"
  public_key = file("${var.ssh_private_key_file}.pub")
}

resource "local_file" "inventory" {
  content = templatefile("templates/inventory.yaml.tpl",
    {
      admin_user = var.admin_user
      cidr       = var.cidr

      database_node      = openstack_compute_instance_v2.database_node
      database_node_name = local.database_node_name

      # ec2_credentials = openstack_identity_ec2_credential_v3.ec2_credentials

      gen3_admin_email                       = var.gen3_admin_email
      gen3_hostname                          = var.gen3_hostname
      gen3_user                              = var.gen3_user
      gen3_portal_appName                    = var.gen3_portal_appName
      gen3_portal_index_introduction_heading = var.gen3_portal_index_introduction_heading
      gen3_portal_index_introduction_text    = var.gen3_portal_index_introduction_text
      gen3_portal_navigation_title           = var.gen3_portal_navigation_title
      gen3_portal_login_title                = var.gen3_portal_login_title
      gen3_portal_login_subtitle             = var.gen3_portal_login_subtitle
      gen3_portal_login_text                 = var.gen3_portal_login_text
      gen3_portal_login_email                = var.gen3_portal_login_email
      gen3_portal_logo                       = var.gen3_portal_logo_base64_png

      google_client_id     = var.google_client_id
      google_client_secret = var.google_client_secret

      load_balancer_float_ip = openstack_networking_floatingip_v2.load_balancer_float_ip.address # todo: change back to this
      load_balancer_node     = openstack_compute_instance_v2.load_balancer_node

      postgres_user     = var.postgres_user
      postgres_password = var.postgres_password

      rancher_rke2_server_nodes = [for node in openstack_compute_instance_v2.rancher_rke2_server_nodes.* : node]
      rancher_rke2_worker_nodes = [for node in openstack_compute_instance_v2.rancher_rke2_worker_nodes.* : node]

      storage_node             = openstack_compute_instance_v2.storage_node
      storage_data_volume_attach = openstack_compute_volume_attach_v2.storage_data_volume_attach
      garage_rpc_secret = var.garage_rpc_secret
      garage_access_key = var.garage_access_key
      garage_secret_key = var.garage_secret_key

      ssh_private_key_file = var.ssh_private_key_file
      timezone             = var.timezone
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
