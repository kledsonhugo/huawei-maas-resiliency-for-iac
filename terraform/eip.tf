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

# Anti-DDoS protection para o EIP do CCE
resource "huaweicloud_antiddos" "antiddos-cce" {
  floating_ip_id     = huaweicloud_vpc_eip.eip-cce.id
  enable_l7          = true
  traffic_pos_id     = 1
  http_request_pos_id = 1
  cleaning_access_pos_id = 1
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

# Anti-DDoS protection para o EIP do Load Balancer
resource "huaweicloud_antiddos" "antiddos-lb" {
  floating_ip_id     = huaweicloud_vpc_eip.eip-lb.id
  enable_l7          = true
  traffic_pos_id     = 1
  http_request_pos_id = 1
  cleaning_access_pos_id = 1
}