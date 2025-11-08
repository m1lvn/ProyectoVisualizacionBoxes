# 🚀 Guía de Uso de Terraform - Hospital Boxes

## ✅ Correcciones Implementadas

### Eliminación de Hardcodeo de `aws_account_id`

**Antes (❌ Incorrecto):**
```hcl
# terraform.tfvars
aws_account_id = "891377117593"  # Hardcodeado - cambia en AWS Learner Lab
```

**Ahora (✅ Correcto):**
```hcl
# providers.tf
data "aws_caller_identity" "current" {}

# iam.tf
"arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table_name}"
```

**Beneficios:**
- ✅ Funciona con cualquier cuenta AWS
- ✅ Compatible con AWS Learner Lab (credenciales temporales)
- ✅ No requiere actualización manual del `account_id`
- ✅ Lee automáticamente de `~/.aws/credentials`

---

## 📋 Prerequisitos

### 1. Credenciales AWS Configuradas

**AWS Learner Lab:**
```powershell
# 1. Iniciar sesión en AWS Learner Lab
# 2. Click en "AWS Details"
# 3. Click en "Show" en "AWS CLI"
# 4. Copiar las credenciales

# 5. Abrir el archivo de credenciales:
notepad $env:USERPROFILE\.aws\credentials

# 6. Pegar (reemplazar todo):
[default]
aws_access_key_id=ASIAWPZRHLL2...
aws_secret_access_key=9HsekPPi...
aws_session_token=IQoJb3JpZ2luX...
```

**Verificar credenciales:**
```powershell
aws sts get-caller-identity
```

Deberías ver:
```json
{
    "UserId": "AROAWPZRHLL2...",
    "Account": "446242970357",
    "Arn": "arn:aws:sts::446242970357:assumed-role/voclabs/user..."
}
```

### 2. Terraform Instalado

```powershell
terraform --version
# Terraform v1.13.4 o superior
```

---

## 🎯 Workflow de Terraform

### Paso 1: Inicializar Terraform (Solo primera vez)

```powershell
cd terraform
terraform init
```

**Output esperado:**
```
Initializing provider plugins...
- Finding hashicorp/aws versions...
- Installing hashicorp/aws v6.x.x...
✓ Terraform has been successfully initialized!
```

### Paso 2: Validar Configuración

```powershell
terraform validate
```

**Output esperado:**
```
Success! The configuration is valid.
```

### Paso 3: Formatear Código

```powershell
terraform fmt -recursive
```

### Paso 4: Ver Plan de Ejecución

```powershell
# Ver qué recursos se crearán/modificarán/eliminarán
terraform plan

# Guardar el plan en un archivo
terraform plan -out=tfplan.out
```

**Revisar cuidadosamente:**
- ✅ `+ create` - Recursos nuevos (OK)
- ⚠️ `~ update` - Cambios en recursos existentes (Revisar)
- 🔴 `-/+ destroy and recreate` - Reemplazos (¡CUIDADO!)

### Paso 5: Aplicar Cambios

**Opción 1: Aplicar todo (después de revisar plan)**
```powershell
terraform apply tfplan.out
```

**Opción 2: Aplicar con confirmación interactiva**
```powershell
terraform apply
# Terraform te pedirá confirmación, escribe: yes
```

**Opción 3: Aplicar recursos específicos (más seguro)**
```powershell
# Solo crear DynamoDB
terraform apply -target=aws_dynamodb_table.main

# Solo crear Cognito
terraform apply -target=aws_cognito_user_pool.main -target=aws_cognito_user_pool_client.main

# Solo crear SNS topics
terraform apply -target=aws_sns_topic.user_events -target=aws_sns_topic.agenda_events
```

### Paso 6: Ver Outputs

```powershell
# Ver todos los outputs
terraform output

# Ver un output específico
terraform output django_server_public_ip
terraform output cognito_user_pool_id
terraform output aws_account_id
```

**Output ejemplo:**
```
aws_account_id         = "446242970357"
aws_caller_arn         = "arn:aws:sts::446242970357:assumed-role/voclabs/user..."
cognito_user_pool_id   = "us-east-1_AbCdEfGhI"
django_server_public_ip = "54.243.19.152"
dynamodb_table_name    = "HospitalData"
```

---

## 🔄 Casos de Uso Comunes

### Escenario 1: Primera Implementación (desde cero)

```powershell
# 1. Configurar credenciales AWS (ver arriba)

# 2. Editar terraform.tfvars (ya no necesitas aws_account_id)
notepad terraform.tfvars

# 3. Inicializar
terraform init

# 4. Ver plan
terraform plan

# 5. Aplicar de forma incremental (más seguro)
terraform apply -target=aws_dynamodb_table.main
terraform apply -target=aws_cognito_user_pool.main
terraform apply -target=aws_sns_topic.user_events
terraform apply -target=aws_lambda_function.login

# 6. O aplicar todo de una vez (si el plan se ve bien)
terraform apply
```

### Escenario 2: Actualizar Recursos Existentes

```powershell
# 1. Hacer cambios en archivos .tf

# 2. Ver qué cambiaría
terraform plan

# 3. Si solo hay updates (~), aplicar
terraform apply

# 4. Si hay replacements (-/+), considerar importar primero
```

### Escenario 3: Importar Recursos Existentes

Si Terraform quiere reemplazar recursos que ya existen en AWS:

```powershell
# Ejemplo: Importar tabla DynamoDB existente
terraform import aws_dynamodb_table.main HospitalData

# Ejemplo: Importar User Pool de Cognito
terraform import aws_cognito_user_pool.main us-east-1_AbCdEfGhI

# Ejemplo: Importar SNS topic
terraform import aws_sns_topic.user_events arn:aws:sns:us-east-1:446242970357:hospital-user-events-dev
```

