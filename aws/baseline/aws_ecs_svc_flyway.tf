# aws_ecs_svc_flyway.tf
locals {
  ecr_flyway = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project}-flyway"
}

# #################################
# IAM: ECS Task Execution Role
# #################################
# assume role
resource "aws_iam_role" "ecs_task_execution_role_flyway" {
  name               = "${var.project}-${var.env}-task-execution-role-flyway"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ecs.json

  tags = {
    Project = var.project
    Role    = "ecs-task-execution-role-flyway"
  }
}

# policy attachment: exec role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_flyway" {
  role       = aws_iam_role.ecs_task_execution_role_flyway.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# #################################
# IAM: ECS Task Role
# #################################
resource "aws_iam_role" "ecs_task_role_flyway" {
  name               = "${var.project}-${var.env}-task-role-flyway"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ecs.json
}

# ##############################
# Security Group
# ##############################
resource "aws_security_group" "flyway" {
  name        = "${var.project}-${var.env}-sg-flyway"
  description = "Security group flyway"
  vpc_id      = aws_vpc.main.id

  # Egress to vpc only
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = [aws_vpc.main.cidr_block]
  }


  tags = {
    Name = "${var.project}-${var.env}-sg-flyway"
  }
}

# #################################
# ECS: Task Definition
# #################################
resource "aws_ecs_task_definition" "flyway" {
  family                   = "${var.project}-${var.env}-task-flyway"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role_flyway.arn
  task_role_arn            = aws_iam_role.ecs_task_role_flyway.arn

  container_definitions = templatefile("${path.module}/container/flyway.tftpl", {
    image         = local.ecr_flyway
    awslogs_group = aws_cloudwatch_log_group.flyway.name
    region        = var.aws_region

    pghost     = aws_db_instance.postgres.address
    pgport     = 5432
    pgdatabase = aws_db_instance.postgres.db_name
    pguser     = aws_db_instance.postgres.username
    pgpwd      = aws_db_instance.postgres.password

    app_user_password     = var.db_app_pwd
    app_readonly_password = var.db_readonly_pwd
  })

  tags = {
    Name = "${var.project}-${var.env}-task-db-init"
  }

  depends_on = [
    aws_db_instance.postgres,
    aws_cloudwatch_log_group.flyway,
  ]
}

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

