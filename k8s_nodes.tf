resource "openstack_compute_instance_v2" "k8s_control_plane" {
  name            = var.k8s_control_plane_node_name
  image_name      = var.k8s_image_name
  flavor_name     = var.k8s_control_plane_node_flavour
  key_pair        = openstack_compute_keypair_v2.gen3_ssh_key.name
  security_groups = [openstack_networking_secgroup_v2.gen3_ssh.name, openstack_networking_secgroup_v2.gen3_kubernetes.name]
  network {
    name = openstack_networking_network_v2.gen3_network.name
  }
}

resource "openstack_compute_instance_v2" "k8s_nodes" {
  count           = var.k8s_node_count
  name            = "${ var.k8s_node_name }-${ count.index + 1 }"
  image_name      = var.k8s_image_name
  flavor_name     = var.k8s_node_flavour
  key_pair        = openstack_compute_keypair_v2.gen3_ssh_key.name
  security_groups = [openstack_networking_secgroup_v2.gen3_kubernetes.name]
  network {
    name = openstack_networking_network_v2.gen3_network.name
  }
}


resource "openstack_compute_floatingip_associate_v2" "k8s_fip" {
  floating_ip = openstack_networking_floatingip_v2.k8s_float_ip.address
  instance_id = openstack_compute_instance_v2.k8s_control_plane.id
}

#output "compute_instances" {
#  description = "All the slurm compute nodes' names"
#  value       = "${openstack_compute_instance_v2.slurm_compute.*.name}"
#}
#
#output "compute_ips" {
#  description = "All the slurm compute nodes' ip addresses"
#  value = "${openstack_compute_instance_v2.slurm_compute.*.access_ip_v4}"
#}