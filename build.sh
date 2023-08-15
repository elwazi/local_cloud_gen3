#!/bin/bash
set -e

VARIABLES_FILE=variables.auto.hcl

if [[ ! -f $VARIABLES_FILE ]]; then
  echo -e "Variables file ${VARIABLES_FILE} not found. Use ${VARIABLES_FILE}.template as a template.\nAborting build."
  exit 1
fi

if grep -q "TODO:CONFIGURE_ME" $VARIABLES_FILE; then
  echo -e "Unconfigured variables found in $VARIABLES_FILE. Please update the values.\n\n$(cat ${VARIABLES_FILE} | grep 'TODO:CONFIGURE_ME')\n"
  echo -e "Note the following existing Network and Security Groups:\n$(openstack network list; openstack security group list)\n"
  echo "Aborting build."
  exit 1
fi

echo "" | openstack -q image list &> /dev/null || { echo -e "Openstack seemingly not connected. Remember to source your '?-openrc.sh' file.\nAborting build."; exit 1; }

VARIABLES=$(packer inspect .)

BASE_IMAGE_NAME=$(echo "${VARIABLES}" | grep "^local.base_image_name" | sed 's/.*: //' | sed 's/\"//g')
DATABASE_IMAGE_NAME=$(echo "${VARIABLES}" | grep "^local.database_image_name" | sed 's/.*: //' | sed 's/\"//g')
RANCHER_RKE2_SERVER_IMAGE_NAME=$(echo "${VARIABLES}" | grep "^local.rancher_rke2_server_image_name" | sed 's/.*: //' | sed 's/\"//g')
RANCHER_RKE2_WORKER_IMAGE_NAME=$(echo "${VARIABLES}" | grep "^local.rancher_rke2_worker_image_name" | sed 's/.*: //' | sed 's/\"//g')
LOADBALANCER_IMAGE_NAME=$(echo "${VARIABLES}" | grep "^local.load_balancer_image_name" | sed 's/.*: //' | sed 's/\"//g')

if openstack image show "${BASE_IMAGE_NAME}" &> /dev/null
then
  echo "Openstack image '${BASE_IMAGE_NAME}' found. Not rebuilding."
else
  echo "Openstack image '${BASE_IMAGE_NAME}' not found. Creating…"
  packer build -only="step1.openstack.base_image" .
fi

to_build=""

if openstack image show "${RANCHER_RKE2_SERVER_IMAGE_NAME}" &> /dev/null
then
  echo "Openstack image '${RANCHER_RKE2_SERVER_IMAGE_NAME}' found. Not rebuilding."
else
  echo "Openstack image '${RANCHER_RKE2_SERVER_IMAGE_NAME}' not found. Creating…"
  to_build="${to_build},step2.openstack.rancher_rke2_server_image"
  #packer build -only="step2.openstack.rancher_rke2_server_image" .
fi

if openstack image show "${RANCHER_RKE2_WORKER_IMAGE_NAME}" &> /dev/null
then
  echo "Openstack image '${RANCHER_RKE2_WORKER_IMAGE_NAME}' found. Not rebuilding."
else
  echo "Openstack image '${RANCHER_RKE2_WORKER_IMAGE_NAME}' not found. Creating…"
  to_build="${to_build},step3.openstack.rancher_rke2_worker_image"
  #packer build -only="step3.openstack.rancher_rke2_worker_image" .
fi

if openstack image show "${DATABASE_IMAGE_NAME}" &> /dev/null
then
  echo "Openstack image '${DATABASE_IMAGE_NAME}' found. Not rebuilding."
else
  echo "Openstack image '${DATABASE_IMAGE_NAME}' not found. Creating…"
  to_build="${to_build},step4.openstack.database_image"
  #packer build -only="step4.openstack.database_image" .
fi

if openstack image show "${LOADBALANCER_IMAGE_NAME}" &> /dev/null
then
  echo "Openstack image '${LOADBALANCER_IMAGE_NAME}' found. Not rebuilding."
else
  echo "Openstack image '${LOADBALANCER_IMAGE_NAME}' not found. Creating…"
  to_build="${to_build},step5.openstack.load_balancer_image"
  #packer build -only="step5.openstack.load_balancer_image" .
fi

to_build=$(echo "${to_build}" | sed 's/^,//')  # remove leading comma

if [[ ! -z "${to_build}" ]]; then
  echo "Building images: ${to_build}"
  packer build -only="${to_build}" .
fi
