# Elastic IP para acesso externo ao cluster
resource "huaweicloud_vpc_eip" "eip-cce" {
  publicip {
    type = "5_bgp"
  }

  bandwidth {
    name        = "bandwidth-cce"
    size        = var.eip_bandwidth_size
    share_type  = "PER"
    charge_mode = "bandwidth"
  }

  tags = {
    environment = var.environment
    component   = "cce-cluster"
    purpose     = "external-access"
    managed-by  = "terraform"
  }
}

# EIP adicional para Load Balancer (opcional)
resource "huaweicloud_vpc_eip" "eip-lb" {
  publicip {
    type = "5_bgp"
  }

  bandwidth {
    name        = "bandwidth-lb"
    size        = var.lb_eip_bandwidth_size
    share_type  = "PER"
    charge_mode = "bandwidth"
  }

  tags = {
    environment = var.environment
    component   = "load-balancer"
    managed-by  = "terraform"
  }
}