variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "proyecto-hospital"
}

variable "django_instance_type" {
  description = "Tipo de instancia EC2 para Django"
  type        = string
  default     = "t3.micro"
}

variable "rds_instance_class" {
  description = "Clase de instancia RDS MySQL"
  type        = string
  default     = "db.t3.micro"
}

variable "db_username" {
  description = "Usuario de la base de datos MySQL"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Contraseña de la base de datos MySQL"
  type        = string
  sensitive   = true
}

variable "ssh_key_name" {
  description = "Nombre de la clave SSH en AWS (debe existir)"
  type        = string
  default     = "my-ec2-key"
}

variable "serverless_api_name" {
  description = "Nombre de la API Serverless"
  type        = string
  default     = "serverless-api"
}