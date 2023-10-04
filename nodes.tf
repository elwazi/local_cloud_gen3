locals {
  base_image_name = "base.${var.image_suffix}"
  database_image_name = "database.${var.image_suffix}"
  rancher_rke2_server_image_name = "rke2.server.${var.image_suffix}"
  rancher_rke2_worker_image_name = "rke2.worker.${var.image_suffix}"
  load_balancer_image_name = "loadbalancer.${var.image_suffix}"

  load_balancer_node_name = "load-balancer.${var.node_suffix}"
  rancher_rke2_worker_node_name = "rke2-worker.${var.node_suffix}"
  rancher_rke2_server_node_name = "rke2-server.${var.node_suffix}"
  database_node_name = "gen3-database.${var.node_suffix}"
}

resource "openstack_compute_instance_v2" "load_balancer_node" {
  name            = local.load_balancer_node_name
  image_name      = local.load_balancer_image_name
  flavor_name     = var.load_balancer_node_flavour
  key_pair        = openstack_compute_keypair_v2.gen3_ssh_key.name
  security_groups = [openstack_networking_secgroup_v2.gen3_ssh.name, openstack_networking_secgroup_v2.gen3_web.name]
  network {
    name = openstack_networking_network_v2.gen3_network.name
  }
}

resource "openstack_compute_floatingip_associate_v2" "k8s_fip" {
  floating_ip = openstack_networking_floatingip_v2.load_balancer_float_ip.address
  #floating_ip = data.openstack_networking_floatingip_v2.load_balancer_fixed_floating_ip.address
  instance_id = openstack_compute_instance_v2.load_balancer_node.id
}

data "openstack_images_image_v2" "rancher_rke2_worker_image" {
  name = local.rancher_rke2_worker_image_name
}

resource "openstack_compute_instance_v2" "rancher_rke2_worker_nodes" {
  count           = var.rancher_rke2_worker_node_count
  name            = "${ local.rancher_rke2_worker_node_name }-${ count.index + 1 }"
#  image_name      = var.rancher_rke2_worker_image_name
  flavor_name     = var.rancher_rke2_worker_node_flavour
  key_pair        = openstack_compute_keypair_v2.gen3_ssh_key.name
  security_groups = [openstack_networking_secgroup_v2.gen3_kubernetes.name, openstack_networking_secgroup_v2.kubernetes_worker_web_traffic.name]
  network {
    name = openstack_networking_network_v2.gen3_network.name
  }
  block_device {
    source_type = "image"
    uuid        = data.openstack_images_image_v2.rancher_rke2_worker_image.id
    volume_size = var.rancher_rke2_worker_node_disk_size_gib
    destination_type = "volume"
    delete_on_termination = true
  }
}

data "openstack_images_image_v2" "rancher_rke2_server_image" {
  name = local.rancher_rke2_server_image_name
}

resource "openstack_compute_instance_v2" "rancher_rke2_server_nodes" {
    count           = var.rancher_rke2_server_node_count
    name            = "${ local.rancher_rke2_server_node_name }-${ count.index + 1 }"
#    image_name      = var.rancher_rke2_server_image_name
    flavor_name     = var.rancher_rke2_server_node_flavour
    key_pair        = openstack_compute_keypair_v2.gen3_ssh_key.name
    security_groups = [openstack_networking_secgroup_v2.gen3_kubernetes.name]
    network {
        name = openstack_networking_network_v2.gen3_network.name
    }
    block_device {
      source_type = "image"
      uuid        = data.openstack_images_image_v2.rancher_rke2_server_image.id
      volume_size = var.rancher_rke2_server_node_disk_size_gib
      destination_type = "volume"
      delete_on_termination = true
    }
}

data "openstack_images_image_v2" "database_image" {
  name = local.database_image_name
}

resource "openstack_compute_instance_v2" "database_node" {
  name            = local.database_node_name
#  image_name      = var.database_image_name
  flavor_name     = var.database_node_flavour
  key_pair        = openstack_compute_keypair_v2.gen3_ssh_key.name
  security_groups = [openstack_networking_secgroup_v2.gen3_postgres.name]
  network {
    name = openstack_networking_network_v2.gen3_network.name
  }
  block_device {
    source_type = "image"
    uuid        = data.openstack_images_image_v2.database_image.id
    volume_size = var.database_node_disk_size_gib
    destination_type = "volume"
    delete_on_termination = false

  }
}
