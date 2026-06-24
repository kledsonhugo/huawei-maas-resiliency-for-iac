# ─── CCE Cluster ───────────────────────────────────────────────────────────────
# Cloud Container Engine cluster com alta disponibilidade (multi-AZ),
# autoscaling e integração com KMS para criptografia de secrets.

resource "huaweicloud_cce_cluster" "cce-cluster" {
  name                   = var.cluster_name
  region                 = var.region
  flavor_id              = "cce.s2.small" # HA flavor com 3 master nodes
  version                = var.kubernetes_version
  cluster_type           = "VirtualMachine"

  vpc_id                 = huaweicloud_vpc.vpc-cce.id
  subnet_id              = huaweicloud_vpc_subnet.subnet-cce.id

  # Multi-AZ: distribui masters entre zonas de disponibilidade
  multi_az               = true

  # High Availability: flavor com 3 master nodes garante quorum do etcd
  container_network_type = "overlay"
  container_network_cidr = "172.16.0.0/16"

  # API Server access control
  api_server_custom_cidr = var.api_allowed_cidr

  # Autenticação via proxy agents para comunicação segura com o cluster
  authenticating_proxy {
    certificate = ""  # Configurado via CSMS secret em produção
    private_key = ""  # Configurado via CSMS secret em produção
  }

  # Criptografia de volumes com KMS (se chave provisionada)
  kms_encryption = var.dew_kms_key_id != "" ? true : false
  kms_key_id     = var.dew_kms_key_id != "" ? var.dew_kms_key_id : null

  # Configuração de kube-proxy
  kube_proxy_mode = "iptables"

  # Tags para rastreabilidade
  tags = {
    environment = var.environment
    component   = "cce-cluster"
    managed-by  = "terraform"
  }

  # Lifecycle: prevenir destruição acidental do cluster
  lifecycle {
    prevent_destroy = true
  }
}

# ─── CCE Node Pool (Multi-AZ + Autoscaling) ──────────────────────────────────
# Node pool com distribuição entre zonas de disponibilidade e
# políticas de auto-scaling para ajuste dinâmico de capacidade.

resource "huaweicloud_cce_node_pool" "node-pool" {
  cluster_id         = huaweicloud_cce_cluster.cce-cluster.id
  name               = "${var.cluster_name}-pool"
  flavor_id          = var.node_flavor
  initial_node_count = var.node_count

  # Multi-AZ: distribui nós entre as zonas primária e HA
  availability_zone = "${var.availability_zone_primary},${var.availability_zone_ha}"

  # Autoscaling: ajuste dinâmico de nós conforme demanda
  scaling_enable    = var.enable_cluster_autoscaler
  min_node_count    = var.node_count_min
  max_node_count    = var.node_count_max
  scale_down_cooldown_time = 300 # 5 minutos entre scale-downs consecutivos
  priority          = 0

  # Subnet para os nós do pool
  subnet_id         = huaweicloud_vpc_subnet.subnet-cce.id

  # Configuração de OS e storage dos nós
  root_volume {
    size       = 40
    volumetype = "SSD"
  }

  data_volume {
    size       = 100
    volumetype = "SSD"
  }

  # Taints para controle de scheduling
  taint_key   = ""
  taint_value = ""

  # Labels para identificação e scheduling
  tags = {
    environment = var.environment
    component   = "cce-node-pool"
    managed-by  = "terraform"
  }

  # Prevenir destruição acidental do node pool
  lifecycle {
    prevent_destroy = true
  }
}

# ─── Node Pool HA (zona secundária) ──────────────────────────────────────────
# Node pool adicional na zona HA para garantir distribuição de carga
# e sobrevivência a falhas de zona de disponibilidade.

resource "huaweicloud_cce_node_pool" "node-pool-ha" {
  cluster_id         = huaweicloud_cce_cluster.cce-cluster.id
  name               = "${var.cluster_name}-pool-ha"
  flavor_id          = var.node_flavor
  initial_node_count = var.node_count_min

  # Nodes exclusivamente na zona HA
  availability_zone  = var.availability_zone_ha

  # Autoscaling para o pool HA
  scaling_enable     = var.enable_cluster_autoscaler
  min_node_count     = var.node_count_min
  max_node_count     = var.node_count_max
  scale_down_cooldown_time = 300
  priority           = 1

  # Subnet HA para os nós deste pool
  subnet_id          = huaweicloud_vpc_subnet.subnet-cce-ha.id

  root_volume {
    size       = 40
    volumetype = "SSD"
  }

  data_volume {
    size       = 100
    volumetype = "SSD"
  }

  tags = {
    environment = var.environment
    component   = "cce-node-pool-ha"
    purpose     = "high-availability"
    managed-by  = "terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}
