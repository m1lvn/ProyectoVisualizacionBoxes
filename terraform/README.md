# 🏗️ Terraform Infrastructure - Hospital Boxes Project

Infrastructure as Code (IaC) para el proyecto de Visualización de Boxes del Hospital.

## 📋 Tabla de Contenidos

- [Descripción](#descripción)
- [Arquitectura](#arquitectura)
- [Prerequisitos](#prerequisitos)
- [Configuración Inicial](#configuración-inicial)
- [Deployment](#deployment)
- [Recursos Creados](#recursos-creados)
- [Variables](#variables)
- [Outputs](#outputs)
- [Troubleshooting](#troubleshooting)

## 🎯 Descripción

Este proyecto usa Terraform para desplegar toda la infraestructura AWS del sistema de Visualización de Boxes:

- **VPC completa** con subnets públicas/privadas
- **EC2** para Django frontend
- **Lambda Functions** para backend serverless
- **API Gateway HTTP** con autenticación Cognito
- **DynamoDB** para persistencia
- **Cognito User Pool** para autenticación
- **SNS Topics** para eventos asíncronos

## 🏛️ Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                          Internet                           │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │     Internet Gateway        │
        └──────────────┬──────────────┘
                       │
┌──────────────────────┴──────────────────────────────────────┐
│                      VPC (10.0.0.0/16)                      │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │   Public Subnet (10.0.1.0/24)                      │    │
│  │                                                     │    │
│  │   ┌─────────────────────┐                          │    │
│  │   │  EC2 - Django       │                          │    │
│  │   │  Ubuntu 22.04       │                          │    │
│  │   │  Port: 8000         │                          │    │
│  │   │  Role: LabRole      │                          │    │
│  │   └─────────────────────┘                          │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │   Private Subnet (10.0.2.0/24)                     │    │
│  │                                                     │    │
│  │   ┌──────────────────┐                             │    │
│  │   │  VPC Endpoint    │                             │    │
│  │   │  → DynamoDB      │                             │    │
│  │   └──────────────────┘                             │    │
│  └────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                    AWS Managed Services                      │
├──────────────────────────────────────────────────────────────┤
│  Lambda Functions (15+)  │  API Gateway HTTP                 │
│  Cognito User Pool       │  DynamoDB Table                   │
│  SNS Topics (4)          │  S3 (Lambda code)                 │
└──────────────────────────────────────────────────────────────┘
```

## ✅ Prerequisitos

### Software necesario:

1. **Terraform** >= 1.0
   ```bash
   # Verificar instalación
   terraform version
   ```

2. **AWS CLI** configurado
   ```bash
   aws configure list
   ```

3. **Credenciales AWS Academy**
   - Ir a AWS Academy → Learner Lab → AWS Details
   - Copiar credenciales a `~/.aws/credentials`

### Conocimientos:

- Básico de Terraform
- Básico de AWS (VPC, EC2, Lambda, etc.)
- Git para control de versiones

## 🚀 Configuración Inicial

### 1. Clonar repositorio

```bash
git clone https://github.com/m1lvn/ProyectoVisualizacionBoxes.git
cd ProyectoVisualizacionBoxes/terraform
```

### 2. Crear archivo de variables

```bash
# Copiar template
cp terraform.tfvars.example terraform.tfvars

# Editar con tus valores
nano terraform.tfvars
```

**Valores importantes a configurar:**

- `aws_account_id`: Tu ID de cuenta AWS
- `github_repo_url`: URL de tu fork del repo
- `environment`: dev, staging o prod

### 3. Inicializar Terraform

```bash
terraform init
```

Este comando:
- Descarga providers (AWS, TLS, etc.)
- Configura el backend
- Prepara el workspace

### 4. Validar configuración

```bash
terraform validate
```

### 5. Ver plan de ejecución

```bash
terraform plan
```

Revisa cuidadosamente qué recursos se crearán.

## 🎬 Deployment

### Deploy completo

```bash
# Ver plan detallado
terraform plan -out=tfplan

# Aplicar cambios
terraform apply tfplan
```

### Deploy por módulos (recomendado para desarrollo)

```bash
# Solo networking
terraform apply -target=aws_vpc.main

# Solo EC2
terraform apply -target=aws_instance.django_server

# Solo Cognito
terraform apply -target=aws_cognito_user_pool.main
```

### Actualizar infraestructura

```bash
# Ver cambios
terraform plan

# Aplicar
terraform apply
```

### Destruir infraestructura

```bash
# Ver qué se destruirá
terraform plan -destroy

# Destruir TODO (⚠️ CUIDADO)
terraform destroy
```

## 📦 Recursos Creados

### Networking (main.tf)
- ✅ VPC con CIDR 10.0.0.0/16
- ✅ Internet Gateway
- ✅ Public Subnet (10.0.1.0/24)
- ✅ Private Subnet (10.0.2.0/24)
- ✅ Route Tables (public/private)
- ✅ VPC Endpoint para DynamoDB

### Compute (main.tf)
- ✅ EC2 Instance (Django)
- ✅ Security Group (SSH, HTTP, 8000)
- ✅ SSH Key Pair (auto-generado)
- ✅ IAM Instance Profile (LabRole)

### Serverless (Próximamente)
- 🔄 15+ Lambda Functions
- 🔄 API Gateway HTTP
- 🔄 Lambda Layers (node_modules)
- 🔄 S3 Bucket (código Lambda)

### Authentication (Próximamente)
- 🔄 Cognito User Pool
- 🔄 Cognito Client
- 🔄 User Groups (Admin, Personal, PersonalAdministrativo)

### Database (Próximamente)
- 🔄 DynamoDB Table (HospitalData)
- 🔄 GSI1 Index
- 🔄 Streams habilitados

### Messaging (Próximamente)
- 🔄 SNS Topic: user-events
- 🔄 SNS Topic: agenda-events
- 🔄 SNS Topic: notifications
- 🔄 SNS Topic: box-events

## 🔧 Variables

Ver archivo `variables.tf` para lista completa.

### Variables principales:

| Variable | Descripción | Default |
|----------|-------------|---------|
| `region` | Región AWS | us-east-1 |
| `project_name` | Nombre del proyecto | hospital-boxes |
| `environment` | Entorno | dev |
| `django_instance_type` | Tipo EC2 | t2.micro |
| `lambda_runtime` | Runtime Lambda | nodejs18.x |
| `dynamodb_table_name` | Nombre tabla | HospitalData |
| `access_token_validity` | Validez token (min) | 60 |

## 📤 Outputs

Después del deploy, Terraform mostrará:

```bash
Outputs:

django_server_public_ip = "54.243.19.152"
api_gateway_url         = "https://xxxxx.execute-api.us-east-1.amazonaws.com"
cognito_user_pool_id    = "us-east-1_xxxxxx"
cognito_client_id       = "xxxxxxxxxxxx"
dynamodb_table_name     = "HospitalData"
```

### Obtener outputs después:

```bash
# Todos los outputs
terraform output

# Output específico
terraform output django_server_public_ip
```

## 🔍 Troubleshooting

### Error: "No credentials found"

```bash
# Configurar credenciales AWS
aws configure

# O copiar desde AWS Academy
cat ~/.aws/credentials
```

### Error: "VPC already exists"

```bash
# Importar VPC existente
terraform import aws_vpc.main vpc-xxxxxx

# O destruir y recrear
terraform destroy
terraform apply
```

### Error: "Lambda package too large"

```bash
# Limpiar node_modules
cd ../serverless-api
rm -rf node_modules
npm install --production

# Recrear ZIP
terraform apply
```

### Ver estado actual:

```bash
# Listar recursos
terraform state list

# Ver recurso específico
terraform state show aws_instance.django_server
```

### Refresh state:

```bash
terraform refresh
```

## 📚 Próximos Pasos

- [x] **FASE 1**: Variables y configuración base ✅
- [ ] **FASE 2**: Migrar Cognito
- [ ] **FASE 3**: Migrar DynamoDB
- [ ] **FASE 4**: Migrar SNS Topics
- [ ] **FASE 5**: Migrar Lambda Functions
- [ ] **FASE 6**: Migrar API Gateway
- [ ] **FASE 7**: Mejorar EC2 Django
- [ ] **FASE 8**: IAM Roles granulares
- [ ] **FASE 9**: Outputs completos
- [ ] **FASE 10**: Testing y validación

## 🤝 Contribución

1. Crear rama feature
2. Hacer cambios
3. Probar con `terraform plan`
4. Crear Pull Request

## 📞 Soporte

- **Documentación Terraform**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **AWS Academy**: Ver docs en Learner Lab
- **Repo Issues**: GitHub Issues del proyecto

---

**Última actualización**: Noviembre 2025  
**Versión Terraform**: 1.13.4  
**Autor**: Milan (UDD - Arquitectura de Sistemas)
