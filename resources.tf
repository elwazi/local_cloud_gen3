locals {
#  database_node_name = "gen3-database.${var.node_suffix}"
  rancher_node_name = "gen3-rancher.${var.node_suffix}"
}

resource "openstack_compute_keypair_v2" "gen3_ssh_key" {
  name       = "${var.name_prefix}-sshkey"
  public_key = var.ssh_public_key
}

resource "local_file" "hosts_cfg" {
  content = templatefile("templates/inventory.tpl",
    {
      gen3_hostname = var.gen3_hostname
#      rancher_hostname = var.rancher_hostname
      #load_balancer_float_ip = openstack_networking_floatingip_v2.load_balancer_float_ip.address  # todo: change back to this
      load_balancer_float_ip = data.openstack_networking_floatingip_v2.load_balancer_fixed_floating_ip.address
      rancher_rke2_worker_nodes = [for node in openstack_compute_instance_v2.rancher_rke2_worker_nodes.*: node ]
      rancher_rke2_server_nodes = [for node in openstack_compute_instance_v2.rancher_rke2_server_nodes.*: node ]
      database_node = openstack_compute_instance_v2.database_node
      load_balancer_node = openstack_compute_instance_v2.load_balancer_node
      admin_user = var.admin_user
    }
  )
  filename = "inventory.ini"
}

resource "local_file" "group_vars_all" {
  content = templatefile("templates/group_vars.all.tpl",
    {
      timezone = var.timezone
      google_client_id = var.google_client_id
      google_client_secret = var.google_client_secret
      awsAccessKeyId = var.awsAccessKeyId
      awsSecretAccessKey = var.awsSecretAccessKey
      gen3_hostname = var.gen3_hostname
      gen3_user = var.gen3_user
#      rancher_hostname = var.rancher_hostname

      database_node_name = local.database_node_name
      postgres_user = var.postgres_user
      postgres_password = var.postgres_password

    }
  )
  filename = "group_vars/all"
}
