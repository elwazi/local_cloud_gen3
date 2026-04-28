#!/bin/bash
# You probably don't want this. I want this, so I can test redeploying works…

set -e

terraform destroy \
  -target='openstack_compute_instance_v2.load_balancer_node' \
  -target='openstack_compute_instance_v2.rancher_rke2_worker_nodes' \
  -target='openstack_compute_instance_v2.rancher_rke2_server_nodes' \
  -target='openstack_compute_instance_v2.storage_node' \
  -target='openstack_compute_instance_v2.database_node'
