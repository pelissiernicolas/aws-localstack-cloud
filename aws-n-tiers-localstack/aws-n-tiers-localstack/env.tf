resource "local_file" "env_local" {
  filename        = "${path.module}/.env.local"
  file_permission = "0600"

  content = <<-EOT
    # Généré automatiquement par Terraform - ne pas éditer manuellement
    # Usage : source .env.local

    export AWS_ENDPOINT_URL=http://localhost:4566
    export AWS_REGION=${var.aws_region}
    export AWS_DEFAULT_REGION=${var.aws_region}
    export AWS_ACCESS_KEY_ID=test
    export AWS_SECRET_ACCESS_KEY=test

    export DB_SECRET_NAME=${aws_secretsmanager_secret.db_credentials.name}
    export DB_SECRET_ARN=${aws_secretsmanager_secret.db_credentials.arn}
    export DYNAMODB_TABLE_NAME=${aws_dynamodb_table.main.name}
    export DYNAMODB_TABLE_ARN=${aws_dynamodb_table.main.arn}
  EOT
}
