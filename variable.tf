variable "environment" {
    description = "The environment to deploy to"
    type        = string
}

variable "region" {
    description = "The AWS region to deploy to"
    type        = string
}

variable "load_balancer" {
    description = "The name of the load balancer"
    type        = string
}

variable "listener_arn" {
    description = "The ARN of the listener"
    type        = string
}

variable "vpc_id" {
    description = "The VPC ID"
    type        = string
}

variable "subnet_ids" {
    description = "The subnet IDs"
    type        = list(string)
}

variable "api_security_group" {
  description = "The security group for the API"
  type        = string 
}

variable "api_endpoint" {
  description = "The endpoint for the API"
  type        = string
}

variable "api_name" {
  description = "The name of the API"
  type        = string
}

variable "api_version" {
  description = "The version of the api"
  type        = string
}

variable "api_port" {
  description = "The port the API will listen on"
  type        = number
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "The ARN of the ECS task role"
  type        = string
}

variable "ecs_execution_role_arn" {
  description = "The ARN of the ECS execution role"
  type        = string
}