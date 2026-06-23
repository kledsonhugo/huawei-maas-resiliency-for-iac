# Variáveis para configuração do CCE

variable "region" {
  description = "Região da Huawei Cloud"
  type        = string
  default     = "sa-brazil-1"
}

variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block para a subnet principal"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_ha_cidr" {
  description = "CIDR block para a subnet de alta disponibilidade"
  type        = string
  default     = "10.0.2.0/24"
}

variable "cluster_name" {
  description = "Nome do cluster CCE"
  type        = string
  default     = "cce-cluster"
}

variable "node_flavor" {
  description = "Flavor (tipo de instância) para os nós do cluster"
  type        = string
  default     = "s6.large.2"
}

variable "node_count" {
  description = "Número de nós no cluster"
  type        = number
  default     = 3
}

variable "kubernetes_version" {
  description = "Versão do Kubernetes. Use versões suportadas (v1.28+)."
  type        = string
  default     = "v1.28"

  validation {
    condition     = can(regex("^v1\\.(2[8-9]|[3-9][0-9])", var.kubernetes_version))
    error_message = "Versão do Kubernetes deve ser v1.28 ou superior. Versões anteriores estão EOL e possuem vulnerabilidades conhecidas."
  }
}

variable "eip_bandwidth_size" {
  description = "Tamanho da banda (Mbps) para o EIP"
  type        = number
  default     = 100
}

variable "lb_eip_bandwidth_size" {
  description = "Tamanho da banda (Mbps) para o EIP do Load Balancer"
  type        = number
  default     = 50
}

variable "ssh_allowed_cidr" {
  description = "CIDR permitido para acesso SSH. NUNCA use 0.0.0.0/0 em produção."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = var.ssh_allowed_cidr != "0.0.0.0/0" || var.environment != "production"
    error_message = "SSH não deve ser exposto para 0.0.0.0/0 em produção. Restrinja a um CIDR específico."
  }
}

variable "api_allowed_cidr" {
  description = "CIDR permitido para acesso à API do Kubernetes. NUNCA use 0.0.0.0/0 em produção."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = var.api_allowed_cidr != "0.0.0.0/0" || var.environment != "production"
    error_message = "A API do Kubernetes não deve ser exposta para 0.0.0.0/0 em produção. Restrinja a um CIDR específico."
  }
}

variable "nodeport_allowed_cidr" {
  description = "CIDR permitido para acesso às NodePort services. NUNCA use 0.0.0.0/0 em produção."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = var.nodeport_allowed_cidr != "0.0.0.0/0" || var.environment != "production"
    error_message = "NodePorts não devem ser expostos para 0.0.0.0/0 em produção. Restrinja a um CIDR específico."
  }
}

variable "icmp_allowed_cidr" {
  description = "CIDR permitido para ICMP (troubleshooting). NUNCA use 0.0.0.0/0 em produção."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = var.icmp_allowed_cidr != "0.0.0.0/0" || var.environment != "production"
    error_message = "ICMP não deve ser exposto para 0.0.0.0/0 em produção. Restrinja a um CIDR específico."
  }
}

variable "lb_allowed_cidr" {
  description = "CIDR permitido para acesso ao Load Balancer (HTTP/HTTPS). Em produção, restrinja a um CIDR específico."
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = var.lb_allowed_cidr != "0.0.0.0/0" || var.environment != "production"
    error_message = "O Load Balancer não deve ser exposto para 0.0.0.0/0 em produção. Restrinja a um CIDR específico."
  }
}

variable "ntp_allowed_cidr" {
  description = "CIDR permitido para acesso NTP (sincronização de horário). Restrinja em produção."
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = var.ntp_allowed_cidr != "0.0.0.0/0" || var.environment != "production"
    error_message = "NTP não deve ser aberto para 0.0.0.0/0 em produção. Use servidores NTP específicos."
  }
}

variable "enable_vpc_flow_logs" {
  description = "Habilita VPC flow logs para auditoria de rede"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Ambiente de deploy (dev, staging, production)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "O ambiente deve ser 'dev', 'staging' ou 'production'."
  }
}

# ─── Availability Zones ───

variable "availability_zone_primary" {
  description = "Zona de disponibilidade primária para a subnet do CCE"
  type        = string
  default     = "sa-brazil-1a"
}

variable "availability_zone_ha" {
  description = "Zona de disponibilidade secundária para a subnet HA do CCE"
  type        = string
  default     = "sa-brazil-1b"
}

# ─── Auto-scaling ───

variable "node_count_min" {
  description = "Número mínimo de nós no cluster (auto-scaling)"
  type        = number
  default     = 2
}

variable "node_count_max" {
  description = "Número máximo de nós no cluster (auto-scaling)"
  type        = number
  default     = 10
}

variable "enable_cluster_autoscaler" {
  description = "Habilita o cluster autoscaler para ajuste dinâmico de nós"
  type        = bool
  default     = true
}

# ─── Secrets Management (DEW/CSMS) ───

variable "dew_kms_key_id" {
  description = "ID da chave KMS no DEW para criptografia de secrets. Deve ser provisionado previamente."
  type        = string
  default     = ""
}

variable "csms_secret_name" {
  description = "Nome do secret no CSMS (Cloud Secret Management Service) para credenciais sensíveis"
  type        = string
  default     = "cce-infra-secrets"
}

# ─── Monitoring ───

variable "enable_ces_alarms" {
  description = "Habilita alarmes no Cloud Eye (CES) para monitoramento de métricas"
  type        = bool
  default     = true
}

variable "enable_lts" {
  description = "Habilita Log Tank Service (LTS) para agregação centralizada de logs"
  type        = bool
  default     = true
}

variable "smn_notification_topic" {
  description = "Nome do tópico SMN para notificações de alertas"
  type        = string
  default     = "infra-alerts"
}

variable "alarm_email_addresses" {
  description = "Lista de e-mails para receber notificações de alertas"
  type        = list(string)
  default     = []
}

# ─── Backup / Recovery ───

variable "enable_cce_backup" {
  description = "Habilita backup automático do cluster CCE (etcd snapshots)"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Dias de retenção para backups do CCE"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 30
    error_message = "A retenção de backups deve ser entre 1 e 30 dias."
  }
}

variable "backup_bucket" {
  description = "Nome do bucket OBS para armazenar backups do cluster"
  type        = string
  default     = "cce-cluster-backups"
}

# ─── Security Monitoring ───

variable "enable_hss" {
  description = "Habilita Host Security Service (HSS) para detecção de intrusão"
  type        = bool
  default     = true
}

variable "enable_cts" {
  description = "Habilita Cloud Trace Service (CTS) para auditoria de operações"
  type        = bool
  default     = true
}

# ─── Production Guards for NodePort and ICMP ───

variable "nodeport_allowed_cidr" {
  description = "CIDR permitido para acesso às NodePort services. NUNCA use 0.0.0.0/0 em produção."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = var.nodeport_allowed_cidr != "0.0.0.0/0" || var.environment != "production"
    error_message = "NodePort não deve ser exposto para 0.0.0.0/0 em produção. Restrinja a um CIDR específico."
  }
}

variable "icmp_allowed_cidr" {
  description = "CIDR permitido para ICMP (troubleshooting). NUNCA use 0.0.0.0/0 em produção."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = var.icmp_allowed_cidr != "0.0.0.0/0" || var.environment != "production"
    error_message = "ICMP não deve ser exposto para 0.0.0.0/0 em produção. Restrinja a um CIDR específico."
  }
}