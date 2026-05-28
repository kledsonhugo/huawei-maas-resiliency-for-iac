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
  description = "Versão do Kubernetes"
  type        = string
  default     = "v1.25"
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
  description = "CIDR permitido para acesso às NodePort services. Restrinja em produção."
  type        = string
  default     = "10.0.0.0/16"
}

variable "icmp_allowed_cidr" {
  description = "CIDR permitido para ICMP (troubleshooting). Restrinja em produção."
  type        = string
  default     = "10.0.0.0/16"
}

variable "lb_allowed_cidr" {
  description = "CIDR permitido para acesso ao Load Balancer (HTTP/HTTPS)."
  type        = string
  default     = "0.0.0.0/0"
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