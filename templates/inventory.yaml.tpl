servers:
  children:
    load_balancer_nodes:
      hosts:
        ${ load_balancer_node.name }:
          ansible_host: ${load_balancer_float_ip}
          private_ip: ${load_balancer_node.access_ip_v4}
      vars:
        ansible_ssh_extra_args: "-o ControlPersist=15m -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o AddKeysToAgent=no -o IdentitiesOnly=yes -v"
    rancher_rke2_server_nodes:
      hosts:
%{ for server_node in rancher_rke2_server_nodes ~}
        ${ server_node.name }:
          ansible_host: ${server_node.access_ip_v4}
          private_ip: ${server_node.access_ip_v4}
%{ endfor ~}
    rancher_rke2_worker_nodes:
      hosts:
%{ for worker_node in rancher_rke2_worker_nodes ~}
        ${ worker_node.name }:
          ansible_host: ${worker_node.access_ip_v4}
          private_ip: ${worker_node.access_ip_v4}
%{ endfor ~}
    database_nodes:
      hosts:
        ${ database_node.name }:
          ansible_host: ${database_node.access_ip_v4}
          private_ip: ${database_node.access_ip_v4}
      vars:
        ansible_ssh_extra_args: "-o ProxyCommand='ssh -o StrictHostKeyChecking=no -o ControlPersist=15m -A -i ~/.ssh/ilifu/id_rsa ${admin_user}@${load_balancer_float_ip} nc %h 22'"
    gen3:
      hosts:
        gen3:
          ansible_host: ${rancher_rke2_server_nodes[0].access_ip_v4}
          private_ip: ${rancher_rke2_server_nodes[0].access_ip_v4}
  vars:
    ansible_ssh_extra_args: "-o ControlPersist=15m -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o AddKeysToAgent=no -o IdentitiesOnly=yes -v -o ProxyCommand='ssh -o StrictHostKeyChecking=no -o ControlPersist=15m -A -i ~/.ssh/ilifu/id_rsa ${admin_user}@${load_balancer_float_ip} nc %h 22'"
    ansible_connection: ssh
    ansible_user: ${admin_user}
    ansible_ssh_private_key_file: ~/.ssh/ilifu/id_rsa

    timezone: '${ timezone }'
    gen3_subnet: 192.168.10.0/24

    gen3: {
      'hostname': '${gen3_hostname}',
      'user': '${gen3_user}',
      'admin_email': '${gen3_admin_email}',
      'ec2': {
        'access': '${ec2_credentials.access}',
        'secret': '${ec2_credentials.secret}',
        'project_id': '${ec2_credentials.project_id}',
        'user_id': '${ec2_credentials.user_id}',
        'trust_id': '${ec2_credentials.trust_id}',
      },
      'data_bucket_name': '${gen3_hostname}-data-bucket',
      'user_bucket_name': '${gen3_hostname}-user-bucket',
      'portal': {
        'appName': '${gen3_portal_appName}',
        'index': {
          'introduction': {
            'heading': '${gen3_portal_index_introduction_heading}',
            'text': '${gen3_portal_index_introduction_text}',
          },
        },
        'navigation': {
          'title': '${gen3_portal_navigation_title}',
        },
        'login': {
            'title': '${gen3_portal_login_title}',
            'subtitle': '${gen3_portal_login_subtitle}',
            'text': '${gen3_portal_login_text}',
            'email': '${gen3_portal_login_email}',
        },
        'logo_base64': '${gen3_portal_logo}'
      }
    }

    s3: {
      'host_base': ${s3_host_server}:${s3_host_port},
      'host_bucket': ${s3_host_server}:${s3_host_port},
    }

    postgres: {
      'hostname': '${ database_node_name }',
      'host_ip': '${ database_node_ip }',
      'user': '${postgres_user}',
      'password': '${postgres_password}',
      'arborist_password': '${postgres_arborist_password}',
      'fence_password': '${postgres_fence_password}',
      'indexd_password': '${postgres_indexd_password}',
      'peregrine_password': '${postgres_peregrine_password}',
      'sheepdog_password': '${postgres_sheepdog_password}',
      'metadata_password': '${postgres_metadata_password}',
      'guppy_password': '${postgres_guppy_password}',
      'audit_password': '${postgres_audit_password}',
      'wts_password': '${postgres_wts_password}',
      'audit_password': '${postgres_audit_password}',
    }

    google_client_id: "${google_client_id}"
    google_client_secret: "${google_client_secret}"
