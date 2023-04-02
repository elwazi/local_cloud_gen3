[all:vars]
ansible_connection=ssh
ansible_ssh_extra_args="-o ControlPersist=15m -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o AddKeysToAgent=no -o IdentitiesOnly=yes -v"
ansible_ssh_private_key_file=~/.ssh/ilifu/id_rsa
ansible_user=${admin_user}


[all:children]
k8s_nodes
k8s_control_plane
database_nodes

[database_nodes]
${ database_node.name } ansible_host=${database_node.access_ip_v4} private_ip=${database_node.access_ip_v4}

[database_nodes:vars]
ansible_ssh_extra_args="-o ProxyCommand='ssh -o ControlPersist=15m -A -i ~/.ssh/ilifu/id_rsa ${admin_user}@${k8s_node_float_ip} nc %h 22'"

[k8s_nodes]
%{ for k8s_node in k8s_nodes ~}
${ k8s_node.name } ansible_host=${k8s_node.access_ip_v4} private_ip=${k8s_node.access_ip_v4}
%{ endfor ~}

[k8s_nodes:vars]
ansible_ssh_extra_args="-o ProxyCommand='ssh -o ControlPersist=15m -A -i ~/.ssh/ilifu/id_rsa ${admin_user}@${k8s_node_float_ip} nc %h 22'"

[k8s_control_plane]
${ k8s_control_plane.name } ansible_host=${k8s_node_float_ip} private_ip=${k8s_control_plane.access_ip_v4}

[gen3]
${ k8s_control_plane.name } ansible_host=${k8s_node_float_ip} private_ip=${k8s_control_plane.access_ip_v4}


