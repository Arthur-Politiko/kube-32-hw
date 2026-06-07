output "vms_info" {
  #depends_on = [ yandex_compute_instance.vms ]
  description = "Information about all VMs"
  value = {
    for vm_name, vm in yandex_compute_instance.vms : vm_name => {
      internal_ip = vm.network_interface[0].ip_address
      external_ip = vm.network_interface[0].nat_ip_address
      hostname    = vm.hostname
    }
  }
}

output "connection_commands" {
  description = "SSH connection commands"
  value = {
    for vm_name, vm in yandex_compute_instance.vms : vm_name => 
    vm.network_interface[0].nat_ip_address != "" ? 
      "ssh ubuntu@${vm.network_interface[0].nat_ip_address} -i ../vault/id_ed25519" : ""
  }
}
