# Security Group para o CCE Cluster
resource "huaweicloud_networking_secgroup" "sg-cce" {
  name        = "sg-cce"
  description = "Security group for CCE cluster nodes"

  tags = {
    environment = var.environment
    component   = "cce-cluster"
    managed-by  = "terraform"
  }
}

# Regras de entrada (ingress) para o Security Group
resource "huaweicloud_networking_secgroup_rule" "sg-cce-ingress" {
  security_group_id = huaweicloud_networking_secgroup.sg-cce.id

  # Regras básicas para Kubernetes
  # 1. SSH para administração (porta 22)
  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 22
  port_range_max   = 22
  remote_ip_prefix = var.ssh_allowed_cidr
  description      = "SSH access for administration"
}

resource "huaweicloud_networking_secgroup_rule" "sg-cce-ingress-k8s-api" {
  security_group_id = huaweicloud_networking_secgroup.sg-cce.id

  # 2. API Server Kubernetes (porta 6443)
  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 6443
  port_range_max   = 6443
  remote_ip_prefix = var.api_allowed_cidr
  description      = "Kubernetes API server access"
}

resource "huaweicloud_networking_secgroup_rule" "sg-cce-ingress-node-ports" {
  security_group_id = huaweicloud_networking_secgroup.sg-cce.id

  # 3. NodePort range (30000-32767)
  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 30000
  port_range_max   = 32767
  remote_ip_prefix = "0.0.0.0/0" # Em produção, ajustar conforme necessário
  description      = "Kubernetes NodePort services"
}

resource "huaweicloud_networking_secgroup_rule" "sg-cce-ingress-icmp" {
  security_group_id = huaweicloud_networking_secgroup.sg-cce.id

  # 4. ICMP para troubleshooting
  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "icmp"
  remote_ip_prefix = "0.0.0.0/0" # Em produção, restringir conforme necessário
  description      = "ICMP for network troubleshooting"
}

# Regras de saída (egress) - permitir todo tráfego de saída
resource "huaweicloud_networking_secgroup_rule" "sg-cce-egress-all" {
  security_group_id = huaweicloud_networking_secgroup.sg-cce.id

  direction        = "egress"
  ethertype        = "IPv4"
  remote_ip_prefix = "0.0.0.0/0"
  description      = "Allow all outbound traffic"
}

# Security Group adicional para Load Balancer (opcional)
resource "huaweicloud_networking_secgroup" "sg-lb" {
  name        = "sg-lb"
  description = "Security group for Load Balancer"

  tags = {
    environment = var.environment
    component   = "load-balancer"
    managed-by  = "terraform"
  }
}

resource "huaweicloud_networking_secgroup_rule" "sg-lb-ingress-http" {
  security_group_id = huaweicloud_networking_secgroup.sg-lb.id

  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 80
  port_range_max   = 80
  remote_ip_prefix = "0.0.0.0/0"
  description      = "HTTP access"
}

resource "huaweicloud_networking_secgroup_rule" "sg-lb-ingress-https" {
  security_group_id = huaweicloud_networking_secgroup.sg-lb.id

  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 443
  port_range_max   = 443
  remote_ip_prefix = "0.0.0.0/0"
  description      = "HTTPS access"
}