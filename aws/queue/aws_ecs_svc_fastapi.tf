# aws_ecs_svc_fastapi.tf

# #################################
# Variable
# #################################
locals {
  svc_fastapi_log_group_name = "/ecs/task/${var.project}-${var.env}-fastapi"
  debug                      = var.debug
  ecr_fastapi                = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project}:fastapi-kafka"
  app_pgdb_host              = aws_db_instance.postgres.address
  app_pgdb_db                = aws_db_instance.postgres.db_name
  app_pgdb_user              = aws_db_instance.postgres.username
  app_pgdb_pwd               = aws_db_instance.postgres.password
  pool_size                  = var.task_fastapi_pool_size
  max_overflow               = var.task_fastapi_max_overflow
  worker                     = var.task_fastapi_worker
  cpu                        = var.svc_fastapi_farget_cpu
  memory                     = var.svc_fastapi_farget_memory
}

# #################################
# IAM: Execution Role
# #################################
# assume role
resource "aws_iam_role" "execution_role_fastapi" {
  name               = "${var.project}-${var.env}-execution-role-fastapi"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ecs.json
}

# policy attachment: exec role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_fastapi" {
  role       = aws_iam_role.execution_role_fastapi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# #################################
# IAM: Task Role
# #################################
resource "aws_iam_role" "task_role_fastapi" {
  name               = "${var.project}-${var.env}-task-role-fastapi"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ecs.json
}

# policy: fastapi to msk
data "aws_iam_policy_document" "fastapi_to_msk" {
  # Connect
  statement {
    sid    = "KafkaClusterConnectAndDescribe"
    effect = "Allow"
    actions = [
      "kafka-cluster:Connect",
      "kafka-cluster:DescribeCluster",
      "kafka-cluster:DescribeClusterDynamicConfiguration",
    ]
    resources = [
      "arn:aws:kafka:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${aws_msk_cluster.kafka.cluster_name}/*"
    ]
  }

  # Topic
  statement {
    sid    = "KafkaTopicAccess"
    effect = "Allow"
    actions = [
      "kafka-cluster:DescribeTopic",
      "kafka-cluster:DescribeTopicDynamicConfiguration",
      "kafka-cluster:WriteData",
    ]
    resources = [
      "arn:aws:kafka:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topic/${aws_msk_cluster.kafka.cluster_name}/*/telemetry"
    ]
  }
}

resource "aws_iam_policy" "fastapi_msk" {
  name   = "${var.project}-${var.env}-fastapi-msk"
  policy = data.aws_iam_policy_document.fastapi_to_msk.json
}

resource "aws_iam_role_policy_attachment" "fastapi_msk" {
  role       = aws_iam_role.task_role_fastapi.name
  policy_arn = aws_iam_policy.fastapi_msk.arn
}


# ##############################
# Security Group
# ##############################
resource "aws_security_group" "fastapi" {
  name        = "${var.project}-${var.env}-sg-fastapi"
  description = "App security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow load balancer to ingress"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # limit source: alb
  }

  # Egress to vpc only
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.env}-sg-fastapi"
  }
}

# #################################
# ECS: Task Definition
# #################################
resource "aws_ecs_task_definition" "ecs_task_fastapi" {
  family                   = "${var.project}-${var.env}-task-fastapi"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.svc_fastapi_farget_cpu
  memory                   = var.svc_fastapi_farget_memory
  execution_role_arn       = aws_iam_role.execution_role_fastapi.arn
  task_role_arn            = aws_iam_role.task_role_fastapi.arn

  # method: json file
  # container_definitions = file("./container/fastapi.json")

  # method: template file
  container_definitions = templatefile("${path.module}/container/fastapi.tftpl", {
    image           = local.ecr_fastapi
    cpu             = local.cpu
    memory          = local.memory
    awslogs_group   = local.svc_fastapi_log_group_name
    region          = var.aws_region
    project         = var.project
    env             = var.env
    debug           = local.debug
    pgdb_host       = local.app_pgdb_host
    pgdb_db         = local.app_pgdb_db
    pgdb_user       = local.app_pgdb_user
    pgdb_pwd        = local.app_pgdb_pwd
    pool_size       = local.pool_size
    max_overflow    = local.max_overflow
    worker          = local.worker
    redis_host      = aws_elasticache_replication_group.redis.primary_endpoint_address
    redis_port      = aws_elasticache_replication_group.redis.port
    kafka_bootstrap = aws_msk_cluster.kafka.bootstrap_brokers_sasl_iam
  })

  tags = {
    Name = "${var.project}-${var.env}-task-fastapi"
  }
}

# #################################
# ECS: Service
# #################################
resource "aws_ecs_service" "ecs_svc_fastapi" {
  name    = "${var.project}-${var.env}-service-fastapi"
  cluster = aws_ecs_cluster.ecs_cluster.id

  # task
  task_definition  = aws_ecs_task_definition.ecs_task_fastapi.arn
  desired_count    = var.svc_fastapi_desired_count
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  # network
  network_configuration {
    security_groups  = [aws_security_group.fastapi.id]
    subnets          = [for subnet in aws_subnet.private : subnet.id]
    assign_public_ip = false # disable public ip
  }

  # lb
  load_balancer {
    target_group_arn = aws_alb_target_group.fastapi_svc.arn
    container_name   = "fastapi"
    container_port   = 8000
  }

  tags = {
    Name = "${var.project}-${var.env}-service-fastapi"
  }

  depends_on = [
    aws_cloudwatch_log_group.log_group_fastapi,
    aws_vpc_endpoint.ecr_api,
    aws_vpc_endpoint.ecr_dkr,
    aws_vpc_endpoint.s3,
  ]
}

# # #################################
# # Service: Scaling policy
# # #################################
# resource "aws_appautoscaling_target" "scaling_target_fastapi" {
#   service_namespace  = "ecs"
#   resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_svc_fastapi.name}"
#   scalable_dimension = "ecs:service:DesiredCount"
#   min_capacity       = var.svc_fastapi_min_capacity
#   max_capacity       = var.svc_fastapi_max_capacity
# }

# # scaling policy: cpu
# resource "aws_appautoscaling_policy" "scaling_cpu_fastapi" {
#   name               = "${var.project}-scale-cpu-fastapi"
#   resource_id        = aws_appautoscaling_target.scaling_target_fastapi.resource_id
#   scalable_dimension = aws_appautoscaling_target.scaling_target_fastapi.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.scaling_target_fastapi.service_namespace
#   policy_type        = "TargetTrackingScaling"

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageCPUUtilization"
#     }
#     target_value       = 60 # cpu%
#     scale_in_cooldown  = 30
#     scale_out_cooldown = 30
#   }
# }

# resource "aws_appautoscaling_policy" "scaling_memory_fastapi" {
#   name               = "${var.project}-scale-memory-fastapi"
#   resource_id        = aws_appautoscaling_target.scaling_target_fastapi.resource_id
#   scalable_dimension = aws_appautoscaling_target.scaling_target_fastapi.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.scaling_target_fastapi.service_namespace
#   policy_type        = "TargetTrackingScaling"

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageMemoryUtilization"
#     }
#     target_value       = 40
#     scale_in_cooldown  = 60
#     scale_out_cooldown = 60
#   }
# }
