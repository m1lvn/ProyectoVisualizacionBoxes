# 🧹 Guía de Limpieza Post-Migración a Terraform

**Fecha**: Noviembre 7, 2025  
**Migración**: Serverless Framework → Terraform  
**Estado**: ✅ Terraform aplicado exitosamente

---

## 📊 Recursos Creados con Terraform

### ✅ Infraestructura Desplegada:

**Cuenta AWS**: `446242970357`  
**Región**: `us-east-1`

**Recursos creados (93 total):**

#### 1. **Networking**
- VPC: `hospital-boxes-dev-vpc`
- Subnets: Public, Private, Custom
- Internet Gateway + NAT Gateway
- Security Groups para EC2

#### 2. **Compute**
- **EC2 Django Server**: `3.88.182.164`
  - Acceso: `http://3.88.182.164:8000`

#### 3. **Database**
- **DynamoDB**: `HospitalData`
  - GSI: `GSI1`
  - Streams: Habilitado
  - PITR: Habilitado

#### 4. **Authentication**
- **Cognito User Pool**: `us-east-1_9kV8gDkDE`
- **Client ID**: `46d0qi0hb666g6b79prq7gjc8m`
- **User Groups**: Admin, Personal, PersonalAdministrativo

#### 5. **Lambda Functions (15)**
```
hospital-boxes-dev-login
hospital-boxes-dev-refresh
hospital-boxes-dev-me
hospital-boxes-dev-get-boxes
hospital-boxes-dev-get-agendas
hospital-boxes-dev-create-agenda
hospital-boxes-dev-get-pasillos
hospital-boxes-dev-list-clients
hospital-boxes-dev-get-client-config
hospital-boxes-dev-update-client-config
hospital-boxes-dev-user-events-handler
hospital-boxes-dev-agenda-events-handler
hospital-boxes-dev-notification-handler
hospital-boxes-dev-setup-test-users
hospital-boxes-api (main API handler)
```

#### 6. **SNS Topics (4)**
```
hospital-user-events-dev
hospital-agenda-events-dev
hospital-notifications-dev
hospital-box-events-dev
```

#### 7. **API Gateway**
- HTTP API con múltiples rutas
- Integrado con todas las funciones Lambda

---

## 🗑️ Archivos a Eliminar

### ❌ Completamente Obsoletos (BORRAR)

#### A. Carpeta `.serverless/`
```powershell
Remove-Item serverless-api\.serverless -Recurse -Force
```
**Razón**: Artefactos de Serverless Framework, ya no se usa.

#### B. `deploy.sh`
```powershell
Remove-Item deploy.sh
```
**Razón**: Script antiguo que usa `serverless deploy`.

#### C. Scripts de validación antiguos (opcionales)
```powershell
Remove-Item validate_saas_migration.bat
Remove-Item PRUEBAS_MIGRACION_GUIA.md
```
**Razón**: Documentación de migración que ya se completó.

### ⚠️ Archivos a MANTENER pero ACTUALIZAR

#### A. `serverless-api/serverless.yml`
**Acción**: ⚠️ **NO BORRAR** pero marcar como obsoleto

**Razón**: Terraform lee de esta estructura, pero ya NO se usa para deployment.

**Opción 1** - Renombrar:
```powershell
Rename-Item serverless-api\serverless.yml serverless-api\serverless.yml.OLD
```

**Opción 2** - Agregar comentario al inicio:
```yaml
# ⚠️ ESTE ARCHIVO YA NO SE USA PARA DEPLOYMENT
# Terraform ahora gestiona toda la infraestructura
# Ver: terraform/*.tf
# Solo se mantiene como referencia histórica
```

#### B. `serverless-api/.env`
**Acción**: ✅ **MANTENER** y actualizar

**Razón**: Django y algunos scripts aún lo usan.

**Actualizar con nuevos valores**:
```env
# Actualizar desde terraform outputs
COGNITO_USER_POOL_ID=us-east-1_9kV8gDkDE
COGNITO_CLIENT_ID=46d0qi0hb666g6b79prq7gjc8m
DYNAMODB_TABLE=HospitalData
AWS_ACCOUNT_ID=446242970357
```

#### C. `README.md`
**Acción**: ✅ **ACTUALIZAR** deployment instructions

Cambiar sección de deployment de:
```bash
cd serverless-api
npm install
serverless deploy
```

A:
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

---

## 🔧 Archivos a Crear/Actualizar

### 1. Nuevo script de deployment: `terraform/deploy-terraform.sh`

```bash
#!/bin/bash
# Script de despliegue usando Terraform

echo "🚀 Iniciando despliegue con Terraform..."

# Verificar credenciales AWS
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ Error: Credenciales AWS no configuradas"
    echo "Actualiza ~/.aws/credentials desde AWS Learner Lab"
    exit 1
fi

cd terraform

echo "🔍 Validando configuración..."
terraform validate
if [ $? -ne 0 ]; then
    echo "❌ Error de validación en archivos Terraform"
    exit 1
fi

echo "📋 Generando plan de ejecución..."
terraform plan

read -p "¿Aplicar cambios? (yes/no): " confirm
if [ "$confirm" = "yes" ]; then
    echo "🏗️  Aplicando infraestructura..."
    terraform apply -auto-approve
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Despliegue completado exitosamente"
        echo ""
        echo "📊 Recursos creados:"
        terraform output
    else
        echo "❌ Error durante el despliegue"
        exit 1
    fi
else
    echo "❌ Despliegue cancelado"
    exit 0
fi
```

