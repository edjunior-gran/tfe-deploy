output "ecr_name" {
    value = aws_ecr_repository.ecr.name
}

output "ecr_url" {
    value = aws_ecr_repository.ecr.repository_url
}

output "service_name" {
    value = aws_ecs_service.fargate_service.name
}

output "service_arn" {
    value = aws_ecs_service.fargate_service.arn
}

output "task_definition_arn" {
    value = aws_ecs_task_definition.fargate_task.arn
}

output "task_definition_family" {
    value = aws_ecs_task_definition.fargate_task.family
}