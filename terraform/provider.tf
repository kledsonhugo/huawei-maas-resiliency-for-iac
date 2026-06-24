terraform {

  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "~> 1.91.0"
    }
  }

  # Remote state backend with encryption and versioning for production safety
  # IMPORTANTE: O bucket S3 "terraform-state-prod" deve ter versioning habilitado
  # no nível do bucket (via console ou API) para proteção completa contra
  # corrupção/sobrescrita do state file. O Terraform não gerencia versioning
  # do bucket de backend diretamente - isso deve ser feito externamente.
  #
  # Comando para habilitar versioning (execute uma vez):
  #   aws s3api put-bucket-versioning --bucket terraform-state-prod \
  #     --versioning-configuration Status=Enabled \
  #     --endpoint-url https://obs.sa-brazil-1.myhuaweicloud.com
  backend "s3" {
    bucket         = "terraform-state-prod"
    key            = "cce/terraform.tfstate"
    region         = "sa-brazil-1"
    endpoint       = "obs.sa-brazil-1.myhuaweicloud.com"
    encrypt        = true
    dynamodb_table = "terraform-locks"
    acl            = "private"
  }

}

provider "huaweicloud" {
  region = var.region

  # Security best practices
  insecure = false  # Explicitly disable insecure HTTP connections
}