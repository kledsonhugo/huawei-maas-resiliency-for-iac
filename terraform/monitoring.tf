# ─── Monitoramento: Cloud Eye (CES) + SMN + LTS ──────────────────────────────
# Implementa alarmes de métricas, tópicos de notificação e agregação
# centralizada de logs para observabilidade completa da infraestrutura.

# ─── SMN Topic para notificações de alertas ───────────────────────────────────
resource "huaweicloud_smn_topic" "infra-alerts" {
  count               = var.enable_ces_alarms ? 1 : 0
  name                = var.smn_notification_topic
  display_name        = "Infrastructure Alerts - ${var.environment}"

  tags = {
    environment = var.environment
    component   = "monitoring"
    managed-by  = "terraform"
  }
}

# SMN Email subscriptions para cada endereço configurado
resource "huaweicloud_smn_subscription" "email-subscriptions" {
  count               = var.enable_ces_alarms ? length(var.alarm_email_addresses) : 0
  topic_urn           = huaweicloud_smn_topic.infra-alerts[0].topic_urn
  protocol            = "email"
  endpoint            = var.alarm_email_addresses[count.index]
  remark              = "Alert subscription for ${var.environment}"
}

# ─── CES Alarm: CPU alta nos nós do cluster ───────────────────────────────────
resource "huaweicloud_ces_alarmrule" "cpu-high" {
  count               = var.enable_ces_alarms ? 1 : 0
  alarm_name          = "${var.cluster_name}-cpu-high"
  alarm_description   = "Alerta quando CPU dos nós do cluster excede 80% por 5 minutos"
  alarm_action_enabled = true

  condition {
    period              = 300  # 5 minutos
    filter              = "average"
    comparison_operator = ">="
    value               = 80

    metric {
      namespace   = "SYS.ECS"
      metric_name = "cpu_util"
      dimensions {
        name  = "instance_id"
        value = huaweicloud_cce_node_pool.node-pool.id
      }
    }
  }

  alarm_actions {
    type              = "notification"
    notification_list = [huaweicloud_smn_topic.infra-alerts[0].topic_urn]
  }

  tags = {
    environment = var.environment
    component   = "monitoring"
    managed-by  = "terraform"
  }
}

# ─── CES Alarm: Memória alta nos nós ──────────────────────────────────────────
resource "huaweicloud_ces_alarmrule" "memory-high" {
  count               = var.enable_ces_alarms ? 1 : 0
  alarm_name          = "${var.cluster_name}-memory-high"
  alarm_description   = "Alerta quando memória dos nós do cluster excede 85% por 5 minutos"
  alarm_action_enabled = true

  condition {
    period              = 300
    filter              = "average"
    comparison_operator = ">="
    value               = 85

    metric {
      namespace   = "SYS.ECS"
      metric_name = "mem_util"
      dimensions {
        name  = "instance_id"
        value = huaweicloud_cce_node_pool.node-pool.id
      }
    }
  }

  alarm_actions {
    type              = "notification"
    notification_list = [huaweicloud_smn_topic.infra-alerts[0].topic_urn]
  }

  tags = {
    environment = var.environment
    component   = "monitoring"
    managed-by  = "terraform"
  }
}

# ─── CES Alarm: Disco baixo nos nós ───────────────────────────────────────────
resource "huaweicloud_ces_alarmrule" "disk-low" {
  count               = var.enable_ces_alarms ? 1 : 0
  alarm_name          = "${var.cluster_name}-disk-low"
  alarm_description   = "Alerta quando disco disponível nos nós fica abaixo de 15% por 5 minutos"
  alarm_action_enabled = true

  condition {
    period              = 300
    filter              = "average"
    comparison_operator = "<="
    value               = 15

    metric {
      namespace   = "SYS.ECS"
      metric_name = "disk_available"
      dimensions {
        name  = "instance_id"
        value = huaweicloud_cce_node_pool.node-pool.id
      }
    }
  }

  alarm_actions {
    type              = "notification"
    notification_list = [huaweicloud_smn_topic.infra-alerts[0].topic_urn]
  }

  tags = {
    environment = var.environment
    component   = "monitoring"
    managed-by  = "terraform"
  }
}

# ─── CES Alarm: Health check do Load Balancer ─────────────────────────────────
resource "huaweicloud_ces_alarmrule" "lb-unhealthy" {
  count               = var.enable_ces_alarms ? 1 : 0
  alarm_name          = "${var.cluster_name}-lb-unhealthy"
  alarm_description   = "Alerta quando backends do Load Balancer ficam unhealthy"
  alarm_action_enabled = true

  condition {
    period              = 60
    filter              = "average"
    comparison_operator = ">"
    value               = 0

    metric {
      namespace   = "SYS.ELB"
      metric_name = "lb_unhealthy_server_num"
      dimensions {
        name  = "pool_id"
        value = huaweicloud_elb_pool.backend-pool.id
      }
    }
  }

  alarm_actions {
    type              = "notification"
    notification_list = [huaweicloud_smn_topic.infra-alerts[0].topic_urn]
  }

  tags = {
    environment = var.environment
    component   = "monitoring"
    managed-by  = "terraform"
  }
}

# ─── CES Alarm: Conexões ativas no LB ─────────────────────────────────────────
resource "huaweicloud_ces_alarmrule" "lb-connections-high" {
  count               = var.enable_ces_alarms ? 1 : 0
  alarm_name          = "${var.cluster_name}-lb-connections-high"
  alarm_description   = "Alerta quando conexões ativas no LB excedem 5000 por 3 minutos"
  alarm_action_enabled = true

  condition {
    period              = 180
    filter              = "average"
    comparison_operator = ">="
    value               = 5000

    metric {
      namespace   = "SYS.ELB"
      metric_name = "lb_active_connections"
      dimensions {
        name  = "loadbalancer_id"
        value = huaweicloud_elb_loadbalancer.lb.id
      }
    }
  }

  alarm_actions {
    type              = "notification"
    notification_list = [huaweicloud_smn_topic.infra-alerts[0].topic_urn]
  }

  tags = {
    environment = var.environment
    component   = "monitoring"
    managed-by  = "terraform"
  }
}
