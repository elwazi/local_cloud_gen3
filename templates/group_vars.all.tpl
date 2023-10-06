---
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
  'bucket_name': '${gen3_hostname}-bucket',
}

s3: {
  'host_base': ${s3_host_server}:${s3_host_port},
  'host_bucket': ${s3_host_server}:${s3_host_port},
}

postgres: {
  'hostname': '${ database_node_name }',
  'user': '${postgres_user}',
  'password': '${postgres_password}',
}

google_client_id: "${google_client_id}"
google_client_secret: "${google_client_secret}"
aws_access_key_id: "${awsAccessKeyId}"
aws_secret_access_key: "${awsSecretAccessKey}"
