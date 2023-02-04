resource "openstack_networking_network_v2" "gen3_network" {
    name = "${var.name_prefix}-net"
    admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "gen3_subnet" {
    name = "${var.name_prefix}-subnet"
    network_id = openstack_networking_network_v2.gen3_network.id
    cidr = "192.168.10.0/24"
    ip_version = 4
    enable_dhcp = "true"

    dns_nameservers = ["8.8.8.8"]
}

data "openstack_networking_network_v2" "public" {
  name = var.floating_ip_pool_name
}

resource "openstack_networking_router_v2" "gen3_router" {
  name                = "${var.name_prefix}-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.public.id
}


resource "openstack_networking_router_interface_v2" "gen3_router_interface" {
  router_id = openstack_networking_router_v2.gen3_router.id
  subnet_id = openstack_networking_subnet_v2.gen3_subnet.id
}


#resource "openstack_networking_secgroup_v2" "gen3_postgres" {
#  name        = "${var.name_prefix}-postgres"
#  description = "For postgres access"
#}
#
#resource "openstack_networking_secgroup_rule_v2" "postgres" {
#  direction         = "ingress"
#  ethertype         = "IPv4"
#  protocol          = "tcp"
#  port_range_min    = 5432
#  port_range_max    = 5432
#  remote_ip_prefix  = "192.168.10.0/24"
#  security_group_id = openstack_networking_secgroup_v2.gen3_postgres.id
#}

resource "openstack_networking_secgroup_v2" "gen3_web" {
  name        = "${var.name_prefix}-web"
  description = "To access the gen3 web services"
}

resource "openstack_networking_secgroup_rule_v2" "http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.gen3_web.id
}

resource "openstack_networking_secgroup_rule_v2" "https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.gen3_web.id
}

resource "openstack_networking_secgroup_v2" "gen3_ssh" {
  name        = "${var.name_prefix}-ssh"
  description = "To access gen3 ssh"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.gen3_ssh.id
}

resource "openstack_networking_floatingip_v2" "k8s_float_ip" {
  pool = "${var.floating_ip_pool_name}"
}
