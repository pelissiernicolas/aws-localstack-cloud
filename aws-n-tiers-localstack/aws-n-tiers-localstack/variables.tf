variable "project_name" {
  type    = string
  default = "lab-factory"
}

variable "aws_region" {
  type    = string
  default = "eu-west-3"
}

variable "vpc_cidr" {
  type    = string
  default = "172.16.0.0/16"
}

variable "db_username" {
  description = "Nom d'utilisateur applicatif stocké dans Secrets Manager"
  type        = string
  default     = "admin"
}