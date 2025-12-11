output "db_endpoint" {
  description = "RDS endpoint for Snipe-IT V1"
  value       = aws_db_instance.snipeit_v1.address
}

output "ec2_instance_id" {
  description = "EC2 instance ID for Snipe-IT V1 host"
  value       = aws_instance.snipeit_ec2.id
}

output "ecr_snipeit_repo_url" {
  description = "ECR repo URL for Snipe-IT V1"
  value       = aws_ecr_repository.snipeit.repository_url
}

output "ecr_flask_repo_url" {
  description = "ECR repo URL for Flask middleware V1"
  value       = aws_ecr_repository.flask_middleware.repository_url
}
