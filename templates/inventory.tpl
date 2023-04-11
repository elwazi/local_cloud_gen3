[all:vars]
ansible_connection=ssh
ansible_ssh_extra_args="-o ControlPersist=15m -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o AddKeysToAgent=no -o IdentitiesOnly=yes -v -o ProxyCommand='ssh -o StrictHostKeyChecking=no -o ControlPersist=15m -A -i ~/.ssh/ilifu/id_rsa ${admin_user}@${load_balancer_float_ip} nc %h 22'"

ansible_ssh_private_key_file=~/.ssh/ilifu/id_rsa
ansible_user=${admin_user}


[all:children]
load_balancer_nodes
rancher_rke2_server_nodes
rancher_rke2_worker_nodes
database_nodes

[load_balancer_nodes]
${ load_balancer_node.name } ansible_host=${load_balancer_float_ip} private_ip=${load_balancer_node.access_ip_v4}

[load_balancer_nodes:vars]
ansible_ssh_extra_args="-o ControlPersist=15m -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o AddKeysToAgent=no -o IdentitiesOnly=yes -v"

[rancher_rke2_server_nodes]
%{ for server_node in rancher_rke2_server_nodes ~}
${ server_node.name } ansible_host=${server_node.access_ip_v4} private_ip=${server_node.access_ip_v4}
%{ endfor ~}

[rancher_rke2_worker_nodes]
%{ for worker_node in rancher_rke2_worker_nodes ~}
${ worker_node.name } ansible_host=${worker_node.access_ip_v4} private_ip=${worker_node.access_ip_v4}
%{ endfor ~}

[database_nodes]
${ database_node.name } ansible_host=${database_node.access_ip_v4} private_ip=${database_node.access_ip_v4}

[database_nodes:vars]
ansible_ssh_extra_args="-o ProxyCommand='ssh -o StrictHostKeyChecking=no -o ControlPersist=15m -A -i ~/.ssh/ilifu/id_rsa ${admin_user}@${load_balancer_float_ip} nc %h 22'"

[gen3]
gen3 ansible_host=${rancher_rke2_server_nodes[0].access_ip_v4} private_ip=${rancher_rke2_server_nodes[0].access_ip_v4}
