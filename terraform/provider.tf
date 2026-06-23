terraform {

  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "~> 1.91.0"
    }
  }

  # Remote state backend with encryption and versioning for production safety
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