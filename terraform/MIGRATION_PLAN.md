# 🚀 Plan de Migración Completo a Terraform

**Fecha de creación**: Noviembre 7, 2025  
**Estado**: FASE 1 Completada ✅  
**Objetivo**: Migrar toda la infraestructura de Serverless Framework a Terraform

---

## 📊 Índice

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Estado Actual vs. Estado Objetivo](#estado-actual-vs-estado-objetivo)
3. [Inventario de Recursos](#inventario-de-recursos)
4. [Fases de Implementación](#fases-de-implementación)
5. [Archivos a Crear](#archivos-a-crear)
6. [Archivos a Eliminar](#archivos-a-eliminar)
7. [Orden de Ejecución](#orden-de-ejecución)
8. [Rollback Plan](#rollback-plan)
9. [Checklist de Validación](#checklist-de-validación)

---

## 📋 Resumen Ejecutivo

### Objetivo
Consolidar toda la infraestructura AWS en Terraform para:
- ✅ Control total mediante IaC (Infrastructure as Code)
- ✅ Versionamiento completo en Git
- ✅ Reproducibilidad entre entornos
- ✅ Mejor documentación
- ✅ Facilitar CI/CD

### Duración estimada
- **Total**: 10-12 horas de trabajo
- **Por fase**: 30 min - 2 horas
- **Recomendado**: 2-3 días laborables

### Riesgos
- 🟡 **MEDIO**: Downtime durante migración (mitigable con blue-green)
- 🟢 **BAJO**: Pérdida de datos (DynamoDB se importa, no se recrea)
- 🟡 **MEDIO**: Usuarios deben re-autenticarse (Cognito nuevo)

---

## 🔄 Estado Actual vs. Estado Objetivo

### **ACTUAL** (Serverless Framework)

```
serverless-api/
├── serverless.yml           # 385 líneas - Define TODO
│   ├── Cognito User Pool
│   ├── Cognito Client
│   ├── User Groups (3)
│   ├── DynamoDB Table
│   ├── Lambda Functions (15+)
│   ├── API Gateway HTTP
│   ├── SNS Topics (4)
│   └── Custom Resources
├── src/handlers/            # Código Lambda
└── package.json             # Dependencias
```

**Comando deploy**: `npx serverless deploy`

### **OBJETIVO** (Terraform)

```
terraform/
├── main.tf                  # VPC, EC2, S3 ✅
├── variables.tf             # Variables ✅
├── terraform.tfvars         # Valores ✅
├── providers.tf             # AWS config ✅
├── outputs.tf               # Outputs ✅
├── user-data.sh             # EC2 bootstrap ✅
├── cognito.tf               # 🆕 User Pool completo
├── dynamodb.tf              # 🆕 Tabla HospitalData
├── sns.tf                   # 🆕 4 topics
├── lambda.tf                # 🆕 15+ funciones
├── lambda-layers.tf         # 🆕 node_modules
├── api-gateway.tf           # 🆕 HTTP API + routes
├── iam.tf                   # 🆕 Roles y políticas
└── README.md                # Docs ✅
```

**Comando deploy**: `terraform apply`

---

## 📦 Inventario de Recursos

### Recursos en Serverless Framework (serverless.yml)

| Recurso | Tipo CloudFormation | Líneas | Migrar a |
|---------|---------------------|--------|----------|
| **Cognito User Pool** | `AWS::Cognito::UserPool` | 216-258 | `cognito.tf` |
| **Cognito Client** | `AWS::Cognito::UserPoolClient` | 261-279 | `cognito.tf` |
| **Admin Group** | `AWS::Cognito::UserPoolGroup` | 282-289 | `cognito.tf` |
| **Personal Group** | `AWS::Cognito::UserPoolGroup` | 291-298 | `cognito.tf` |
| **PersonalAdministrativo Group** | `AWS::Cognito::UserPoolGroup` | 300-307 | `cognito.tf` |
| **DynamoDB Table** | `AWS::DynamoDB::Table` | 183-214 | `dynamodb.tf` |
| **UserEventsTopic** | `AWS::SNS::Topic` | 315-319 | `sns.tf` |
| **AgendaEventsTopic** | `AWS::SNS::Topic` | 321-325 | `sns.tf` |
| **NotificationsTopic** | `AWS::SNS::Topic` | 327-331 | `sns.tf` |
| **BoxEventsTopic** | `AWS::SNS::Topic` | 333-337 | `sns.tf` |
| **Login Lambda** | Función | 43-49 | `lambda.tf` |
| **Refresh Lambda** | Función | 51-57 | `lambda.tf` |
| **Me Lambda** | Función | 59-66 | `lambda.tf` |
| **GetBoxes Lambda** | Función | 73-81 | `lambda.tf` |
| **GetAgendas Lambda** | Función | 84-92 | `lambda.tf` |
| **CreateAgenda Lambda** | Función | 95-103 | `lambda.tf` |
| **GetPasillos Lambda** | Función | 105-113 | `lambda.tf` |
| **ListClients Lambda** | Función | 116-124 | `lambda.tf` |
| **GetClientConfig Lambda** | Función | 127-135 | `lambda.tf` |
| **UpdateClientConfig Lambda** | Función | 138-146 | `lambda.tf` |
| **UserEventsHandler Lambda** | Función | 154-160 | `lambda.tf` |
| **AgendaEventsHandler Lambda** | Función | 163-169 | `lambda.tf` |
| **NotificationHandler Lambda** | Función | 172-178 | `lambda.tf` |
| **SetupTestUsers Lambda** | Función | 176-179 | `lambda.tf` |
| **HTTP API** | `AWS::ApiGatewayV2::Api` | - | `api-gateway.tf` |
| **JWT Authorizer** | `AWS::ApiGatewayV2::Authorizer` | 23-32 | `api-gateway.tf` |

**Total**: ~30 recursos a migrar

---

## 🎯 Fases de Implementación

### ✅ **FASE 1: Preparación y Variables** (COMPLETADA)
**Duración**: 30 min  
**Estado**: ✅ DONE

**Archivos creados:**
- ✅ `variables.tf` (50+ variables)
- ✅ `terraform.tfvars` (valores reales)
- ✅ `terraform.tfvars.example` (template)
- ✅ `.gitignore` (seguridad)
- ✅ `README.md` (documentación)
- ✅ `user-data.sh` (EC2 mejorado)

**Cambios en archivos existentes:**
- ✅ `main.tf` actualizado con variables
- ✅ `providers.tf` sin cambios
- ✅ `outputs.tf` sin cambios

**Validación:**
```bash
✅ terraform init -upgrade
✅ terraform fmt
✅ terraform validate
```

---

### 🔄 **FASE 2: Migrar Cognito** (SIGUIENTE)
**Duración**: 45 min  
**Prioridad**: ALTA  
**Dependencias**: Ninguna

**Archivo a crear**: `terraform/cognito.tf`

**Recursos a migrar:**
```hcl
# User Pool
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
}

# User Pool Client
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

# User Groups
resource "aws_cognito_user_pool_group" "admin" {
  name         = "Admin"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Administrators with full system access and management capabilities"
  precedence   = 1
}

resource "aws_cognito_user_pool_group" "personal" {
  name         = "Personal"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Medical and nursing staff with access to assigned corridor only"
  precedence   = 2
}

resource "aws_cognito_user_pool_group" "personal_administrativo" {
  name         = "PersonalAdministrativo"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Administrative staff with booking and reporting access to all corridors"
  precedence   = 3
}
```

**Outputs a agregar en `outputs.tf`:**
```hcl
output "cognito_user_pool_id" {
  description = "ID del Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_arn" {
  description = "ARN del Cognito User Pool"
  value       = aws_cognito_user_pool.main.arn
}

output "cognito_user_pool_endpoint" {
  description = "Endpoint del Cognito User Pool"
  value       = aws_cognito_user_pool.main.endpoint
}

output "cognito_client_id" {
  description = "ID del Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.main.id
  sensitive   = true
}
```

**Testing:**
```bash
terraform plan -target=aws_cognito_user_pool.main
terraform apply -target=aws_cognito_user_pool.main
```

---

### 🔄 **FASE 3: Migrar DynamoDB**
**Duración**: 30 min  
**Prioridad**: ALTA  
**Dependencias**: Ninguna

**Archivo a crear**: `terraform/dynamodb.tf`

**Recursos:**
```hcl
resource "aws_dynamodb_table" "main" {
  name           = var.dynamodb_table_name
  billing_mode   = var.dynamodb_billing_mode
  
  # Keys
  hash_key  = "PK"
  range_key = "SK"
  
  # Attributes
  attribute {
    name = "PK"
    type = "S"
  }
  
  attribute {
    name = "SK"
    type = "S"
  }
  
  attribute {
    name = "GSI1PK"
    type = "S"
  }
  
  attribute {
    name = "GSI1SK"
    type = "S"
  }
  
  # Global Secondary Index
  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }
  
  # Streams
  stream_enabled   = var.enable_dynamodb_streams
  stream_view_type = var.enable_dynamodb_streams ? "NEW_AND_OLD_IMAGES" : null
  
  # Point-in-time recovery
  point_in_time_recovery {
    enabled = var.enable_dynamodb_pitr
  }
  
  # TTL (opcional)
  ttl {
    enabled        = false
    attribute_name = ""
  }
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-dynamodb"
    }
  )
}
```

**⚠️ IMPORTANTE**: Si la tabla ya existe, usar `terraform import`:
```bash
terraform import aws_dynamodb_table.main HospitalData
```

**Outputs:**
```hcl
output "dynamodb_table_name" {
  value = aws_dynamodb_table.main.name
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.main.arn
}

output "dynamodb_stream_arn" {
  value = aws_dynamodb_table.main.stream_arn
}
```

---

### 🔄 **FASE 4: Migrar SNS Topics**
**Duración**: 20 min  
**Prioridad**: MEDIA  
**Dependencias**: Ninguna

**Archivo a crear**: `terraform/sns.tf`

```hcl
# User Events Topic
resource "aws_sns_topic" "user_events" {
  name         = "${var.environment}-${var.sns_topics_prefix}-user-events"
  display_name = "Hospital User Events"
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-user-events"
    }
  )
}

# Agenda Events Topic
resource "aws_sns_topic" "agenda_events" {
  name         = "${var.environment}-${var.sns_topics_prefix}-agenda-events"
  display_name = "Hospital Agenda Events"
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-agenda-events"
    }
  )
}

# Notifications Topic
resource "aws_sns_topic" "notifications" {
  name         = "${var.environment}-${var.sns_topics_prefix}-notifications"
  display_name = "Hospital System Notifications"
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-notifications"
    }
  )
}

# Box Events Topic
resource "aws_sns_topic" "box_events" {
  name         = "${var.environment}-${var.sns_topics_prefix}-box-events"
  display_name = "Hospital Box State Events"
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-box-events"
    }
  )
}
```

**Outputs:**
```hcl
output "sns_user_events_arn" {
  value = aws_sns_topic.user_events.arn
}

output "sns_agenda_events_arn" {
  value = aws_sns_topic.agenda_events.arn
}

output "sns_notifications_arn" {
  value = aws_sns_topic.notifications.arn
}

output "sns_box_events_arn" {
  value = aws_sns_topic.box_events.arn
}
```

---

### 🔄 **FASE 5: Migrar Lambda Functions** (MÁS COMPLEJA)
**Duración**: 2 horas  
**Prioridad**: ALTA  
**Dependencias**: Cognito, DynamoDB, SNS

**Archivos a crear**:
- `terraform/lambda.tf` (funciones)
- `terraform/lambda-layers.tf` (node_modules)
- `terraform/lambda-packaging.tf` (ZIP optimization)

**Estructura Lambda:**
```hcl
# Lambda Layer (node_modules compartido)
resource "aws_lambda_layer_version" "nodejs_deps" {
  filename   = "${path.module}/layers/nodejs.zip"
  layer_name = "${var.project_name}-${var.environment}-nodejs-deps"
  
  compatible_runtimes = [var.lambda_runtime]
  
  source_code_hash = filebase64sha256("${path.module}/layers/nodejs.zip")
}

# Lambda: Login
resource "aws_lambda_function" "login" {
  filename      = "${path.module}/lambda-packages/auth-login.zip"
  function_name = "${var.project_name}-${var.environment}-login"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "src/handlers/auth.login"
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory
  
  layers = [aws_lambda_layer_version.nodejs_deps.arn]
  
  environment {
    variables = {
      DYNAMODB_TABLE       = aws_dynamodb_table.main.name
      USER_POOL_ID         = aws_cognito_user_pool.main.id
      USER_POOL_CLIENT_ID  = aws_cognito_user_pool_client.main.id
      STAGE                = var.environment
    }
  }
  
  source_code_hash = filebase64sha256("${path.module}/lambda-packages/auth-login.zip")
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-login"
    }
  )
}

# Lambda: GetBoxes
resource "aws_lambda_function" "get_boxes" {
  filename      = "${path.module}/lambda-packages/boxes.zip"
  function_name = "${var.project_name}-${var.environment}-get-boxes"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "src/handlers/boxes.getBoxes"
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory
  
  layers = [aws_lambda_layer_version.nodejs_deps.arn]
  
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.main.name
      STAGE          = var.environment
    }
  }
  
  source_code_hash = filebase64sha256("${path.module}/lambda-packages/boxes.zip")
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-get-boxes"
    }
  )
}

# SNS Subscriptions
resource "aws_sns_topic_subscription" "user_events_lambda" {
  topic_arn = aws_sns_topic.user_events.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.user_events_handler.arn
}

resource "aws_lambda_permission" "user_events_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user_events_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.user_events.arn
}

# Repetir para todas las funciones...
```

**Script de packaging** (`terraform/package-lambdas.sh`):
```bash
#!/bin/bash
# Package individual Lambda functions (sin node_modules)

HANDLERS_DIR="../serverless-api/src/handlers"
OUTPUT_DIR="./lambda-packages"

mkdir -p $OUTPUT_DIR

# Auth functions
zip -j $OUTPUT_DIR/auth-login.zip $HANDLERS_DIR/auth.js
zip -j $OUTPUT_DIR/auth-refresh.zip $HANDLERS_DIR/auth.js
zip -j $OUTPUT_DIR/auth-me.zip $HANDLERS_DIR/auth.js

# Boxes
zip -r $OUTPUT_DIR/boxes.zip $HANDLERS_DIR/boxes.js

# Agendas
zip -r $OUTPUT_DIR/agendas.zip $HANDLERS_DIR/agendas.js

# Pasillos
zip -r $OUTPUT_DIR/pasillos.zip $HANDLERS_DIR/pasillos.js

# Event handlers
zip -r $OUTPUT_DIR/user-events-handler.zip $HANDLERS_DIR/user-events-handler.js
zip -r $OUTPUT_DIR/agenda-events-handler.zip $HANDLERS_DIR/agenda-events-handler.js
zip -r $OUTPUT_DIR/notification-handler.zip $HANDLERS_DIR/notification-handler.js

echo "✅ Lambda packages created in $OUTPUT_DIR"
```

**Total funciones**: 15+

---

### 🔄 **FASE 6: Migrar API Gateway**
**Duración**: 1 hora  
**Prioridad**: ALTA  
**Dependencias**: Lambda, Cognito

**Archivo a crear**: `terraform/api-gateway.tf`

```hcl
# HTTP API
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.api_gateway_name}-${var.environment}"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins     = ["*"]  # Configurar en producción
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers     = ["*"]
    max_age           = 300
  }
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-api"
    }
  )
}

# JWT Authorizer (Cognito)
resource "aws_apigatewayv2_authorizer" "cognito_jwt" {
  api_id           = aws_apigatewayv2_api.main.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-jwt-authorizer"
  
  jwt_configuration {
    audience = [aws_cognito_user_pool_client.main.id]
    issuer   = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
  }
}

# Stage
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
  
  default_route_settings {
    throttling_burst_limit = var.api_throttle_burst_limit
    throttling_rate_limit  = var.api_throttle_rate_limit
  }
  
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format         = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = 7
}

# Routes
# POST /auth/login
resource "aws_apigatewayv2_route" "login" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /auth/login"
  target    = "integrations/${aws_apigatewayv2_integration.login.id}"
}

resource "aws_apigatewayv2_integration" "login" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.login.invoke_arn
}

resource "aws_lambda_permission" "login_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.login.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# GET /api/boxes (con autorización)
resource "aws_apigatewayv2_route" "get_boxes" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /api/boxes"
  target    = "integrations/${aws_apigatewayv2_integration.get_boxes.id}"
  
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_jwt.id
}

resource "aws_apigatewayv2_integration" "get_boxes" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.get_boxes.invoke_arn
}

resource "aws_lambda_permission" "get_boxes_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_boxes.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# Repetir para todas las rutas (~15 endpoints)
```

**Outputs:**
```hcl
output "api_gateway_url" {
  description = "URL del API Gateway"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "api_gateway_id" {
  value = aws_apigatewayv2_api.main.id
}
```

---

### 🔄 **FASE 7: IAM Roles Granulares**
**Duración**: 1 hora  
**Prioridad**: MEDIA  
**Dependencias**: Todas las anteriores

**Archivo a crear**: `terraform/iam.tf`

```hcl
# Lambda Execution Role (granular)
resource "aws_iam_role" "lambda_execution" {
  name = "${var.project_name}-${var.environment}-lambda-execution"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Policy: CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy: DynamoDB Access
resource "aws_iam_policy" "dynamodb_access" {
  name = "${var.project_name}-${var.environment}-dynamodb-access"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.main.arn,
          "${aws_dynamodb_table.main.arn}/index/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

# Policy: SNS Publish
resource "aws_iam_policy" "sns_publish" {
  name = "${var.project_name}-${var.environment}-sns-publish"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["sns:Publish"]
      Resource = [
        aws_sns_topic.user_events.arn,
        aws_sns_topic.agenda_events.arn,
        aws_sns_topic.notifications.arn,
        aws_sns_topic.box_events.arn
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sns" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.sns_publish.arn
}

# Policy: Cognito Access
resource "aws_iam_policy" "cognito_access" {
  name = "${var.project_name}-${var.environment}-cognito-access"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "cognito-idp:AdminInitiateAuth",
        "cognito-idp:AdminCreateUser",
        "cognito-idp:AdminSetUserPassword",
        "cognito-idp:AdminAddUserToGroup",
        "cognito-idp:AdminGetUser",
        "cognito-idp:ListUsers"
      ]
      Resource = aws_cognito_user_pool.main.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_cognito" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.cognito_access.arn
}
```

**⚠️ Nota**: Si usas AWS Academy, puedes seguir usando LabRole o crear roles propios.

---

### 🔄 **FASE 8: Outputs Completos**
**Duración**: 15 min  
**Prioridad**: BAJA

**Actualizar `outputs.tf`** con todos los outputs necesarios.

---

### 🔄 **FASE 9: Testing y Validación**
**Duración**: 1 hora  
**Prioridad**: CRÍTICA

**Checklist**:
- [ ] `terraform plan` sin errores
- [ ] Deploy exitoso
- [ ] Usuarios de prueba creados en Cognito
- [ ] Login funcional
- [ ] APIs funcionando
- [ ] Chaos experiments pasan
- [ ] Django conectado a nueva API

---

## 📁 Archivos a Crear

### Archivos Terraform Nuevos

| Archivo | Descripción | Líneas est. | Prioridad |
|---------|-------------|-------------|-----------|
| ✅ `variables.tf` | Variables completas | 300+ | CRÍTICA |
| ✅ `terraform.tfvars` | Valores reales | 50+ | CRÍTICA |
| ✅ `terraform.tfvars.example` | Template | 100+ | ALTA |
| ✅ `.gitignore` | Protección | 80+ | CRÍTICA |
| ✅ `README.md` | Documentación | 400+ | ALTA |
| ✅ `user-data.sh` | Bootstrap EC2 | 200+ | ALTA |
| 🔄 `cognito.tf` | User Pool | 150+ | CRÍTICA |
| 🔄 `dynamodb.tf` | Tabla | 80+ | CRÍTICA |
| 🔄 `sns.tf` | Topics | 60+ | MEDIA |
| 🔄 `lambda.tf` | Funciones | 800+ | CRÍTICA |
| 🔄 `lambda-layers.tf` | Layers | 50+ | ALTA |
| 🔄 `api-gateway.tf` | HTTP API | 400+ | CRÍTICA |
| 🔄 `iam.tf` | Roles | 200+ | ALTA |
| 🔄 `package-lambdas.sh` | Build script | 50+ | ALTA |
| 🔄 `MIGRATION_PLAN.md` | Este doc | 2000+ | MEDIA |

**Total**: ~15 archivos, ~5000 líneas de código

---

## 🗑️ Archivos a ELIMINAR después del Deploy

### ⚠️ CRÍTICO: Eliminar DESPUÉS de validar Terraform

**Orden de eliminación**:

1. **PRIMERO: Destruir stack CloudFormation de Serverless**
```bash
cd serverless-api
npx serverless remove
```

Esto eliminará:
- ✅ Cognito User Pool (se recrea en Terraform)
- ✅ DynamoDB Table (⚠️ BACKUP antes!)
- ✅ Lambda Functions
- ✅ API Gateway
- ✅ SNS Topics
- ✅ CloudFormation Stack completo

2. **SEGUNDO: Archivos a eliminar del repo**

```bash
# Eliminar Serverless Framework config
rm serverless-api/serverless.yml

# Eliminar scripts obsoletos
rm serverless-api/deploy.sh
rm setup-local-dev.sh
rm setup-local-dev.bat

# Eliminar validación SaaS (ya ejecutada)
rm validate_saas_migration.sh
rm validate_saas_migration.bat
rm PRUEBAS_MIGRACION_GUIA.md

# Eliminar docs de migración antigua
rm CHAOS_ENGINEERING_GUIA.md
rm CHAOS_ENGINEERING_RESUMEN.md

# Limpiar archivos temporales
rm -rf serverless-api/.serverless/
rm -rf serverless-api/node_modules/  # Reinstalar después
```

3. **TERCERO: Actualizar .gitignore del proyecto**

Agregar a `.gitignore` raíz:
```
# Serverless Framework (obsoleto)
.serverless/
serverless.yml

# Terraform
terraform/.terraform/
terraform/*.tfstate
terraform/*.tfstate.*
terraform/*.tfvars
terraform/lambda.zip
terraform/lambda-packages/
terraform/layers/
```

4. **CUARTO: Actualizar README.md del proyecto**

Cambiar sección de deployment:
```markdown
## 🚀 Deployment

### Con Terraform (ACTUAL)

1. Configurar credenciales AWS
2. Crear `terraform.tfvars` desde template
3. Deploy:
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

### ~~Con Serverless Framework (OBSOLETO)~~
~~Migrado a Terraform el 7 Nov 2025~~
```

---

## 🔄 Orden de Ejecución Recomendado

### Pre-Migración (Preparación)

```bash
# 1. Backup DynamoDB
aws dynamodb create-backup \
  --table-name HospitalData \
  --backup-name pre-terraform-migration-$(date +%Y%m%d)

# 2. Exportar configuración actual de Cognito
aws cognito-idp describe-user-pool \
  --user-pool-id <POOL_ID> > cognito-backup.json

# 3. Commit todo el código actual
git add .
git commit -m "Pre-migration backup"
git tag v1.0-serverless
git push origin milan --tags
```

### Migración (Ejecución)

```bash
# FASE 1: ✅ COMPLETADA
cd terraform
terraform init
terraform validate

# FASE 2: Cognito
terraform plan -target=aws_cognito_user_pool.main
terraform apply -target=aws_cognito_user_pool.main
terraform apply -target=aws_cognito_user_pool_client.main
terraform apply -target=aws_cognito_user_pool_group.admin
terraform apply -target=aws_cognito_user_pool_group.personal
terraform apply -target=aws_cognito_user_pool_group.personal_administrativo

# FASE 3: DynamoDB (importar si existe)
terraform import aws_dynamodb_table.main HospitalData
terraform plan -target=aws_dynamodb_table.main
terraform apply -target=aws_dynamodb_table.main

# FASE 4: SNS
terraform apply -target=aws_sns_topic.user_events
terraform apply -target=aws_sns_topic.agenda_events
terraform apply -target=aws_sns_topic.notifications
terraform apply -target=aws_sns_topic.box_events

# FASE 5: Lambda (packaging primero)
./package-lambdas.sh
terraform apply -target=aws_lambda_layer_version.nodejs_deps
terraform apply -target=aws_lambda_function.login
# ... repetir para todas las funciones

# FASE 6: API Gateway
terraform apply -target=aws_apigatewayv2_api.main
terraform apply -target=aws_apigatewayv2_authorizer.cognito_jwt
terraform apply -target=aws_apigatewayv2_stage.default
# ... routes

# FASE 7: IAM (opcional si usas LabRole)
terraform apply -target=aws_iam_role.lambda_execution
terraform apply -target=aws_iam_policy.dynamodb_access

# DEPLOY COMPLETO FINAL
terraform plan
terraform apply
```

### Post-Migración (Validación)

```bash
# 1. Obtener outputs
terraform output

# 2. Actualizar .env de Django con nueva API URL
API_URL=$(terraform output -raw api_gateway_url)
echo "SERVERLESS_API_BASE_URL=$API_URL" > ../ProyectoHospital/.env.local

# 3. Ejecutar chaos experiments
cd ../chaos-experiments
./setup.sh
./run-all-experiments.sh

# 4. Verificar usuarios de prueba
aws cognito-idp list-users \
  --user-pool-id $(terraform output -raw cognito_user_pool_id) \
  --limit 10

# 5. Test manual de APIs
curl -X POST $API_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin@hospital.com","password":"Admin123"}'
```

### Limpieza (Solo si todo funciona)

```bash
# 1. Destruir stack Serverless
cd ../serverless-api
npx serverless remove

# 2. Eliminar archivos obsoletos
cd ..
rm serverless-api/serverless.yml
rm PRUEBAS_MIGRACION_GUIA.md
# ... otros archivos

# 3. Commit cambios
git add .
git commit -m "Migración completa a Terraform - Eliminados archivos Serverless obsoletos"
git tag v2.0-terraform
git push origin milan --tags
```

---

## 🔙 Rollback Plan

### Si algo sale mal durante la migración:

#### Opción 1: Rollback completo a Serverless

```bash
# 1. Destruir infraestructura Terraform
cd terraform
terraform destroy

# 2. Re-deploy con Serverless
cd ../serverless-api
npx serverless deploy

# 3. Restaurar backup DynamoDB si es necesario
aws dynamodb restore-table-from-backup \
  --target-table-name HospitalData \
  --backup-arn <ARN_BACKUP>
```

#### Opción 2: Rollback parcial (mantener lo que funciona)

```bash
# Destruir solo recursos problemáticos
terraform destroy -target=aws_lambda_function.problematic_function

# Re-aplicar
terraform apply -target=aws_lambda_function.problematic_function
```

#### Opción 3: Blue-Green Deployment

1. Mantener Serverless corriendo
2. Desplegar Terraform en paralelo (diferente stage/environment)
3. Probar Terraform completamente
4. Cambiar DNS/configuración a Terraform
5. Destruir Serverless solo cuando todo esté validado

---

## ✅ Checklist de Validación

### Pre-Deploy

- [ ] Backup DynamoDB creado
- [ ] Backup Cognito exportado
- [ ] Código commiteado y tagged
- [ ] Variables terraform.tfvars configuradas
- [ ] `terraform validate` exitoso

### Post-Deploy Cognito

- [ ] User Pool creado
- [ ] Client creado con token validity correcto
- [ ] 3 grupos creados (Admin, Personal, PersonalAdministrativo)
- [ ] Login funcional

### Post-Deploy DynamoDB

- [ ] Tabla creada/importada
- [ ] Keys correctas (PK, SK)
- [ ] GSI1 creado
- [ ] Streams habilitados
- [ ] PITR habilitado
- [ ] Data preservada (si importada)

### Post-Deploy Lambda

- [ ] 15+ funciones creadas
- [ ] Layer con node_modules
- [ ] Variables de entorno correctas
- [ ] Permisos IAM correctos
- [ ] Subscripciones SNS funcionando

### Post-Deploy API Gateway

- [ ] HTTP API creada
- [ ] JWT Authorizer configurado
- [ ] Todas las routes creadas
- [ ] CORS configurado
- [ ] Logging habilitado
- [ ] Throttling configurado

### Post-Deploy EC2

- [ ] Instancia running
- [ ] Django accesible en puerto 8000
- [ ] Nginx proxy funcionando
- [ ] Health check OK
- [ ] Logs sin errores

### Testing Funcional

- [ ] Login con usuario de prueba
- [ ] GET /api/boxes funciona
- [ ] GET /api/agendas funciona
- [ ] POST /api/agendas funciona
- [ ] GET /api/pasillos funciona
- [ ] Eventos SNS se publican
- [ ] Handlers SNS se ejecutan

### Chaos Experiments

- [ ] Script 1: DOS attack (pasa)
- [ ] Script 2: Lambda latency (pasa)
- [ ] Script 3: SNS failure (pasa)
- [ ] Script 4: DynamoDB throttling (pasa)
- [ ] Script 5: Lambda errors (pasa)

### Cleanup

- [ ] Stack Serverless destruido
- [ ] Archivos obsoletos eliminados
- [ ] .gitignore actualizado
- [ ] README actualizado
- [ ] Código commiteado
- [ ] Tag v2.0-terraform creado

---

## 📊 Resumen de Recursos

### ANTES (Serverless Framework)
- 1 archivo: `serverless.yml` (385 líneas)
- CloudFormation: ~30 recursos
- Deploy: `npx serverless deploy`
- Tiempo: 3-5 minutos

### DESPUÉS (Terraform)
- 15 archivos: *.tf (5000+ líneas)
- Terraform: ~30 recursos
- Deploy: `terraform apply`
- Tiempo: 5-8 minutos

### Ventajas Terraform
- ✅ Versionamiento granular
- ✅ Mejor modularidad
- ✅ Import de recursos existentes
- ✅ Plan antes de aplicar
- ✅ Estado compartible
- ✅ Reutilizable entre proyectos

### Desventajas
- ❌ Más verboso
- ❌ Curva de aprendizaje
- ❌ Packaging Lambda manual

---

## 📞 Soporte y Referencias

### Documentación
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- AWS Academy Docs: Ver Learner Lab
- Proyecto GitHub: https://github.com/m1lvn/ProyectoVisualizacionBoxes

### Comandos útiles
```bash
# Ver estado
terraform show

# Ver plan sin aplicar
terraform plan -out=tfplan

# Aplicar plan guardado
terraform apply tfplan

# Destruir recurso específico
terraform destroy -target=RESOURCE

# Importar recurso existente
terraform import RESOURCE ID

# Ver outputs
terraform output

# Formatear código
terraform fmt -recursive

# Validar sintaxis
terraform validate

# Refrescar estado
terraform refresh
```

---

**Última actualización**: Noviembre 7, 2025  
**Versión**: 1.0  
**Estado**: FASE 1 Completada ✅  
**Próximo paso**: FASE 2 - Migrar Cognito 🔄
