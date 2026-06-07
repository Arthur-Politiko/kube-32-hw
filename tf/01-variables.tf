###cloud vars
# variable "token" {
#   type        = string
#   description = "OAuth-token; https://cloud.yandex.ru/docs/iam/concepts/authorization/oauth-token"
# }

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

variable "default_cidr" {
  type        = list(string)
  default     = ["10.0.1.0/24"]
  description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
}

variable "vpc_name" {
  type        = string
  default     = "net"
  description = "VPC network name"
}

variable "sub_vpc_name" {
  type        = string
  default     = "subnet"
  description = "VPC subnet name"
}

###common vars

variable "vms_ssh_public_key" {
  type        = string
  default     = "../vault/id_ed25519.pub"
  description = "ssh-keygen -t ed25519"
}

###example vm_web var
variable "vm_web_name" {
  type        = string
  default     = "netology-develop-platform-web"
  description = "example vm_web_ prefix"
}

###example vm_db var
variable "vm_db_name" {
  type        = string
  default     = "netology-develop-platform-db"
  description = "example vm_db_ prefix"
}

#**********************************************#
variable "vm_platform_id" {
  type        = string
  default     = "standard-v1"
  description = "https://yandex.cloud/ru/docs/compute/concepts/vm-platforms"
}

variable "vm_image_family" {
  type        = string
  default     = "ubuntu-2404-lts"
  description = "https://cloud.yandex.ru/docs/compute/concepts/images"
}

variable "vm_res_types" {
  type = map(object({
    cpu = optional(number, 1), 
    ram = optional(number, 1), 
    core_fraction = optional(number, 20), 
    disk_volume = optional(number, 10)
  }))
  default = {
    "master" = {
      cpu       = 4
      ram       = 8
      core_fraction = 100
      disk_volume  = 20
    },
    "worker" = {
      cpu       = 2
      ram       = 4
    }
  }
  description = "Node type templates for reuse"
}

variable "vms" {
  type = list(object({  
    vm_name = string, 
    vm_res_type = string,
    serial-port-enable = optional(bool, true), 
    nat_enable = optional(bool, true), 
    # "user-data" = optional(string, ""), 
    # inline = optional(string, ""),
    internal_ip = optional(string, "")
    external_ip = optional(string, "")
  }))
  default = [
    { vm_name = "k8s-master", nat_enable = true,   vm_res_type = "master" },
    { vm_name = "k8s-worker-01", vm_res_type = "worker" },
    { vm_name = "k8s-worker-02", vm_res_type = "worker" },
    { vm_name = "k8s-worker-03", vm_res_type = "worker" },
    { vm_name = "k8s-worker-04", vm_res_type = "worker" },
    { vm_name = "k8s-worker-05", vm_res_type = "worker" }
    # { vm_name = "docker-host", 
    #   user_data = "docker-init-vm.yml" },
    # { vm_name = "jumphost",
    #   user_data = "jumphost-init-vm.yml"}
  ]
  description = "List of VMs"
}

variable "registry_name" {
  type        = string
  default     = "container-reg"
  description = "https://yandex.cloud/ru/docs/container-registry/operations/"
}

variable "registry_label" {
  type        = string
  default     = "registry-label"
  description = "https://yandex.cloud/ru/docs/container-registry/operations/"
}
 
variable "repo_name" {
  type    = string
  default = "my-app"
}

variable "image_tag" {
  type    = string
  default = "v1.0"
}

#**********************************************#
variable "security_group_01_name" {
  type    = string
  default = "strict_01"
}

#**********************************************#
# calculated vars
variable "internal_master_ip" {
  type        = string
  default     = "10.0.1.1"
  description = "Internal IP of master node, needed for worker node initialization"
}  

variable "external_master_ip" {
  type        = string
  default     = "1.0.1.1"
  description = "External IP of master node, needed for worker node initialization"
}  