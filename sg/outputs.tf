# Name: outputs.tf
# Owner: Saurav Mitra
# Description: Outputs the Securtiy Group ID for Vault Server

output "vault_sg_id" {
  value       = aws_security_group.vault_sg.id
  description = "Security Group for Vault."
}

output "database_sg_id" {
  value       = aws_security_group.database_sg.id
  description = "Security Group for Database Server."
}
