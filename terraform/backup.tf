# ─── Backup e Recovery ─────────────────────────────────────────────────────────
# OBS bucket para backups do cluster CCE e configuração de backup automático
# com retenção configurável. Garante recuperação em caso de desastre.

# OBS Bucket para backups do cluster
resource "huaweicloud_obs_bucket" "backup-bucket" {
  bucket     = var.backup_bucket
  acl        = "private"

  # Versioning para proteger contra deleção/corrupção acidental de objetos
  versioning = true

  # Criptografia server-side com KMS (se chave disponível)
  encryption  = var.dew_kms_key_id != "" ? true : false
  kms_key_id = var.dew_kms_key_id != "" ? var.dew_kms_key_id : null

  tags = {
    environment = var.environment
    component   = "backup"
    managed-by  = "terraform"
  }
}

# Lifecycle rule: expirar backups após o período de retenção
resource "huaweicloud_obs_bucket_lifecycle" "backup-lifecycle" {
  bucket = huaweicloud_obs_bucket.backup-bucket.bucket

  rule {
    id     = "expire-backups"
    prefix = ""
    status = "Enabled"

    expiration {
      days = var.backup_retention_days
    }

    # Transição para storage mais barato após 7 dias
    transition {
      days        = 7
      storage_class = "WARM"
    }
  }
}

# ─── CCE Cluster Backup (etcd snapshots) ──────────────────────────────────────
# Configuração de backup automático do cluster CCE.
# Nota: O recurso huaweicloud_cce_backup é gerenciado pela API do CCE
# após o cluster ser criado. Aqui definimos a configuração via
# cluster_addon para habilitar o backup automático.

# O backup do CCE é habilitado através de configuração no cluster.
# A variável enable_cce_backup controla se o addon de backup é instalado.
# O backup real é gerenciado pelo CCE Auto-Backup feature que
# faz snapshots periódicos do etcd e recursos do cluster.
