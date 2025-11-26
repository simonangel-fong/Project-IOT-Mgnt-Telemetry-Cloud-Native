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
# AWS VPC
# ##############################
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
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