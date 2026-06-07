resource "yandex_vpc_network" "net" {
  name = var.vpc_name
}

resource "yandex_vpc_subnet" "sub" {
  name           = var.sub_vpc_name
  zone           = var.default_zone
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = var.default_cidr
}