# ###########################################
# aws_ecs_svc_fastapi_monitoring.tf
# a file to define ECS fastapi task monitoring
# ###########################################

# #################################
# Monitoring: cup alarm
# #################################
resource "aws_cloudwatch_metric_alarm" "ecs_fastapi_high_cpu" {
  alarm_name          = "${var.project}-${var.env}-ecs-fastapi-high-cpu"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  statistic           = "Average"
  threshold           = 70
  period              = 60 # period in seconds
  evaluation_periods  = 2  # number of periods to compare with threshold.  

  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
    ServiceName = aws_ecs_service.ecs_svc_fastapi.name
  }

  alarm_description = "High CPU on ECS FastAPI service"
}
