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

resource "openstack_networking_secgroup_v2" "gen3_kubernetes" {
  name        = "${var.name_prefix}-kubernetes"
  description = "To access gen3 kubernetes nodes ssh and api"
}

resource "openstack_networking_secgroup_rule_v2" "internal_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "192.168.10.0/24"
  security_group_id = openstack_networking_secgroup_v2.gen3_kubernetes.id
}

resource "openstack_networking_secgroup_rule_v2" "kubelet_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10250
  port_range_max    = 10250
  remote_ip_prefix  = "192.168.10.0/24"
  security_group_id = openstack_networking_secgroup_v2.gen3_kubernetes.id
}

resource "openstack_networking_secgroup_rule_v2" "k8s_icmp" {
    direction         = "ingress"
    ethertype         = "IPv4"
    protocol          = "icmp"
    remote_ip_prefix  = "192.168.10.0/24"
    security_group_id = openstack_networking_secgroup_v2.gen3_kubernetes.id
}

resource "openstack_networking_secgroup_v2" "gen3_k8s_control_plane" {
  name        = "${var.name_prefix}-k8s-control-plane"
  description = "kubernetes control plane networks"
}

resource "openstack_networking_secgroup_rule_v2" "kubernetes_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "192.168.10.0/24"
  security_group_id = openstack_networking_secgroup_v2.gen3_k8s_control_plane.id
}

resource "openstack_networking_secgroup_rule_v2" "kubernetes_api_server_etcd" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2379
  port_range_max    = 2380
  remote_ip_prefix  = "192.168.10.0/24"
  security_group_id = openstack_networking_secgroup_v2.gen3_k8s_control_plane.id
}

resource "openstack_networking_secgroup_rule_v2" "kube_scheduler" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10259
  port_range_max    = 10259
  remote_ip_prefix  = "192.168.10.0/24"
  security_group_id = openstack_networking_secgroup_v2.gen3_k8s_control_plane.id
}

resource "openstack_networking_secgroup_rule_v2" "kube_controller_manager" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10257
  port_range_max    = 10257
  remote_ip_prefix  = "192.168.10.0/24"
  security_group_id = openstack_networking_secgroup_v2.gen3_k8s_control_plane.id
}

resource "openstack_networking_secgroup_v2" "gen3_k8s_worker_node" {
  name        = "${var.name_prefix}-k8s-worker"
  description = "kubernetes worker node settings"
}

resource "openstack_networking_secgroup_rule_v2" "k8s_nodeport_services" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 30000
  port_range_max    = 32767
  remote_ip_prefix  = "192.168.10.0/24"
  security_group_id = openstack_networking_secgroup_v2.gen3_k8s_worker_node.id
}

resource "openstack_networking_secgroup_v2" "gen3_postgres" {
  name        = "${var.name_prefix}-postgres"
  description = "To access database ssh and postgres port"
}

resource "openstack_networking_secgroup_rule_v2" "pg_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "192.168.10.0/24"
  security_group_id = openstack_networking_secgroup_v2.gen3_postgres.id
}

resource "openstack_networking_secgroup_rule_v2" "postgres" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 5432
  port_range_max    = 5432
  remote_ip_prefix  = "192.168.10.0/24"
  security_group_id = openstack_networking_secgroup_v2.gen3_postgres.id
}

resource "openstack_networking_secgroup_rule_v2" "elasticsearch" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9200
  port_range_max    = 9300
  remote_ip_prefix  = "192.168.10.0/24"
  security_group_id = openstack_networking_secgroup_v2.gen3_postgres.id
}

resource "openstack_networking_secgroup_rule_v2" "postgres_icmp" {
    direction         = "ingress"
    ethertype         = "IPv4"
    protocol          = "icmp"
    remote_ip_prefix  = "192.168.10.0/24"
    security_group_id = openstack_networking_secgroup_v2.gen3_postgres.id
}

resource "openstack_networking_floatingip_v2" "k8s_float_ip" {
  pool = "${var.floating_ip_pool_name}"
}
