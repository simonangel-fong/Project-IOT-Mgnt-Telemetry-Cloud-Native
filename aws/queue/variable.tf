# ##############################
# APP
# ##############################
variable "project" {
  type    = string
  default = "iot-mgnt-telemetry"
}

variable "env" {
  type    = string
  default = "queue"
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
# AWS ECS
# ##############################
variable "svc_fastapi_farget_cpu" {
  type    = number
  default = 2048
}

variable "svc_fastapi_farget_memory" {
  type    = number
  default = 4096
}

variable "svc_fastapi_desired_count" {
  type    = number
  default = 5
}

variable "svc_fastapi_min_capacity" {
  type    = number
  default = 5
}

variable "svc_fastapi_max_capacity" {
  type    = number
  default = 20
}

variable "task_fastapi_pool_size" {
  type    = number
  default = 20 # default: 5
}

variable "task_fastapi_max_overflow" {
  type    = number
  default = 10 # default: 10
}

variable "task_fastapi_worker" {
  type    = number
  default = 2 # default: 2 cpu
}

# ##############################
# AWS Elasticache
# ##############################
variable "redis_node_type" {
  description = "Instance type for Redis cache nodes"
  type        = string
  default     = "cache.t4g.micro"
}

variable "redis_num_cache_nodes" {
  description = "Number of Redis cache nodes"
  type        = number
  default     = 1
}


# ##############################
# AWS RDS
# ##############################
variable "instance_class" {
  type    = string
  default = "db.t4g.medium"
}

variable "rds_max_connection" {
  type    = number
  default = 400
}

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
