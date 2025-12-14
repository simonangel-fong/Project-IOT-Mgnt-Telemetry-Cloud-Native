# aws_ecs_svc_kafka_consumer.tf

# #################################
# Variable
# #################################
locals {
  svc_consumer_log_group_name = "/ecs/task/${var.project}-${var.env}-kafka-consumer"
  ecr_consumer                = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project}:kafka-consumer"
  consumer_group_id           = "telemetry-consumer" # consumer group name
}

# #################################
# IAM: Task Execution Role
# #################################
resource "aws_iam_role" "consumer_task_execution_role" {
  name               = "${var.project}-${var.env}-task-execution-role-consumer"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ecs.json
}

# policy attachment: exec role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_consumer" {
  role       = aws_iam_role.consumer_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# #################################
# IAM: Task Role
# #################################
resource "aws_iam_role" "consumer_task_role" {
  name               = "${var.project}-${var.env}-task-role-consumer"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ecs.json
}

# policy attachment: consumer with msk
data "aws_iam_policy_document" "consumer_msk" {
  # cluster
  statement {
    sid    = "KafkaClusterConnectAndDescribe"
    effect = "Allow"
    actions = [
      "kafka-cluster:Connect",
      "kafka-cluster:DescribeCluster",
      "kafka-cluster:DescribeClusterDynamicConfiguration",
    ]
    resources = [
      "arn:aws:kafka:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${aws_msk_cluster.kafka.cluster_name}/${aws_msk_cluster.kafka.cluster_uuid}"
    ]
  }

  # topic
  statement {
    sid    = "KafkaTopicReadTelemetry"
    effect = "Allow"
    actions = [
      "kafka-cluster:DescribeTopic",
      "kafka-cluster:DescribeTopicDynamicConfiguration",
      "kafka-cluster:ReadData",
    ]
    resources = [
      "arn:aws:kafka:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topic/${aws_msk_cluster.kafka.cluster_name}/${aws_msk_cluster.kafka.cluster_uuid}/telemetry"
    ]
  }

  # Group
  statement {
    sid    = "KafkaConsumerGroupAccess"
    effect = "Allow"
    actions = [
      "kafka-cluster:DescribeGroup",
      "kafka-cluster:AlterGroup",
    ]
    resources = [
      "arn:aws:kafka:${var.aws_region}:${data.aws_caller_identity.current.account_id}:group/${aws_msk_cluster.kafka.cluster_name}/${aws_msk_cluster.kafka.cluster_uuid}/${local.consumer_group_id}"
    ]
  }
}

resource "aws_iam_policy" "consumer_msk" {
  name   = "${var.project}-${var.env}-consumer-msk"
  policy = data.aws_iam_policy_document.consumer_msk.json
}

resource "aws_iam_role_policy_attachment" "consumer_msk" {
  role       = aws_iam_role.consumer_task_role.name
  policy_arn = aws_iam_policy.consumer_msk.arn
}

# ##############################
# Security Group
# ##############################
resource "aws_security_group" "consumer" {
  name        = "${var.project}-${var.env}-sg-consumer"
  description = "Consumer security group"
  vpc_id      = aws_vpc.main.id

  # no ingress needed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.env}-sg-consumer"
  }
}

# #################################
# CloudWatch: log group
# #################################
resource "aws_cloudwatch_log_group" "log_group_consumer" {
  name              = local.svc_consumer_log_group_name
  retention_in_days = 7
  kms_key_id        = aws_kms_key.cloudwatch_log.arn

  tags = {
    Name = local.svc_consumer_log_group_name
  }
}

# #################################
# ECS: Task Definition
# #################################
resource "aws_ecs_task_definition" "ecs_task_consumer" {
  family                   = "${var.project}-${var.env}-task-consumer"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024

  execution_role_arn = aws_iam_role.consumer_task_execution_role.arn
  task_role_arn      = aws_iam_role.consumer_task_role.arn

  container_definitions = templatefile("${path.module}/container/kafka_consumer.tftpl", {
    image             = local.ecr_consumer
    cpu               = 512
    memory            = 1024
    awslogs_group     = local.svc_consumer_log_group_name
    region            = var.aws_region
    project           = var.project
    env               = var.env
    debug             = var.debug
    pgdb_host         = local.app_pgdb_host
    pgdb_db           = local.app_pgdb_db
    pgdb_user         = local.app_pgdb_user
    pgdb_pwd          = local.app_pgdb_pwd
    pool_size         = local.pool_size
    max_overflow      = local.max_overflow
    kafka_bootstrap   = aws_msk_cluster.kafka.bootstrap_brokers_sasl_iam
    consumer_group_id = local.consumer_group_id
  })

  tags = {
    Name = "${var.project}-${var.env}-task-consumer"
  }
}

# #################################
# ECS: Service
# #################################
resource "aws_ecs_service" "ecs_svc_consumer" {
  name    = "${var.project}-${var.env}-service-consumer"
  cluster = aws_ecs_cluster.ecs_cluster.id

  task_definition  = aws_ecs_task_definition.ecs_task_consumer.arn
  desired_count    = 2
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  network_configuration {
    security_groups  = [aws_security_group.consumer.id]
    subnets          = [for subnet in aws_subnet.private : subnet.id]
    assign_public_ip = false
  }

  tags = {
    Name = "${var.project}-${var.env}-service-consumer"
  }

  depends_on = [
    aws_cloudwatch_log_group.log_group_consumer,
  ]
}


# #################################
# Service: Scaling policy
# #################################
resource "aws_appautoscaling_target" "scaling_target_kafka_consumer" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_svc_consumer.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 10
}

# scaling policy: cpu
resource "aws_appautoscaling_policy" "scaling_cpu_kafka_consumer" {
  name               = "${var.project}-scale-cpu-kafka-consumer"
  resource_id        = aws_appautoscaling_target.scaling_target_kafka_consumer.resource_id
  scalable_dimension = aws_appautoscaling_target.scaling_target_kafka_consumer.scalable_dimension
  service_namespace  = aws_appautoscaling_target.scaling_target_kafka_consumer.service_namespace
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 60 # cpu%
    scale_in_cooldown  = 30
    scale_out_cooldown = 30
  }
}

resource "aws_appautoscaling_policy" "scaling_memory_kafka_consumer" {
  name               = "${var.project}-scale-memory-kafka-consumer"
  resource_id        = aws_appautoscaling_target.scaling_target_kafka_consumer.resource_id
  scalable_dimension = aws_appautoscaling_target.scaling_target_kafka_consumer.scalable_dimension
  service_namespace  = aws_appautoscaling_target.scaling_target_kafka_consumer.service_namespace
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 40
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}


