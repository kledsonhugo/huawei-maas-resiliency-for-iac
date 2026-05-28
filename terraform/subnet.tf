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

# ─── Network ACL para defense-in-depth na subnet principal ───
resource "huaweicloud_network_acl" "acl-cce" {
  name        = "acl-cce"
  description = "Network ACL for CCE subnet - defense in depth"

  ingress_rules = [
    {
      rule_id   = huaweicloud_network_acl_rule.acl-ingress-ssh.id
    },
    {
      rule_id   = huaweicloud_network_acl_rule.acl-ingress-k8s-api.id
    },
    {
      rule_id   = huaweicloud_network_acl_rule.acl-ingress-internal.id
    },
  ]

  egress_rules = [
    {
      rule_id   = huaweicloud_network_acl_rule.acl-egress-https.id
    },
    {
      rule_id   = huaweicloud_network_acl_rule.acl-egress-dns.id
    },
    {
      rule_id   = huaweicloud_network_acl_rule.acl-egress-internal.id
    },
  ]

  subnets = [huaweicloud_vpc_subnet.subnet-cce.id]

  tags = {
    environment = var.environment
    component   = "cce-cluster"
    managed-by  = "terraform"
  }
}

# ACL Ingress Rules
resource "huaweicloud_network_acl_rule" "acl-ingress-ssh" {
  name             = "acl-ingress-ssh"
  description      = "Allow SSH from trusted CIDR"
  direction        = "ingress"
  protocol         = "tcp"
  source_ip_address = var.ssh_allowed_cidr
  destination_port = "22"
  action           = "allow"
  enabled          = true
}

resource "huaweicloud_network_acl_rule" "acl-ingress-k8s-api" {
  name             = "acl-ingress-k8s-api"
  description      = "Allow K8s API from trusted CIDR"
  direction        = "ingress"
  protocol         = "tcp"
  source_ip_address = var.api_allowed_cidr
  destination_port = "6443"
  action           = "allow"
  enabled          = true
}

resource "huaweicloud_network_acl_rule" "acl-ingress-internal" {
  name             = "acl-ingress-internal"
  description      = "Allow internal VPC traffic"
  direction        = "ingress"
  protocol         = "tcp"
  source_ip_address = var.vpc_cidr
  destination_port = "1-65535"
  action           = "allow"
  enabled          = true
}

# ACL Egress Rules
resource "huaweicloud_network_acl_rule" "acl-egress-https" {
  name             = "acl-egress-https"
  description      = "Allow outbound HTTPS"
  direction        = "egress"
  protocol         = "tcp"
  destination_ip_address = "0.0.0.0/0"
  destination_port = "443"
  action           = "allow"
  enabled          = true
}

resource "huaweicloud_network_acl_rule" "acl-egress-dns" {
  name             = "acl-egress-dns"
  description      = "Allow outbound DNS"
  direction        = "egress"
  protocol         = "udp"
  destination_ip_address = "0.0.0.0/0"
  destination_port = "53"
  action           = "allow"
  enabled          = true
}

resource "huaweicloud_network_acl_rule" "acl-egress-internal" {
  name             = "acl-egress-internal"
  description      = "Allow outbound to VPC"
  direction        = "egress"
  protocol         = "tcp"
  destination_ip_address = var.vpc_cidr
  destination_port = "1-65535"
  action           = "allow"
  enabled          = true
}