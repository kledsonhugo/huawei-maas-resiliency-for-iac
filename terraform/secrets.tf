# ─── Secrets Management: DEW KMS + CSMS ───────────────────────────────────────
# Integração com Data Encryption Workshop (DEW) para criptografia
# e Cloud Secret Management Service (CSMS) para gestão de secrets.
# Os IDs/nomes são referenciados pelo CCE cluster e outros recursos.

# KMS Key para criptografia de volumes e OBS (se não provisionada externamente)
# Nota: Se dew_kms_key_id já estiver definido (chave existente), este recurso
# não é criado. Use a variável create_kms_key para controlar isso.

variable "create_kms_key" {
  description = "Cria uma nova chave KMS. Se false, use dew_kms_key_id para referenciar chave existente."
  type        = bool
  default     = true
}

# KMS Key para criptografia de volumes do CCE e objetos do OBS
resource "huaweicloud_kms_key" "infra-key" {
  count               = var.create_kms_key ? 1 : 0
  key_alias           = "${var.cluster_name}-infra-key"
  key_description     = "KMS key for ${var.cluster_name} infrastructure encryption"
  pending_days        = 7  # Dias antes de deleção pendente (proteção contra deleção acidental)
  is_enabled          = true

  tags = {
    environment = var.environment
    component   = "secrets-management"
    managed-by  = "terraform"
  }

  # Prevenir deleção acidental da chave de criptografia
  lifecycle {
    prevent_destroy = true
  }
}

# CSMS Secret para credenciais sensíveis da infraestrutura
# Nota: O conteúdo do secret deve ser definido via API ou console
# após a criação do recurso. O Terraform cria apenas o metadado.
resource "huaweicloud_dew_csms_secret" "infra-secrets" {
  name        = var.csms_secret_name
  description = "Infrastructure secrets for ${var.cluster_name} - contains DB credentials, API keys, etc."
  kms_key_id  = var.create_kms_key ? huaweicloud_kms_key.infra-key[0].id : var.dew_kms_key_id

  # Rotatividade automática de secrets a cada 90 dias
  rotation_enabled = true
  rotation_period  = 90

  tags = {
    environment = var.environment
    component   = "secrets-management"
    managed-by  = "terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# ─── Cloud Trace Service (CTS) ────────────────────────────────────────────────
# Tracker para auditoria de operações na conta, garantindo rastreabilidade
# de todas as chamadas de API e mudanças de infraestrutura.

resource "huaweicloud_cts_tracker" "infra-tracker" {
  count      = var.enable_cts ? 1 : 0
  name       = "infra-tracker"
  bucket     = huaweicloud_obs_bucket.backup-bucket.bucket
  file_prefix = "cts-audit-logs/"

  # Habilitar notificação de eventos de segurança
  is_support_trace_messages = true
  is_support_smn            = var.enable_ces_alarms

  # SMN topic para notificações de auditoria
  smn_topic_urn = var.enable_ces_alarms ? huaweicloud_smn_topic.infra-alerts[0].topic_urn : null

  tags = {
    environment = var.environment
    component   = "security-auditing"
    managed-by  = "terraform"
  }
}
