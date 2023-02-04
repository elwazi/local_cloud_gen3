source "openstack" "base_image" {
  flavor       = "${var.build_image_flavour}"
  image_name   = "${var.base_image_name}"
  external_source_image_url = "${var.base_image_source}"
  external_source_image_format = "${var.base_image_source_format}"
  ssh_username = "${var.admin_user}"
  networks = "${var.network_ids}"
  floating_ip_network = "${var.floating_ip_network_id}"
  security_groups = "${var.security_groups}"
  metadata = {
    hw_disk_bus = "scsi"
    hw_qemu_guest_agent = "yes",
    hw_rng_model = "virtio",
    hw_scsi_model = "virtio-scsi",
    hw_vif_model = "virtio"
  }
}

#source "openstack" "database_image" {
#  flavor       = "${var.build_image_flavour}"
#  image_name   = "${var.database_image_name}"
#  source_image_name = "${var.base_image_name}"
#  ssh_username = "${var.admin_user}"
#  networks = "${var.network_ids}"
#  floating_ip_network = "${var.floating_ip_network_id}"
#  security_groups = "${var.security_groups}"
#  metadata = {
#    hw_disk_bus = "scsi"
#    hw_qemu_guest_agent = "yes",
#    hw_rng_model = "virtio",
#    hw_scsi_model = "virtio-scsi",
#    hw_vif_model = "virtio"
#  }
#}

source "openstack" "k8s_image" {
  flavor       = "${var.build_image_flavour}"
  image_name   = "${var.k8s_image_name}"
  source_image_name = "${var.base_image_name}"
  ssh_username = "${var.admin_user}"
  networks = "${var.network_ids}"
  floating_ip_network = "${var.floating_ip_network_id}"
  security_groups = "${var.security_groups}"
  metadata = {
    hw_disk_bus = "scsi"
    hw_qemu_guest_agent = "yes",
    hw_rng_model = "virtio",
    hw_scsi_model = "virtio-scsi",
    hw_vif_model = "virtio"
  }
}

build {
  name = "step1"
  sources = [
    "source.openstack.base_image"
   ]
  provisioner "ansible" {
    use_proxy = false
    playbook_file = "./base.yml"
    ansible_env_vars = [
      "ANSIBLE_SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o AddKeysToAgent=no -o IdentitiesOnly=yes'"
    ]
    extra_arguments = ["--tags", "build"]
//    extra_arguments = ["-vvv"]
    user = "${var.admin_user}"
    groups = [
      "base_image"
    ]
  }
}

build {
  name = "step2"
  sources = [
    "source.openstack.k8s_image"
  ]
    provisioner "ansible" {
    use_proxy = false
    playbook_file = "./k8s.yml"
    extra_arguments = ["--tags", "build"]
    ansible_env_vars = [
      "ANSIBLE_SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o AddKeysToAgent=no -o IdentitiesOnly=yes'"
    ]
    user = "${var.admin_user}"
    groups = [
      "k8s_image"
    ]
  }
}

#build {
#  name = "step3"
#  sources = [
#    "source.openstack.docker_image"
#  ]
#    provisioner "ansible" {
#    use_proxy = false
#    playbook_file = "./docker.yml"
#    extra_arguments = ["--tags", "build"]
#    ansible_env_vars = [
#      "ANSIBLE_SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o AddKeysToAgent=no -o IdentitiesOnly=yes'"
#    ]
#    user = "${var.admin_user}"
#    groups = [
#      "docker_image"
#    ]
#  }
#}
