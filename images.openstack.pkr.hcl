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

source "openstack" "database_image" {
  flavor       = "${var.build_image_flavour}"
  image_name   = "${var.database_image_name}"
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

source "openstack" "load_balancer_image" {
  flavor       = "${var.build_image_flavour}"
  image_name   = "${var.load_balancer_image_name}"
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

source "openstack" "rancher_rke2_server_image" {
  flavor       = "${var.build_image_flavour}"
  image_name   = "${var.rancher_rke2_server_image_name}"
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

source "openstack" "rancher_rke2_worker_image" {
  flavor       = "${var.build_image_flavour}"
  image_name   = "${var.rancher_rke2_worker_image_name}"
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
    extra_arguments = ["--tags", "build", "--extra-vars", "timezone=${var.timezone}"]
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
    "source.openstack.rancher_rke2_server_image"
  ]
    provisioner "ansible" {
    use_proxy = false
    playbook_file = "./rancher.yml"
    extra_arguments = ["--tags", "build_server"]
    ansible_env_vars = [
      "ANSIBLE_SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o AddKeysToAgent=no -o IdentitiesOnly=yes'"
    ]
    user = "${var.admin_user}"
    groups = [
      "rancher_rke2_image"
    ]
  }
}

build {
  name = "step3"
  sources = [
    "source.openstack.rancher_rke2_worker_image"
  ]
    provisioner "ansible" {
    use_proxy = false
    playbook_file = "./rancher.yml"
    extra_arguments = ["--tags", "build_worker"]
    ansible_env_vars = [
      "ANSIBLE_SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o AddKeysToAgent=no -o IdentitiesOnly=yes'"
    ]
    user = "${var.admin_user}"
    groups = [
      "rancher_rke2_image"
    ]
  }
}

build {
  name = "step4"
  sources = [
    "source.openstack.database_image"
  ]
    provisioner "ansible" {
    use_proxy = false
    playbook_file = "./database.yml"
    extra_arguments = ["--tags", "build"]
    ansible_env_vars = [
      "ANSIBLE_SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o AddKeysToAgent=no -o IdentitiesOnly=yes'"
    ]
    user = "${var.admin_user}"
    groups = [
      "database_image"
    ]
  }
}

build {
  name = "step5"
  sources = [
    "source.openstack.load_balancer_image"
  ]
    provisioner "ansible" {
    use_proxy = false
    playbook_file = "./load_balancer.yml"
    extra_arguments = ["--tags", "build"]
    ansible_env_vars = [
      "ANSIBLE_SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o AddKeysToAgent=no -o IdentitiesOnly=yes'"
    ]
    user = "${var.admin_user}"
    groups = [
      "load_balancer_image"
    ]
  }
}

build {
  name = "step5"
  sources = [
    "source.openstack.rancher_rke2_server_image"
  ]
    provisioner "ansible" {
    use_proxy = false
    playbook_file = "./rancher.yml"
    extra_arguments = ["--tags", "build"]
    ansible_env_vars = [
      "ANSIBLE_SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o AddKeysToAgent=no -o IdentitiesOnly=yes'"
    ]
    user = "${var.admin_user}"
    groups = [
      "rancher_image"
    ]
  }
}

