[all:vars]
ansible_connection=ssh
ansible_ssh_extra_args="-o ControlPersist=15m -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o AddKeysToAgent=no -o IdentitiesOnly=yes -v"
ansible_ssh_private_key_file=~/.ssh/ilifu/id_rsa
ansible_user=${admin_user}
postgres_user=${postgres_user}
postgres_password=${postgres_password}
postgres_fence_user=${postgres_fence_user}
postgres_fence_password=${postgres_fence_password}
postgres_peregrine_user=${postgres_peregrine_user}
postgres_peregrine_password=${postgres_peregrine_password}
postgres_sheepdog_user=${postgres_sheepdog_user}
postgres_sheepdog_password=${postgres_sheepdog_password}
postgres_indexd_user=${postgres_indexd_user}
postgres_indexd_password=${postgres_indexd_password}
postgres_arborist_user=${postgres_arborist_user}
postgres_arborist_password=${postgres_arborist_password}

[all:children]
k8s_nodes
k8s_control_plane

[k8s_nodes]
%{ for k8s_node in k8s_nodes ~}
${k8s_node} ansible_host=${k8s_node}
%{ endfor ~}

[k8s_nodes:vars]
ansible_ssh_extra_args="-o ProxyCommand='ssh -o ControlPersist=15m -A -i ~/.ssh/ilifu/id_rsa ${admin_user}@${k8s_node_float_ip} nc %h 22'"

[k8s_control_plane]
docker ansible_host=${k8s_node_float_ip}


