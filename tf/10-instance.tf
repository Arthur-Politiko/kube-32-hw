data "yandex_compute_image" "ubuntu-2004-lts" {
  family = var.vm_image_family
}

data "template_file" "master-node-init" {
  template = file("${path.module}/deploy/master-node-init.yml")
  vars = {
    ssh_private_key = file("../vault/id_ed25519")
    # ssh_public_key = "ubuntu:${file(var.vms_ssh_root_key)}"
    # internal_master_ip = var.internal_master_ip
  }
}

data "template_file" "worker-node-init" {
  template = file("${path.module}/deploy/worker-node-init.yml")
  vars = {
    ssh_public_key = "ubuntu:${file(var.vms_ssh_public_key)}"
    # internal_master_ip = var.internal_master_ip
  }
}

locals {
  user_data_templates = {
    # master = data.template_file.master-node-init.rendered
    # worker = data.template_file.worker-node-init.rendered
    master = file("${path.module}/deploy/master-node-init.yml")
    worker = file("${path.module}/deploy/worker-node-init.yml")
  }
}


resource "yandex_compute_instance" "vms" {
  for_each = { for vm in var.vms : vm.vm_name => vm }

  name = each.value.vm_name
  hostname = each.value.vm_name
  
  platform_id = var.vm_platform_id
  zone = var.default_zone

  resources {
    cores = var.vm_res_types[each.value.vm_res_type].cpu   # 
    memory = var.vm_res_types[each.value.vm_res_type].ram  #
    core_fraction = var.vm_res_types[each.value.vm_res_type].core_fraction #
  }
  metadata = {
    serial-port-enable = each.value.serial-port-enable ? "1" : "0"
    ssh-keys           = "ubuntu:${file(var.vms_ssh_public_key)}"
    # user-data          = each.value.user_data != "" ? file("${path.module}/${each.value.user_data}") : ""
    # user-data          = file("${path.module}/${each.value.user_data}")
    # user-data          = local.user_data_templates[each.value.vm_res_type]
  }
  boot_disk {
    initialize_params {
      # https://yandex.cloud/ru/docs/terraform/data-sources/compute_instance#nested-schema-for6
      image_id = data.yandex_compute_image.ubuntu-2004-lts.image_id
      size     = var.vm_res_types[each.value.vm_res_type].disk_volume  # GB
      #type     = "network-hdd"  # "network-ssd"
    }
  }
  scheduling_policy {
    # конфигурация политики планирования в контексте Yandex Cloud
    # preemptible - прерывание виртуальной машины
    preemptible = true #var.default_scheduling_policy_flag
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.sub.id
    nat       = each.value.nat_enable
    #nat       = true
    # https://terraform-provider.yandexcloud.net/resources/compute_instance
    # security_group_ids = [yandex_vpc_security_group.strict1.id]
  }
}

# 
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content = templatefile("${path.module}/templates/inventory.tpl", {
    master_ip = yandex_compute_instance.vms["k8s-master"].network_interface[0].nat_ip_address
    master_private_ip = yandex_compute_instance.vms["k8s-master"].network_interface[0].ip_address
    worker_ips = {
      for name, vm in yandex_compute_instance.vms :
      name => vm.network_interface[0].ip_address
      if name != "k8s-master"
    }
  })
}

