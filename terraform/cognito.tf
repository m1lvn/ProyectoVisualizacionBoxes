# --- Cognito User Pool ---
resource "aws_cognito_user_pool" "main" {
  name = "${var.cognito_user_pool_name}-${var.environment}"

  # Password policy
  password_policy {
    minimum_length    = var.password_minimum_length
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
  }

  # Attributes
  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]

  # Schema
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  schema {
    name                = "given_name"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  schema {
    name                = "family_name"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  # Custom attributes
  schema {
    name                = "hospital_id"
    attribute_data_type = "String"
    required            = false
    mutable             = true
  }

  schema {
    name                = "pasillo_asignado"
    attribute_data_type = "String"
    required            = false
    mutable             = true
  }

  schema {
    name                = "role"
    attribute_data_type = "String"
    required            = false
    mutable             = true
  }

  # Admin config
  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-user-pool"
    }
  )

  lifecycle {
    # El esquema de atributos de Cognito no puede modificarse una vez creado.
    # Ignoramos cambios en `schema` para evitar errores al reconciliar la
    # configuración declarativa con el pool preexistente.
    ignore_changes = [schema]
  }
}

# --- Cognito User Pool Client ---
resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.cognito_client_name}-${var.environment}"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"

  # Token validity
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  access_token_validity  = var.access_token_validity
  id_token_validity      = var.id_token_validity
  refresh_token_validity = var.refresh_token_validity
}

# --- Cognito User Groups ---
resource "aws_cognito_user_group" "admin" {
  name         = "Admin"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Administrators with full system access and management capabilities"
  precedence   = 1
}

resource "aws_cognito_user_group" "personal" {
  name         = "Personal"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Medical and nursing staff with access to assigned corridor only"
  precedence   = 2
}

resource "aws_cognito_user_group" "personal_administrativo" {
  name         = "PersonalAdministrativo"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Administrative staff with booking and reporting access to all corridors"
  precedence   = 3
}