resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.project_name}/db/credentials"
  description             = "Credentials applicatifs pour la base de données"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.project_name}-db-credentials"
    Tier = "database"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username   = var.db_username
    password   = random_password.db.result
    table_name = aws_dynamodb_table.main.name
    table_arn  = aws_dynamodb_table.main.arn
    region     = var.aws_region
  })
}
