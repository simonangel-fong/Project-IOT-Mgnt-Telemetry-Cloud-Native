# ###########################################
# aws_ecs_svc_fastapi_logging.tf
# a file to define ECS fastapi task logging
# ###########################################

# #################################
# CloudWatch: log group
# #################################
resource "aws_cloudwatch_log_group" "log_group_fastapi" {
  name              = local.svc_fastapi_log_group_name
  retention_in_days = 7
  kms_key_id        = aws_kms_key.cloudwatch_log.arn

  tags = {
    Name = "${var.project}-${var.env}-log-group-fastapi"
  }
}
