
output "flyway_task_param" {
  description = "Parameters to run the Flyway ECS task for RDS initialization"
  value = {
    cluster         = aws_ecs_cluster.ecs_cluster.name
    task_definition = aws_ecs_task_definition.flyway.arn
    launch_type     = "FARGATE"
    subnets         = [for s in aws_subnet.private : s.id]
    security_groups = [aws_security_group.flyway.id]
  }
}

output "flyway_init_cmd" {
  value = <<EOF

    aws ecs run-task
        --region "${var.aws_region}"
        --cluster "${aws_ecs_cluster.ecs_cluster.name}" 
        --task-definition "${aws_ecs_task_definition.flyway.arn}"
        --launch-type "FARGATE"
        --network-configuration "awsvpcConfiguration={subnets=[${join(",", [for s in aws_subnet.private : s.id])}],securityGroups=[${aws_security_group.flyway.id}]}"
        --output text

  EOF

}
