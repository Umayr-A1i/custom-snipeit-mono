output "ec2_instance_id" {
  value = aws_instance.snipeit_ec2.id
}

output "static_ip" {
  value = aws_eip.snipeit_eip.public_ip
}
