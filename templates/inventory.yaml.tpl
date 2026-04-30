servers:
  children:
    storage_nodes:
      hosts:
        ${ storage_node.name }:
          ansible_host: ${ storage_node.access_ip_v4 }
          private_ip: ${ storage_node.access_ip_v4 }
          data_device: ${ storage_data_volume_attach.device }
    load_balancer_nodes:
      hosts:
        ${ load_balancer_node.name }:
          ansible_host: ${load_balancer_float_ip}
          private_ip: ${load_balancer_node.access_ip_v4}
      vars:
        ansible_connection: ssh
        ansible_user: ${admin_user}
        ansible_ssh_common_args: "-o ControlPersist=15m -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentityAgent=none -o IdentitiesOnly=yes"
        ansible_ssh_private_key_file: ${ssh_private_key_file}
    database_nodes:
      hosts:
        ${ database_node.name }:
          ansible_host: ${ database_node.access_ip_v4 }
          private_ip: ${ database_node.access_ip_v4 }
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
    gen3:
      hosts:
        gen3:
          ansible_host: ${rancher_rke2_server_nodes[0].access_ip_v4}
          private_ip: ${rancher_rke2_server_nodes[0].access_ip_v4}
  vars:

    ansible_connection: ssh
    ansible_user: ${admin_user}
    ansible_ssh_common_args: "-o ControlPersist=15m -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentityAgent=none -o IdentitiesOnly=yes -o ProxyJump=${admin_user}@${load_balancer_float_ip}"
    ansible_ssh_private_key_file: ${ssh_private_key_file}

    timezone: '${ timezone }'
    gen3_subnet: ${cidr}

    gen3: {
      'hostname': '${gen3_hostname}',
      'user': '${gen3_user}',
      'admin_email': '${gen3_admin_email}',
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
      },
    }

    s3: {
      'host_base': '${gen3_hostname}:9000',
      'host_bucket': '${gen3_hostname}:9000',
    }

    garage: {
      'rpc_secret': '${garage_rpc_secret}',
      'access_key': '${garage_access_key}',
      'secret_key': '${garage_secret_key}',
    }

    google_client_id: "${google_client_id}"
    google_client_secret: "${google_client_secret}"

    postgres: {
      'host_ip': '${database_node.access_ip_v4}',
      'user': '${postgres_user}',
      'password': '${postgres_password}',
      'service_passwords': {
%{ for svc, pw in gen3_db_service_passwords ~}
        '${svc}': '${pw}',
%{ endfor ~}
      }
    }

