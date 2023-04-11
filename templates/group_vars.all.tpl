---
timezone: '${ timezone }'
gen3_subnet: 192.168.10.0/24
rancher: {
  'hostname': '${rancher_hostname}',
}

gen3 : {
  'hostname': '${gen3_hostname}',
  'user': '${gen3_user}',
}

postgres: {
  'user': '${postgres_user}',
  'password': '${postgres_password}',
}

google_client_id: "${google_client_id}"
google_client_secret: "${google_client_secret}"
aws_access_key_id: "${awsAccessKeyId}"
aws_secret_access_key: "${awsSecretAccessKey}"
