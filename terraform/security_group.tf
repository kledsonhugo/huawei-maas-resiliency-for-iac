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

  # 3. NodePort range (30000-32767) - restrito ao CIDR configurado
  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 30000
  port_range_max   = 32767
  remote_ip_prefix = var.nodeport_allowed_cidr
  description      = "Kubernetes NodePort services"
}

resource "huaweicloud_networking_secgroup_rule" "sg-cce-ingress-icmp" {
  security_group_id = huaweicloud_networking_secgroup.sg-cce.id

  # 4. ICMP para troubleshooting - restrito ao CIDR configurado
  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "icmp"
  remote_ip_prefix = var.icmp_allowed_cidr
  description      = "ICMP for network troubleshooting"
}

# 5. Comunicação interna entre nós do cluster (Kubernetes CNI / etcd / kubelet)
resource "huaweicloud_networking_secgroup_rule" "sg-cce-ingress-internal-tcp" {
  security_group_id = huaweicloud_networking_secgroup.sg-cce.id

  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 1
  port_range_max   = 65535
  remote_group_id  = huaweicloud_networking_secgroup.sg-cce.id
  description      = "Internal TCP communication between cluster nodes"
}

resource "huaweicloud_networking_secgroup_rule" "sg-cce-ingress-internal-udp" {
  security_group_id = huaweicloud_networking_secgroup.sg-cce.id

  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "udp"
  port_range_min   = 1
  port_range_max   = 65535
  remote_group_id  = huaweicloud_networking_secgroup.sg-cce.id
  description      = "Internal UDP communication between cluster nodes (VXLAN/CNI)"
}

# Regras de saída (egress) - permitir tráfego de saída para destinos necessários
resource "huaweicloud_networking_secgroup_rule" "sg-cce-egress-https" {
  security_group_id = huaweicloud_networking_secgroup.sg-cce.id

  direction        = "egress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 443
  port_range_max   = 443
  remote_ip_prefix = "0.0.0.0/0"
  description      = "Allow outbound HTTPS (API calls, image pulls)"
}

resource "huaweicloud_networking_secgroup_rule" "sg-cce-egress-dns" {
  security_group_id = huaweicloud_networking_secgroup.sg-cce.id

  direction        = "egress"
  ethertype        = "IPv4"
  protocol         = "udp"
  port_range_min   = 53
  port_range_max   = 53
  remote_ip_prefix = "100.125.1.250/32"
  description      = "Allow outbound DNS to Huawei Cloud DNS server (primary)"
}

resource "huaweicloud_networking_secgroup_rule" "sg-cce-egress-dns-secondary" {
  security_group_id = huaweicloud_networking_secgroup.sg-cce.id

  direction        = "egress"
  ethertype        = "IPv4"
  protocol         = "udp"
  port_range_min   = 53
  port_range_max   = 53
  remote_ip_prefix = "100.125.21.250/32"
  description      = "Allow outbound DNS to Huawei Cloud DNS server (secondary)"
}

resource "huaweicloud_networking_secgroup_rule" "sg-cce-egress-ntp" {
  security_group_id = huaweicloud_networking_secgroup.sg-cce.id

  direction        = "egress"
  ethertype        = "IPv4"
  protocol         = "udp"
  port_range_min   = 123
  port_range_max   = 123
  remote_ip_prefix = var.ntp_allowed_cidr
  description      = "Allow outbound NTP for time synchronization"
}

resource "huaweicloud_networking_secgroup_rule" "sg-cce-egress-internal" {
  security_group_id = huaweicloud_networking_secgroup.sg-cce.id

  direction        = "egress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 1
  port_range_max   = 65535
  remote_group_id  = huaweicloud_networking_secgroup.sg-cce.id
  description      = "Allow outbound traffic to other cluster nodes"
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
  remote_ip_prefix = var.lb_allowed_cidr
  description      = "HTTP access"
}

resource "huaweicloud_networking_secgroup_rule" "sg-lb-ingress-https" {
  security_group_id = huaweicloud_networking_secgroup.sg-lb.id

  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 443
  port_range_max   = 443
  remote_ip_prefix = var.lb_allowed_cidr
  description      = "HTTPS access"
}

# Egress restrito para o Load Balancer - apenas tráfego necessário
resource "huaweicloud_networking_secgroup_rule" "sg-lb-egress-internal" {
  security_group_id = huaweicloud_networking_secgroup.sg-lb.id

  direction        = "egress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 1
  port_range_max   = 65535
  remote_group_id  = huaweicloud_networking_secgroup.sg-cce.id
  description      = "Allow outbound traffic to CCE cluster nodes"
}

resource "huaweicloud_networking_secgroup_rule" "sg-lb-egress-dns" {
  security_group_id = huaweicloud_networking_secgroup.sg-lb.id

  direction        = "egress"
  ethertype        = "IPv4"
  protocol         = "udp"
  port_range_min   = 53
  port_range_max   = 53
  remote_ip_prefix = "100.125.1.250/32"
  description      = "Allow outbound DNS to Huawei Cloud DNS server (primary)"
}

resource "huaweicloud_networking_secgroup_rule" "sg-lb-egress-dns-secondary" {
  security_group_id = huaweicloud_networking_secgroup.sg-lb.id

  direction        = "egress"
  ethertype        = "IPv4"
  protocol         = "udp"
  port_range_min   = 53
  port_range_max   = 53
  remote_ip_prefix = "100.125.21.250/32"
  description      = "Allow outbound DNS to Huawei Cloud DNS server (secondary)"
}