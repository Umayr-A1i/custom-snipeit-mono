output "ec2_instance_id" {
  description = "EC2 instance ID for SSM commands"
  value       = aws_instance.snipeit_ec2.id
}

output "static_ip" {
  description = "Public static IP assigned to Snipe-IT host"
  value       = aws_eip.snipeit_eip.public_ip
}

output "ecr_snipeit_repo_url" {
  description = "ECR repository URL for the Snipe-IT image"
  value       = aws_ecr_repository.snipeit.repository_url
}

output "ecr_flask_repo_url" {
  description = "ECR repository URL for the Flask middleware image"
  value       = aws_ecr_repository.flask_middleware.repository_url
}
