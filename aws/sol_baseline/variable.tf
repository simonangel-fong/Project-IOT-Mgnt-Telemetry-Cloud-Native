# ##############################
# APP
# ##############################
variable "project" {
  type    = string
  default = "iot-mgnt-telemetry"
}

variable "env" {
  type    = string
  default = "baseline"
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
# AWS VPC
# ##############################
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

# ##############################
# AWS RDS
# ##############################
variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_app_pwd" {
  type = string
}

variable "db_readonly_pwd" {
  type = string
}

# ##############################
# AWS Cloudfront
# ##############################
variable "domain_name" {
  type    = string
  default = "arguswatcher.net"
}

locals {
  dns_record = "iot-${var.env}.${var.domain_name}"
}
