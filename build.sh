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

BASE_IMAGE_NAME=$(grep "^base_image_name" ${VARIABLES_FILE} | sed 's/.*= "\(.*\)"$/\1/')
DATABASE_IMAGE_NAME=$(grep "^database_image_name" ${VARIABLES_FILE} | sed 's/.*= "\(.*\)"$/\1/')
#DOCKER_IMAGE_NAME=$(grep "^docker_image_name" ${VARIABLES_FILE} | sed 's/.*= "\(.*\)"$/\1/')
K8S_IMAGE_NAME=$(grep "^k8s_image_name" ${VARIABLES_FILE} | sed 's/.*= "\(.*\)"$/\1/')
LOADBALANCER_IMAGE_NAME=$(grep "^load_balancer_image_name" ${VARIABLES_FILE} | sed 's/.*= "\(.*\)"$/\1/')

if openstack image show "${BASE_IMAGE_NAME}" &> /dev/null
then
  echo "Openstack image '${BASE_IMAGE_NAME}' found. Not rebuilding."
else
  echo "Openstack image '${BASE_IMAGE_NAME}' not found. Creating…"
  packer build -only="step1.openstack.base_image" .
fi

if openstack image show "${K8S_IMAGE_NAME}" &> /dev/null
then
  echo "Openstack image '${K8S_IMAGE_NAME}' found. Not rebuilding."
else
  echo "Openstack image '${K8S_IMAGE_NAME}' not found. Creating…"
  packer build -only="step2.openstack.k8s_image" .
fi

if openstack image show "${DATABASE_IMAGE_NAME}" &> /dev/null
then
  echo "Openstack image '${DATABASE_IMAGE_NAME}' found. Not rebuilding."
else
  echo "Openstack image '${DATABASE_IMAGE_NAME}' not found. Creating…"
  packer build -only="step3.openstack.database_image" .
fi

if openstack image show "${LOADBALANCER_IMAGE_NAME}" &> /dev/null
then
  echo "Openstack image '${LOADBALANCER_IMAGE_NAME}' found. Not rebuilding."
else
  echo "Openstack image '${LOADBALANCER_IMAGE_NAME}' not found. Creating…"
  packer build -only="step4.openstack.load_balancer_image" .
fi