output "dns_url" {
  value = "https://${cloudflare_record.dns_record.hostname}"
}

# output "redis_primary_endpoint" {
#   description = "Primary endpoint for Redis"
#   value       = aws_elasticache_replication_group.redis.primary_endpoint_address
# }

# output "redis_port" {
#   description = "Port for Redis"
#   value       = aws_elasticache_replication_group.redis.port
# }

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

# output "msk_bootstrap_brokers_tls" {
#   description = "Bootstrap broker string for TLS"
#   value       = aws_msk_cluster.kafka.bootstrap_brokers_tls
# }
