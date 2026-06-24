# ─── Log Tank Service (LTS) ────────────────────────────────────────────────────
# Agregação centralizada de logs do cluster CCE e aplicações.
# Complementa os VPC flow logs já implementados em vpc.tf.

# LTS Log Group para logs de infraestrutura
resource "huaweicloud_lts_group" "infra-logs" {
  count       = var.enable_lts ? 1 : 0
  group_name  = "${var.cluster_name}-infra-logs"
  ttl_in_days = 30 # Retenção de 30 dias para logs de infra

  tags = {
    environment = var.environment
    component   = "logging"
    managed-by  = "terraform"
  }
}

# LTS Log Stream para logs do CCE cluster (kube-apiserver, kubelet, etc.)
resource "huaweicloud_lts_stream" "cce-cluster-logs" {
  count       = var.enable_lts ? 1 : 0
  group_id    = huaweicloud_lts_group.infra-logs[0].id
  stream_name = "cce-cluster-logs"

  tags = {
    environment = var.environment
    component   = "logging"
    source      = "cce-cluster"
    managed-by  = "terraform"
  }
}

# LTS Log Stream para logs de aplicação (containers)
resource "huaweicloud_lts_stream" "app-logs" {
  count       = var.enable_lts ? 1 : 0
  group_id    = huaweicloud_lts_group.infra-logs[0].id
  stream_name = "app-logs"

  tags = {
    environment = var.environment
    component   = "logging"
    source      = "application"
    managed-by  = "terraform"
  }
}

# LTS Log Stream para logs do Load Balancer
resource "huaweicloud_lts_stream" "lb-logs" {
  count       = var.enable_lts ? 1 : 0
  group_id    = huaweicloud_lts_group.infra-logs[0].id
  stream_name = "lb-logs"

  tags = {
    environment = var.environment
    component   = "logging"
    source      = "load-balancer"
    managed-by  = "terraform"
  }
}

# LTS Log Stream para VPC flow logs (centraliza os logs já gerados)
resource "huaweicloud_lts_stream" "vpc-flow-logs" {
  count       = var.enable_lts ? 1 : 0
  group_id    = huaweicloud_lts_group.infra-logs[0].id
  stream_name = "vpc-flow-logs"

  tags = {
    environment = var.environment
    component   = "logging"
    source      = "vpc-flow-logs"
    managed-by  = "terraform"
  }
}
