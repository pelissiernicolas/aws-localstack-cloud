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
  type    = string
  default = "admin"
}

variable "db_password" {
  type      = string
  default   = "Password123!"
  sensitive = true
}