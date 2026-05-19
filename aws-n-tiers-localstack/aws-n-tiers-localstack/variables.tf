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

variable "web_ami_id" {
  description = "Override optionnel pour l'AMI de l'instance web. Si null, le data source aws_ami.ubuntu prend le relais. À renseigner pour LocalStack avec une AMI Docker-backed (ex: ami-df5de72bdb3b)"
  type        = string
  default     = null
}

variable "allowed_ssh_cidrs" {
  description = "CIDRs autorisés pour SSH vers l'instance web. Par défaut ouvert (LocalStack en local). À restreindre impérativement sur un compte AWS réel (ex: ['ton.ip.publique/32'])"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}