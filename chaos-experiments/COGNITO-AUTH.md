# Autenticación con Cognito User Pool para Chaos Engineering

## Visión General

Los experimentos de chaos engineering requieren un **JWT Token válido** desde el **Cognito User Pool** de tu API para acceder a los endpoints protegidos.

**IMPORTANTE:** El JWT de la API externa (serverless-auth) **NO funciona** para los endpoints de tu propia API (`/api/boxes`, `/api/agendas`, etc.) porque estos requieren autenticación con tu propio Cognito User Pool.

## Flujo de Autenticación

```
┌─────────────────────┐
│  Cognito User Pool  │
│  (hospital-users)   │
└──────────┬──────────┘
           │ 1. Admin Auth
           ▼
     ┌──────────┐
     │   JWT    │ ←─── IdToken válido por ~60 min
     │  Token   │
     └────┬─────┘
          │ 2. Authorization: Bearer <JWT>
          ▼
   ┌─────────────────┐
   │  API Gateway    │
   │  /api/boxes     │ ←─── Valida JWT con Cognito
   └─────────────────┘
```

## Uso Rápido

### Obtener JWT Token

```bash
# Modo básico (solo imprime el token)
./get-cognito-jwt.sh

# Modo verbose (muestra detalles del proceso)
./get-cognito-jwt.sh --verbose

# Usar usuario específico
./get-cognito-jwt.sh --user admin     # Usuario administrador
./get-cognito-jwt.sh --user personal  # Usuario personal médico
./get-cognito-jwt.sh --user test      # Usuario genérico
```

El script automáticamente:
1. ✅ Obtiene UserPoolId y ClientId desde CloudFormation
2. ✅ Autentica con Cognito usando credenciales de prueba
3. ✅ Actualiza el archivo `.env` con el JWT y API endpoint
4. ✅ Imprime el token en stdout para captura

### Ejecutar Experimentos

Los scripts de chaos ya están configurados para usar el nuevo sistema:

```bash
# Un experimento individual
cd bash-scripts
./01-dos-attack.sh

# Suite completa
./run-all-chaos-experiments.sh
```

Los scripts automáticamente:
- Intentan cargar JWT desde `.env`
- Si no existe, llaman a `get-cognito-jwt.sh` automáticamente
- Validan que sea un token válido de Cognito

## Usuarios de Prueba

El script `serverless-api/src/handlers/setup-test-users.js` crea usuarios predefinidos:

| Usuario | Email | Contraseña | Rol |
|---------|-------|------------|-----|
| admin | `admin@hospital.test` | `Admin123!` | Administrador |
| personal | `personal@hospital.test` | `Personal123!` | Personal Médico |
| test | `test@hospital.test` | `Test123!` | Usuario Genérico |

### Verificar Usuarios Existentes

```bash
# Obtener User Pool ID
USER_POOL_ID=$(aws cloudformation describe-stacks \
    --stack-name hospital-boxes-api-dev \
    --query 'Stacks[0].Outputs[?OutputKey==`UserPoolId`].OutputValue' \
    --output text)

# Listar usuarios
aws cognito-idp list-users --user-pool-id $USER_POOL_ID
```

### Crear Usuario Manualmente (si no existe)

```bash
# 1. Crear usuario
aws cognito-idp admin-create-user \
    --user-pool-id $USER_POOL_ID \
    --username admin@hospital.test \
    --user-attributes \
        Name=email,Value=admin@hospital.test \
        Name=given_name,Value=Admin \
        Name=family_name,Value=User \
        Name=email_verified,Value=true

# 2. Establecer contraseña permanente
aws cognito-idp admin-set-user-password \
    --user-pool-id $USER_POOL_ID \
    --username admin@hospital.test \
    --password "Admin123!" \
    --permanent
```

## Arquitectura

### Script Python: `get-cognito-jwt.py`

**Funcionalidad:**
- Obtiene outputs del stack CloudFormation (UserPoolId, ClientId, ApiGatewayUrl)
- Autentica usuario con `admin_initiate_auth` (ADMIN_NO_SRP_AUTH)
- Maneja casos especiales (usuario no confirmado, password incorrecto)
- Actualiza archivo `.env` automáticamente
- Retorna IdToken en stdout para captura

**Dependencias:**
- `boto3` (AWS SDK)
- Credenciales AWS configuradas

### Script Bash: `get-cognito-jwt.sh`

