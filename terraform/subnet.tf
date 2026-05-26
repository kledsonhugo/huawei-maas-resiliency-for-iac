# Subnet para o CCE Cluster
resource "huaweicloud_vpc_subnet" "subnet-cce" {
  name       = "subnet-cce"
  cidr       = var.subnet_cidr
  gateway_ip = cidrhost(var.subnet_cidr, 1)
  vpc_id     = huaweicloud_vpc.vpc-cce.id

  # DNS servers da Huawei Cloud
  dns_list = ["100.125.1.250", "100.125.21.250"]

  tags = {
    environment = var.environment
    component   = "cce-cluster"
    managed-by  = "terraform"
  }
}

# Subnet adicional para alta disponibilidade (opcional)
resource "huaweicloud_vpc_subnet" "subnet-cce-ha" {
  name       = "subnet-cce-ha"
  cidr       = var.subnet_ha_cidr
  gateway_ip = cidrhost(var.subnet_ha_cidr, 1)
  vpc_id     = huaweicloud_vpc.vpc-cce.id

  dns_list = ["100.125.1.250", "100.125.21.250"]

  tags = {
    environment = var.environment
    component   = "cce-cluster"
    purpose     = "high-availability"
    managed-by  = "terraform"
  }
}