### Escenario 4: Destruir Todo (Cleanup)

```powershell
# Ver qué se destruiría
terraform plan -destroy

# Destruir recursos específicos
terraform destroy -target=aws_lambda_function.login

# Destruir TODO (⚠️ CUIDADO)
terraform destroy
# Escribe: yes
```

---

## 🛠️ Troubleshooting

### Error: "Invalid credentials"

```powershell
# Verificar credenciales
aws sts get-caller-identity

# Si falla, actualizar credenciales desde AWS Learner Lab
notepad $env:USERPROFILE\.aws\credentials
```

### Error: "Resource already exists"

```powershell
# Opción 1: Importar el recurso existente
terraform import aws_dynamodb_table.main HospitalData

# Opción 2: Eliminar el recurso manualmente en AWS Console
# Opción 3: Renombrar en terraform.tfvars
```

### Error: "Timeout" o "Operation too slow"

```powershell
# Aumentar timeout de AWS provider
# En providers.tf agregar:
provider "aws" {
  region = var.region
  
  default_tags {
    tags = var.common_tags
  }
  
  http_timeout = 60  # segundos
}
```

### Warning: "Deprecated attribute"

```powershell
# Ejecutar para formatear y actualizar sintaxis
terraform fmt -recursive
```

---

## 📊 Verificación Post-Deploy

### 1. Verificar en AWS Console

**DynamoDB:**
- Console → DynamoDB → Tables
- Verificar que existe `HospitalData`
- Verificar GSI `GSI1`
- Verificar Streams habilitado

**Cognito:**
- Console → Cognito → User Pools
- Verificar `hospital-users-dev`
- Verificar Client `hospital-web-client`

**Lambda:**
- Console → Lambda → Functions
- Verificar funciones: login, getBoxes, getAgendas, etc.

**SNS:**
- Console → SNS → Topics
- Verificar topics: user-events, agenda-events, notifications, box-events

### 2. Verificar con Terraform

```powershell
# Ver estado actual
terraform show

# Ver recursos específicos
terraform state list
terraform state show aws_dynamodb_table.main
terraform state show aws_cognito_user_pool.main
```

### 3. Verificar con AWS CLI

```powershell
# DynamoDB
aws dynamodb describe-table --table-name HospitalData

# Cognito
aws cognito-idp list-user-pools --max-results 10

# Lambda
aws lambda list-functions --query 'Functions[?contains(FunctionName, `hospital`)].FunctionName'

# SNS
aws sns list-topics --query 'Topics[?contains(TopicArn, `hospital`)].TopicArn'
```

---

## 🔐 Seguridad y Buenas Prácticas

### ✅ DO (Hacer)

- ✅ Usar `data.aws_caller_identity.current.account_id` en lugar de hardcodear
- ✅ Mantener `terraform.tfvars` en `.gitignore`
- ✅ Usar `terraform plan` SIEMPRE antes de `apply`
- ✅ Revisar outputs con `terraform output`
- ✅ Hacer commits frecuentes de archivos `.tf`
- ✅ Usar `terraform fmt` antes de cada commit

### ❌ DON'T (No hacer)

- ❌ NO hardcodear `aws_account_id` en variables
- ❌ NO commitear `terraform.tfvars` (tiene valores reales)
- ❌ NO commitear `terraform.tfstate` (tiene secretos)
- ❌ NO hacer `terraform apply` sin revisar el plan
- ❌ NO destruir recursos sin backup
- ❌ NO compartir credenciales de AWS

---

## 📚 Recursos Adicionales

**Documentación Oficial:**
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [DynamoDB Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table)
- [Cognito User Pool](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool)

**Archivos en este proyecto:**
- `README.md` - Overview del proyecto Terraform
- `README_TERRAFORM.md` - Workflow y comandos de importación
- `MIGRATION_PLAN.md` - Plan completo de migración desde Serverless

---

## 🎓 Comparación: Antes vs Ahora

### Antes (Serverless Framework)

```bash
# serverless-api/.env
AWS_ACCOUNT_ID=891377117593  # Hardcodeado

# Despliegue
cd serverless-api
sls deploy
```

**Problemas:**
- Hardcodeo de account ID
- No versionado de infraestructura
- Difícil rollback
- No hay plan previo

### Ahora (Terraform)

```powershell
# terraform/providers.tf
data "aws_caller_identity" "current" {}  # Automático

# Despliegue
cd terraform
terraform plan   # Ver cambios
terraform apply  # Aplicar
```

**Beneficios:**
- ✅ Account ID automático
- ✅ Infraestructura como código versionada
- ✅ Rollback fácil con `terraform destroy`
- ✅ Plan detallado antes de aplicar
- ✅ State tracking de recursos

---

## 🚦 Próximos Pasos

1. **Ejecutar primer plan:**
   ```powershell
   terraform plan
   ```

2. **Revisar qué se creará** (lista de recursos)

3. **Aplicar de forma incremental:**
   ```powershell
   terraform apply -target=aws_dynamodb_table.main
   terraform apply -target=aws_cognito_user_pool.main
   # ... etc
   ```

4. **Verificar outputs:**
   ```powershell
   terraform output
   ```

5. **Probar endpoints** del API Gateway

6. **Documentar** en README.md los pasos que funcionaron

---

**Generado**: Noviembre 7, 2025  
**Última actualización**: Eliminación de hardcodeo de `aws_account_id`  
**Autor**: Equipo DevOps Hospital Boxes
