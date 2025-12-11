# aws_ecs_svc_flyway_logging
locals {
  svc_flyway_log_group_name = "/ecs/task/${var.project}-${var.env}-init-db"
}

resource "aws_cloudwatch_log_group" "flyway" {
  name              = local.svc_flyway_log_group_name
  retention_in_days = 7

  kms_key_id = aws_kms_key.cloudwatch_log.arn

  tags = {
    Name = local.svc_flyway_log_group_name
  }
}
