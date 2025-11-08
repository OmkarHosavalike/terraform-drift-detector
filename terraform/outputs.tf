output "ec2_instance_ids" {
  value = aws_instance.ec2_instances[*].id
}

output "ec2_instance_public_ips" {
  value = aws_instance.ec2_instances[*].public_ip
}