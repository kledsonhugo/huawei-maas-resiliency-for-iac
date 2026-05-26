resource "huaweicloud_vpc" "vpc-cce" {
  name   = "vpc-cce"
  cidr   = var.vpc_cidr
  region = var.region

  tags = {
    environment = var.environment
    managed-by  = "terraform"
  }
}