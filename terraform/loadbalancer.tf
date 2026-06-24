# ─── ELB Load Balancer ─────────────────────────────────────────────────────────
# Elastic Load Balancer com listener HTTPS e backend pool apontando
# para os nós do CCE. Garante distribuição de tráfego e alta disponibilidade.

# Security Group dedicado para o Load Balancer
resource "huaweicloud_networking_secgroup" "sg-lb" {
  name        = "sg-lb"
  description = "Security group for Load Balancer"

  tags = {
    environment = var.environment
    component   = "load-balancer"
    managed-by  = "terraform"
  }
}

# Regra ingress: HTTP (80) para redirecionamento
resource "huaweicloud_networking_secgroup_rule" "sg-lb-ingress-http" {
  security_group_id = huaweicloud_networking_secgroup.sg-lb.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = var.lb_allowed_cidr
  description       = "HTTP access for redirect to HTTPS"
}

# Regra ingress: HTTPS (443) para tráfego de aplicação
resource "huaweicloud_networking_secgroup_rule" "sg-lb-ingress-https" {
  security_group_id = huaweicloud_networking_secgroup.sg-lb.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = var.lb_allowed_cidr
  description       = "HTTPS access for application traffic"
}

# Regra egress: permitir tráfego para os nós do cluster
resource "huaweicloud_networking_secgroup_rule" "sg-lb-egress-cluster" {
  security_group_id = huaweicloud_networking_secgroup.sg-lb.id
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_group_id   = huaweicloud_networking_secgroup.sg-cce.id
  description       = "Allow traffic to CCE cluster nodes"
}

# ─── ELB Load Balancer ────────────────────────────────────────────────────────
resource "huaweicloud_elb_loadbalancer" "lb" {
  name           = "${var.cluster_name}-lb"
  description    = "Load Balancer for ${var.cluster_name} CCE cluster"
  type           = "External" # External para receber tráfego da internet
  vpc_id         = huaweicloud_vpc.vpc-cce.id
  subnet_id      = huaweicloud_vpc_subnet.subnet-cce.id
  security_group_id = huaweicloud_networking_secgroup.sg-lb.id

  # EIP para acesso externo
  publicip {
    ip_version = 4
  }

  # Auto-scaling do LB baseado em conexões
  l7_flavor_id = "" # Usa flavor padrão

  tags = {
    environment = var.environment
    component   = "load-balancer"
    managed-by  = "terraform"
  }
}

# Associa o EIP dedicado ao Load Balancer
resource "huaweicloud_vpc_eip_associate" "lb-eip-assoc" {
  public_ip   = huaweicloud_vpc_eip.eip-lb.address
  port_id     = huaweicloud_elb_loadbalancer.lb.vip_port_id
}

# ─── Listener HTTPS (443) ─────────────────────────────────────────────────────
resource "huaweicloud_elb_listener" "listener-https" {
  name            = "${var.cluster_name}-listener-https"
  description     = "HTTPS listener for application traffic"
  protocol        = "HTTPS"
  protocol_port   = 443
  loadbalancer_id = huaweicloud_elb_loadbalancer.lb.id

  # TLS com certificado do ELB (certificado deve ser provisionado previamente)
  # Em produção, o certificate_id deve ser configurado via CSMS secret
  server_certificate_id  = ""
  ca_certificate_id      = ""

  # Idle timeout para conexões
  idle_timeout    = 60

  tags = {
    environment = var.environment
    component   = "load-balancer"
    managed-by  = "terraform"
  }
}

# ─── Listener HTTP (80) → redireciona para HTTPS ─────────────────────────────
resource "huaweicloud_elb_listener" "listener-http" {
  name            = "${var.cluster_name}-listener-http"
  description     = "HTTP listener that redirects to HTTPS"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = huaweicloud_elb_loadbalancer.lb.id

  idle_timeout    = 60

  tags = {
    environment = var.environment
    component   = "load-balancer"
    managed-by  = "terraform"
  }
}

# ─── Backend Pool (grupo de servidores) ───────────────────────────────────────
resource "huaweicloud_elb_pool" "backend-pool" {
  name            = "${var.cluster_name}-backend-pool"
  description     = "Backend pool targeting CCE node pool"
  protocol        = "HTTP"
  lb_algorithm    = "ROUND_ROBIN" # Distribuição round-robin entre backends
  listener_id     = huaweicloud_elb_listener.listener-https.id

  # Health check para remover nós unhealthy do pool
  healthcheck {
    protocol    = "HTTP"
    port        = 8080
    url_path    = "/healthz"
    delay       = 10  # segundos entre checks
    timeout     = 5   # timeout por check
    max_retries = 3   # falhas antes de marcar unhealthy
  }

  # Session persistence (sticky sessions)
  session_persistence {
    type                = "HTTP_COOKIE"
    persistence_timeout = 30 # minutos
  }

  tags = {
    environment = var.environment
    component   = "load-balancer"
    managed-by  = "terraform"
  }
}

# ─── Health Check dedicado ────────────────────────────────────────────────────
resource "huaweicloud_elb_healthcheck" "hc-backend" {
  name           = "${var.cluster_name}-healthcheck"
  protocol       = "HTTP"
  port           = 8080
  url_path       = "/healthz"
  delay          = 10
  timeout        = 5
  max_retries    = 3
  pool_id        = huaweicloud_elb_pool.backend-pool.id

  tags = {
    environment = var.environment
    component   = "load-balancer"
    managed-by  = "terraform"
  }
}
