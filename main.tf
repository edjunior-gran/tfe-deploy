#################################
# Variaveis de ambiente Padrão
#################################

locals {
    name = "${var.environment}-${var.api_name}"
    tags = {
      team-owner = var.environment
      maneged-by = "terraform"
      application = var.api_name
    }
}




###############################
# create ecr repository
###############################
resource "aws_ecr_repository" "ecr" {
  name = "${local.name}-repo"
  image_tag_mutability = "MUTABLE"
  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = local.tags
}

#################################
# create lifecycle policy ecr repository
#################################

resource "aws_ecr_lifecycle_policy" "lifecycle_policy" {
  repository = aws_ecr_repository.ecr.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 6 images",
        selection    = {
          tagStatus    = "any",
          countType    = "imageCountMoreThan",
          countNumber  = 10
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}


#################################
# Build Image
#################################

resource "null_resource" "build_image" {
  triggers = {
    api_version = var.api_version
  }
  provisioner "local-exec" {
    command = <<EOT
        cd ..
        docker build -t ${aws_ecr_repository.ecr.repository_url}:${var.api_version} .
        aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.ecr.repository_url}
        docker push ${aws_ecr_repository.ecr.repository_url}:${var.api_version}
    EOT
  }
  depends_on = [ aws_ecr_repository.ecr ]
}

#################################
# Create Rule Listener in Load Balancer
#################################

resource "aws_lb_listener_rule" "listener_rule" {
  listener_arn = var.listener_arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
  condition {
    host_header {
      values = [ var.api_endpoint]
    }
  }
}

#################################
# Create target group for load balancer
#################################

resource "aws_lb_target_group" "target_group" {
  name     = "${local.name}-target-group"
  port     = var.api_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
  health_check {
    path                = "/"
    port                = var.api_port
    protocol            = "HTTP"
    timeout             = 5
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

#################################
# Create LogGroup CloudWatch
#################################

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/ecs/${local.name}"
  retention_in_days = 7
}

#################################
# Create task definition for ecs fargate
#################################

resource "aws_ecs_task_definition" "fargate_task" {
  family                   = "${local.name}-task"
  network_mode             = "awsvpc"  
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"     
  memory                   = "1024"    
  container_definitions = jsonencode([
    {
      name      = "${local.name}-container"
      image     = "${aws_ecr_repository.ecr.repository_url}:${var.api_version}"
      cpu       = 256
      memory    = 512
      essential = true
      linuxParameters = {
        initProcessEnabled = true
      }
      portMappings = [
        {
          containerPort = var.api_port
          hostPort      = var.api_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${local.name}"
          "awslogs-region"        = "${var.region}"
          "awslogs-stream-prefix" = "ecs"
        }
      }
      requires_compatibilities = ["FARGATE", "EC2"]
    }
  ])

  execution_role_arn = var.ecs_execution_role_arn
  task_role_arn      = var.ecs_task_role_arn
}

#################################
# Create service for ecs fargate
#################################

resource "aws_ecs_service" "fargate_service" {
  name            = "${local.name}-service"
  cluster         = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.fargate_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  force_new_deployment = true 
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.api_security_group]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "${local.name}-container"
    container_port   = var.api_port
  }


  depends_on = [ aws_ecs_task_definition.fargate_task ]
}