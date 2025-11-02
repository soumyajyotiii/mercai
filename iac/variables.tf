variable "aws_region" {
  description = "aws region for resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "project name for resource naming"
  type        = string
  default     = "ecs-bg-deploy"
}

variable "environment" {
  description = "environment name"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "cidr block for vpc"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "container_port" {
  description = "port exposed by the container"
  type        = number
  default     = 3000
}

variable "app_count" {
  description = "number of docker containers to run"
  type        = number
  default     = 2
}

variable "fargate_cpu" {
  description = "fargate instance cpu units"
  type        = string
  default     = "256"
}

variable "fargate_memory" {
  description = "fargate instance memory"
  type        = string
  default     = "1024"
}

variable "app_image" {
  description = "docker image to run in ecs cluster"
  type        = string
  default     = "661399039717.dkr.ecr.us-west-2.amazonaws.com/ecs-bg-deploy-app:latest"
}
