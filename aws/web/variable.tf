# ##############################
# APP
# ##############################
variable "project" {
  type    = string
  default = "iot-mgnt-telemetry"
}

variable "env" {
  type    = string
  default = "dev"
}

# ##############################
# AWS
# ##############################
variable "aws_region" { type = string }

# ##############################
# Cloudflare
# ##############################
variable "cloudflare_api_token" { type = string }
variable "cloudflare_zone_id" { type = string }

# ##############################
# AWS Cloudfront
# ##############################
variable "domain_name" { type = string }

locals {
  dns_record = var.env == "prod" ? "iot.${var.domain_name}" : "iot-${var.env}.${var.domain_name}"
}