### 2. Actualizar `.gitignore`

Agregar entradas para Terraform:
```gitignore
# Terraform (ya existe en terraform/.gitignore pero por seguridad)
terraform/.terraform/
terraform/*.tfstate
terraform/*.tfstate.backup
terraform/terraform.tfvars
terraform/.terraform.lock.hcl
terraform/lambda.zip

# Serverless (obsoleto pero mantener por si acaso)
.serverless/
serverless-api/.serverless/
```

---

## 📝 Actualizar Configuraciones

### 1. Django (`ProyectoHospital/settings.py`)

Actualizar variables de entorno para usar outputs de Terraform:

```python
# Cognito Configuration (desde terraform output)
COGNITO_USER_POOL_ID = os.getenv('COGNITO_USER_POOL_ID', 'us-east-1_9kV8gDkDE')
COGNITO_CLIENT_ID = os.getenv('COGNITO_CLIENT_ID', '46d0qi0hb666g6b79prq7gjc8m')
COGNITO_REGION = os.getenv('AWS_DEFAULT_REGION', 'us-east-1')

# DynamoDB Configuration
DYNAMODB_TABLE = os.getenv('DYNAMODB_TABLE', 'HospitalData')

# API Gateway URL (actualizar después de terraform output)
API_GATEWAY_URL = os.getenv('API_GATEWAY_URL', 'https://[API-ID].execute-api.us-east-1.amazonaws.com')
```

### 2. Chaos Experiments (`.env`)

Actualizar `chaos-experiments/.env`:
```bash
# AWS Configuration (desde terraform outputs)
AWS_ACCOUNT_ID=446242970357
AWS_DEFAULT_REGION=us-east-1

# API Configuration
API_URL=https://[API-GATEWAY-ID].execute-api.us-east-1.amazonaws.com

# Cognito
COGNITO_USER_POOL_ID=us-east-1_9kV8gDkDE
COGNITO_CLIENT_ID=46d0qi0hb666g6b79prq7gjc8m

# DynamoDB
DYNAMODB_TABLE_NAME=HospitalData
```

---

## 🎯 Próximos Pasos

### Paso 1: Verificar Deployment ✅ (COMPLETADO)

```powershell
terraform output
```

### Paso 2: Obtener API Gateway URL

```powershell
aws apigatewayv2 get-apis --query 'Items[?Name==`hospital-boxes-api`].ApiEndpoint' --output text
```

### Paso 3: Probar Endpoints

```powershell
# Login
$API_URL = "https://[API-ID].execute-api.us-east-1.amazonaws.com"
Invoke-RestMethod -Uri "$API_URL/auth/login" -Method POST -Body (@{username="test"; password="test123"} | ConvertTo-Json) -ContentType "application/json"

# Get Boxes
Invoke-RestMethod -Uri "$API_URL/api/boxes" -Method GET -Headers @{Authorization="Bearer [TOKEN]"}
```

### Paso 4: Actualizar Django con nueva configuración

```powershell
cd ProyectoHospital
# Actualizar .env o settings.py con nuevos valores
python manage.py runserver
```

### Paso 5: Ejecutar Chaos Tests

```powershell
cd chaos-experiments
.\setup-env.bat  # Actualizar con nuevas credenciales
.\run-all-experiments.sh
```

### Paso 6: Limpiar archivos obsoletos

```powershell
# Desde raíz del proyecto
Remove-Item serverless-api\.serverless -Recurse -Force
Remove-Item deploy.sh
Rename-Item serverless-api\serverless.yml serverless-api\serverless.yml.OLD
```

---

## 📋 Checklist de Migración

- [x] Terraform configurado sin hardcodeo de `aws_account_id`
- [x] Terraform aplicado exitosamente (93 recursos)
- [x] DynamoDB creado (`HospitalData`)
- [x] Cognito User Pool creado
- [x] Lambda functions desplegadas (15)
- [x] SNS topics creados (4)
- [x] API Gateway configurado
- [ ] Obtener API Gateway URL
- [ ] Actualizar Django settings
- [ ] Actualizar chaos-experiments/.env
- [ ] Probar endpoints
- [ ] Eliminar archivos obsoletos
- [ ] Actualizar README.md
- [ ] Commit cambios a git

---

## 🔄 Rollback (si es necesario)

Si necesitas volver atrás:

```powershell
# Destruir infraestructura Terraform
cd terraform
terraform destroy

# Restaurar despliegue con Serverless (no recomendado)
cd ..\serverless-api
serverless deploy
```

**⚠️ IMPORTANTE**: El backup del state antiguo está en:
```
terraform/terraform.tfstate.OLD-BACKUP-[timestamp]
```

---

## 📚 Documentación Relacionada

- `terraform/GUIA_USO.md` - Guía completa de uso de Terraform
- `terraform/README_TERRAFORM.md` - Workflow y comandos
- `terraform/MIGRATION_PLAN.md` - Plan de migración completo
- `chaos-experiments/results/CHAOS_ANALYSIS_REPORT.md` - Análisis de resiliencia

---

**Generado**: Noviembre 7, 2025  
**Estado**: Post-deployment exitoso  
**Próximo paso**: Obtener API Gateway URL y actualizar configuraciones
