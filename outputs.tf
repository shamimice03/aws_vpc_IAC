output "baston_host_ip" {
  value = aws_instance.baston_host.public_ip
}

output "private_host_ip" {
  value = aws_instance.private_node.private_ip
}