resource "huaweicloud_vpc" "vpc-cce" {
  name   = "vpc-cce"
  cidr   = var.vpc_cidr
  region = var.region

  tags = {
    environment = var.environment
    managed-by  = "terraform"
  }
}

# VPC Flow Logs para auditoria e monitoramento de segurança
resource "huaweicloud_vpc_flow_log" "vpc-cce-flowlog" {
  count       = var.enable_vpc_flow_logs ? 1 : 0
  name        = "vpc-cce-flowlog"
  vpc_id      = huaweicloud_vpc.vpc-cce.id
  resource_type = "vpc"
  traffic_type = "all"
  description = "Flow log for security auditing on VPC"

  tags = {
    environment = var.environment
    component   = "network-auditing"
    managed-by  = "terraform"
  }
}