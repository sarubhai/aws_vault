# Name: outputs.tf
# Owner: Saurav Mitra
# Description: Outputs the EC2 Instances IP

output "vault_dc1_instances_ip" {
  value       = aws_instance.vault_dc1[*].private_ip
  description = "The Vault DC1 Instances IP's."
}

output "vault_dc2_instances_ip" {
  value       = aws_instance.vault_dc2[*].private_ip
  description = "The Vault DC2 Instances IP's."
}

output "vault_dc3_instances_ip" {
  value       = aws_instance.vault_dc3[*].private_ip
  description = "The Vault DC3 Instances IP's."
}

output "database_server_ip" {
  value       = aws_instance.database-server.private_ip
  description = "Database Server IP."
}

output "minikube_server_ip" {
  value       = aws_instance.minikube-server.private_ip
  description = "Minikube Server IP."
}
