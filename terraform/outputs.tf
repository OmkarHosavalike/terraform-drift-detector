output "instance_id" {
  value = aws_instance.ec2_instances[*].id
}

output "instance_public_ips" {
  value = aws_instance.ec2_instances[*].public_ip
}