# ============================================
# AWS CONFIGURATION
# ============================================

variable "region" {
  description = "Región de AWS donde se desplegará la infraestructura"
  type        = string
  default     = "us-east-1"
}

# NOTA: aws_account_id se obtiene automáticamente mediante data.aws_caller_identity.current.account_id
# No es necesario configurarlo manualmente - se lee de las credenciales de ~/.aws/credentials

variable "project_name" {
  description = "Nombre base del proyecto (usado como prefijo en recursos)"
  type        = string
  # Mantener el nombre histórico para evitar reemplazos de recursos existentes
  default = "proyecto-hospital"
}

variable "environment" {
  description = "Entorno de deployment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ============================================
# NETWORKING CONFIGURATION
# ============================================

variable "vpc_cidr" {
  description = "CIDR block para la VPC principal"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block para la subnet pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block para la subnet privada"
  type        = string
  default     = "10.0.2.0/24"
}

# Subnet adicional personalizada (FASE 1)
variable "custom_subnet_cidr" {
  description = "CIDR block para la subnet personalizada (tercera subnet)"
  type        = string
  default     = "10.0.3.0/24"
}

# ============================================
# EC2 CONFIGURATION (Django Frontend)
# ============================================

variable "django_instance_type" {
  description = "Tipo de instancia EC2 para el servidor Django"
  type        = string
  default     = "t2.micro" # Free tier eligible
}

variable "ssh_key_name" {
  description = "Nombre del key pair SSH para acceder a EC2"
  type        = string
  # Nombre del keypair ya existente en la cuenta (evitar recrear/reemplazar)
  default = "my-ec2-key"
}

variable "github_repo_url" {
  description = "URL del repositorio GitHub del proyecto"
  type        = string
  default     = "https://github.com/m1lvn/ProyectoVisualizacionBoxes.git  "
}

variable "django_port" {
  description = "Puerto donde Django escuchará"
  type        = number
  default     = 8000
}

# ============================================
# LAMBDA CONFIGURATION
# ============================================

variable "lambda_runtime" {
  description = "Runtime de Node.js para funciones Lambda"
  type        = string
  default     = "nodejs18.x"
}

variable "lambda_timeout" {
  description = "Timeout por defecto para funciones Lambda (segundos)"
  type        = number
  default     = 30
}

variable "lambda_memory" {
  description = "Memoria asignada a funciones Lambda (MB)"
  type        = number
  default     = 256
}

variable "lambda_setup_users_timeout" {
  description = "Timeout para la función de setup de usuarios de prueba (segundos)"
  type        = number
  default     = 300 # 5 minutos
}

# ============================================
# COGNITO CONFIGURATION
# ============================================

variable "cognito_user_pool_name" {
  description = "Nombre del Cognito User Pool"
  type        = string
  default     = "hospital-user-pool"
}

variable "cognito_client_name" {
  description = "Nombre del Cognito User Pool Client"
  type        = string
  default     = "hospital-client"
}

variable "password_minimum_length" {
  description = "Longitud mínima de contraseña"
  type        = number
  default     = 8
}

variable "access_token_validity" {
  description = "Validez del access token en minutos"
  type        = number
  default     = 60
}

variable "id_token_validity" {
  description = "Validez del ID token en minutos"
  type        = number
  default     = 60
}

variable "refresh_token_validity" {
  description = "Validez del refresh token en días"
  type        = number
  default     = 30
}

# ============================================
# DYNAMODB CONFIGURATION
# ============================================

variable "dynamodb_table_name" {
  description = "Nombre de la tabla principal de DynamoDB"
  type        = string
  default     = "HospitalData"
}

variable "dynamodb_billing_mode" {
  description = "Modo de billing de DynamoDB (PROVISIONED o PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "enable_dynamodb_pitr" {
  description = "Habilitar Point-in-Time Recovery para DynamoDB"
  type        = bool
  default     = true
}

variable "enable_dynamodb_streams" {
  description = "Habilitar DynamoDB Streams"
  type        = bool
  default     = true
}

# ============================================
# SNS CONFIGURATION
# ============================================

variable "sns_topics_prefix" {
  description = "Prefijo para nombres de SNS topics"
  type        = string
  default     = "hospital"
}

# ============================================
# API GATEWAY CONFIGURATION
# ============================================

variable "api_gateway_name" {
  description = "Nombre del API Gateway"
  type        = string
  default     = "hospital-boxes-api"
}

variable "api_throttle_burst_limit" {
  description = "Límite de burst para throttling del API Gateway"
  type        = number
  default     = 5000
}

variable "api_throttle_rate_limit" {
  description = "Límite de rate para throttling del API Gateway"
  type        = number
  default     = 2000
}

# ============================================
# TAGS CONFIGURATION
# ============================================

variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default = {
    Project     = "Hospital Boxes Visualization"
    ManagedBy   = "Terraform"
    Environment = "dev"
    Team        = "DevOps"
  }
}

# ============================================
# FEATURE FLAGS
# ============================================

variable "enable_vpc_flow_logs" {
  description = "Habilitar VPC Flow Logs (para debugging de red)"
  type        = bool
  default     = false
}

variable "enable_api_gateway_logging" {
  description = "Habilitar logging detallado en API Gateway"
  type        = bool
  default     = true
}

variable "enable_lambda_insights" {
  description = "Habilitar CloudWatch Lambda Insights"
  type        = bool
  default     = false # Tiene costo adicional
}

variable "create_test_users" {
  description = "Crear usuarios de prueba automáticamente en Cognito"
  type        = bool
  default     = true
}

variable "create_iam_resources" {
  description = "Create dedicated IAM roles/policies for Lambdas when true"
  type        = bool
  default     = false
}

# ============================================
# SECURITY CONFIGURATION
# ============================================

variable "allowed_ssh_cidr" {
  description = "CIDR blocks permitidos para acceso SSH a EC2"
  type        = list(string)
  default     = ["0.0.0.0/0"] # ⚠️ Cambiar en producción
}

variable "allowed_http_cidr" {
  description = "CIDR blocks permitidos para acceso HTTP a EC2"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}