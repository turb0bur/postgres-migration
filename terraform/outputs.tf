output "db_host" {
  description = "The connection endpoint for the database"
  value       = aws_db_instance.postgres_db.endpoint
}

output "db_name" {
  description = "The database name"
  value       = aws_db_instance.postgres_db.db_name
  sensitive   = true
}

output "db_user" {
  description = "The master username for the database"
  value       = aws_db_instance.postgres_db.username
  sensitive   = true
}

output "db_password" {
  description = "The database password"
  value       = aws_ssm_parameter.postgres_db_password.value
  sensitive   = true
}

output "db_port" {
  description = "The database port"
  value       = aws_db_instance.postgres_db.port
}

output "bastion_host_id" {
  description = "The instance ID of the bastion host"
  value       = aws_instance.bastion.id
}

output "ssm_connection_command" {
  description = "Command to connect to the bastion host using Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.bastion.id}"
} 