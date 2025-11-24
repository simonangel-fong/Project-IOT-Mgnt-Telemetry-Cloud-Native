# # ##############################
# # ALB SG
# # ##############################
# resource "aws_security_group" "alb" {
#   name        = "${var.project}-${var.env}-sg-alb"
#   description = "ALB security group"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     description = "Allow HTTP ingress"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     # cidr_blocks = ["0.0.0.0/0"]
#     cidr_blocks = [aws_vpc.main.cidr_block]
#   }

#   egress {
#     description = "Allow all egress"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     # cidr_blocks = ["0.0.0.0/0"]
#     cidr_blocks = [aws_vpc.main.cidr_block]
#   }

#   tags = {
#     Name = "${var.project}-${var.env}-sg-alb"
#   }
# }

# # ##############################
# # ALB
# # ##############################
# resource "aws_alb" "alb" {
#   name               = "${var.project}-${var.env}-alb"
#   load_balancer_type = "application"
#   internal           = false
#   subnets            = [for subnet in aws_subnet.public : subnet.id]
#   security_groups    = [aws_security_group.alb.id]

#   drop_invalid_header_fields = true
# }

# # ##############################
# # ALB Target Group
# # ##############################
# resource "aws_alb_target_group" "http" {
#   name        = "${var.project}-${var.env}-lb-tg"
#   target_type = "ip"
#   vpc_id      = aws_vpc.main.id
#   port        = 8000
#   protocol    = "HTTP"

#   health_check {
#     path                = "/api/health/"
#     matcher             = "200-399"
#     interval            = 15
#     timeout             = 5
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#   }
# }

# # ##############################
# # ALB listener
# # ##############################
# # Route traffic from the ALB to the target group
# resource "aws_alb_listener" "lb_lsn" {
#   load_balancer_arn = aws_alb.alb.id
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     target_group_arn = aws_alb_target_group.http.arn
#     type             = "forward"
#   }
# }
