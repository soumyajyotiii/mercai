output "ecr_repository_url" {
  description = "url of the ecr repository"
  value       = aws_ecr_repository.app.repository_url
}

output "alb_dns_name" {
  description = "dns name of the application load balancer"
  value       = aws_lb.main.dns_name
}

output "ecs_cluster_name" {
  description = "name of the ecs cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "name of the ecs service"
  value       = aws_ecs_service.app.name
}
