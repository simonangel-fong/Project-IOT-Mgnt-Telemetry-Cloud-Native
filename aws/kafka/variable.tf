# ##############################
# APP
# ##############################
variable "project" {
  type    = string
  default = "iot-mgnt-telemetry"
}

variable "env" {
  type    = string
  default = "kafka"
}

variable "debug" {
  type    = bool
  default = true
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

locals {
  ecr_repo = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project}"
}

variable "scale_cpu" {
  type    = number
  default = 40
}

variable "kafka_topic" {
  type    = string
  default = "telemetry"
}

variable "svc_param" {
  type = map(object({
    image_suffix  = string
    cpu           = number
    memory        = number
    count_desired = number
    count_min     = number
    count_max     = number
    container_env = map(any)
  }))
  default = {
    fastapi_svc = {
      image_suffix  = "fastapi-kafka"
      cpu           = 2048
      memory        = 4096
      count_desired = 4
      count_min     = 4
      count_max     = 10
      container_env = {
        pool_size    = 20
        max_overflow = 10
        worker       = 2
      }
    },
    kafka_consumer_svc = {
      image_suffix  = "kafka-consumer"
      cpu           = 1024
      memory        = 2048
      count_desired = 3
      count_min     = 2
      count_max     = 10
      container_env = {
        pool_size    = 20
        max_overflow = 10
        worker       = 1
        group_id     = "telemetry-consumer"
      }
    }
  }
}

variable "task_param" {
  type = map(object({
    image_suffix  = string
    cpu           = number
    memory        = number
    container_env = map(any)
    })
  )
  default = {
    flyway = {
      image_suffix  = "flyway"
      cpu           = 512
      memory        = 1024
      container_env = {}
    }
    kafka_init = {
      image_suffix  = "kafka-init"
      cpu           = 512
      memory        = 1024
      container_env = {}
    }
  }
}

# ##############################
# AWS Elastiredis
# ##############################
variable "redis_node_type" {
  description = "Instance type for Redis redis nodes"
  type        = string
  default     = "cache.t4g.micro"
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
# AWS MSK
# ##############################
variable "kafka_instance_type" {
  type    = string
  default = "kafka.t3.small"
}

variable "kafka_volume_size" {
  type    = number
  default = 20
}

variable "kafka_broker_count" {
  type    = number
  default = 3
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