**Funcionalidad:**
- Wrapper simple para el script Python
- Manejo de argumentos (`--verbose`, `--user`)
- Verificación de dependencias (boto3)
- Activación automática de venv

**Uso en scripts:**
```bash
# Capturar token
JWT_TOKEN=$(./get-cognito-jwt.sh)

# Con manejo de errores
JWT_TOKEN=$(./get-cognito-jwt.sh --user admin)
if [ $? -ne 0 ]; then
    echo "Error obteniendo JWT"
    exit 1
fi
```

## Troubleshooting

### Error: "Usuario no existe"

**Causa:** Los usuarios de prueba no fueron creados en el deploy

**Solución:**
```bash
# Verificar que el Custom Resource se ejecutó
aws cloudformation describe-stack-events \
    --stack-name hospital-boxes-api-dev \
    --query 'StackEvents[?ResourceType==`AWS::CloudFormation::CustomResource`]'

# Si no se ejecutó, crear usuario manualmente (ver sección anterior)
```

### Error: "NotAuthorizedException"

**Causa:** Contraseña incorrecta

**Solución:**
1. Verificar credenciales en `get-cognito-jwt.py` líneas 32-48
2. Restablecer contraseña:
```bash
aws cognito-idp admin-set-user-password \
    --user-pool-id $USER_POOL_ID \
    --username admin@hospital.test \
    --password "Admin123!" \
    --permanent
```

### Error: "Stack no encontrado"

**Causa:** La API no está desplegada o el nombre del stack es diferente

**Solución:**
```bash
# Listar stacks existentes
aws cloudformation list-stacks \
    --query 'StackSummaries[?StackStatus==`CREATE_COMPLETE` || StackStatus==`UPDATE_COMPLETE`].StackName'

# Si el nombre es diferente, editar get-cognito-jwt.py línea 13
```

### Error: "boto3 not found"

**Causa:** boto3 no instalado en el entorno

**Solución:**
```bash
# Activar venv
source ~/.venv/bin/activate

# Instalar boto3
pip install boto3
```

### Token expira durante experimentos

**Causa:** Los tokens Cognito expiran en ~60 minutos

**Solución:**
```bash
# Refrescar token antes de ejecutar suite larga
./get-cognito-jwt.sh --verbose

# O eliminar JWT_TOKEN de .env para forzar refresh
sed -i '/^JWT_TOKEN=/d' .env
```

## Diferencias con Sistema Anterior

| Aspecto | Sistema Anterior (serverless-auth) | Sistema Actual (Cognito) |
|---------|-----------------------------------|--------------------------|
| **Fuente** | API externa (44wvhl6j05...) | Cognito User Pool propio |
| **Validación** | API Gateway no valida | API Gateway valida con Cognito |
| **Usuarios** | Admin externo | Usuarios de prueba propios |
| **Resultado** | ❌ 404 Not Found | ✅ 200 OK (si configurado) |
| **Expiración** | Variable | ~60 minutos |
| **Renovación** | Manual | Automático con script |

## Scripts Actualizados

Los siguientes scripts ahora usan el nuevo sistema de autenticación:

- ✅ `01-dos-attack.sh` - DoS attack simulation
- ✅ `02-lambda-latency.sh` - Lambda latency injection
- ✅ `03-sns-failure.sh` - SNS failure simulation
- ✅ `04-dynamodb-throttling-sim.sh` - DynamoDB throttling
- ✅ `05-lambda-errors-sim.sh` - Lambda error injection
- ✅ `run-all-chaos-experiments.sh` - Master orchestrator

Todos intentan:
1. Cargar JWT desde `.env`
2. Si no existe, ejecutar `get-cognito-jwt.sh`
3. Validar que el token sea válido

## Próximos Pasos

1. **Verificar usuarios de prueba existen:**
   ```bash
   ./get-cognito-jwt.sh --verbose
   ```

2. **Ejecutar primer experimento:**
   ```bash
   cd bash-scripts
   ./01-dos-attack.sh
   ```

3. **Si funciona (200 OK), ejecutar suite completa:**
   ```bash
   ./run-all-chaos-experiments.sh
   ```

4. **Revisar resultados:**
   ```bash
   ls -la results/dos-attack-*.log
   cat results/suite-*/summary.md
   ```

## Referencias

- [AWS Cognito Admin Auth Flow](https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-authentication-flow.html)
- [API Gateway JWT Authorizers](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-jwt-authorizer.html)
- [Serverless Framework Cognito](https://www.serverless.com/framework/docs/providers/aws/events/http-api#jwt-authorizers)
