
resource "aws_ssm_document" "session_manager_settings" {
  name            = "SSM-SessionManagerSettings"
  document_type   = "Session"
  document_format = "JSON"
  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Document to configure Session Manager preferences"
    sessionType   = "Standard_Stream"
    inputs = {
      s3BucketName                = ""
      s3KeyPrefix                 = ""
      s3EncryptionEnabled         = true
      cloudWatchLogGroupName      = ""
      cloudWatchEncryptionEnabled = true
      idleSessionTimeout          = "20"
      maxSessionDuration          = ""
      runAsEnabled                = false
      runAsDefaultUser            = ""
    }
  })
}

resource "aws_ssm_parameter" "postgres_db_name" {
  name  = format("/%s/%s", local.param_store_prefix, "db/name")
  type  = "String"
  value = var.rds_db_name

  tags = {
    Name = format(local.resource_name, "postgres-db-name")
  }
}

resource "aws_ssm_parameter" "postgres_db_user" {
  name  = format("/%s/%s", local.param_store_prefix, "db/user")
  type  = "String"
  value = var.rds_db_user

  tags = {
    Name = format(local.resource_name, "postgres-db-user")
  }
}

resource "aws_ssm_parameter" "postgres_db_password" {
  name  = format("/%s/%s", local.param_store_prefix, "db/password")
  type  = "SecureString"
  value = random_password.db_password.result

  tags = {
    Name = format(local.resource_name, "postgres-db-password")
  }
}

resource "random_password" "db_password" {
  length      = 32
  min_lower   = 8
  min_upper   = 8
  min_numeric = 4
  min_special = 4
}