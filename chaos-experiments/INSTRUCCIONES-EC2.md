# 🚀 Instrucciones para Ejecutar en EC2

## Paso 1: Actualizar código

```bash
cd ~/ProyectoVisualizacionBoxes/chaos-experiments
git pull origin milan
```

## Paso 2: Dar permisos de ejecución

```bash
chmod +x get-cognito-jwt.sh
chmod +x get-cognito-jwt.py
```

## Paso 3: Verificar boto3 instalado

```bash
source ~/.venv/bin/activate
pip install boto3
```

## Paso 4: Verificar que el stack esté desplegado

```bash
aws cloudformation describe-stacks \
    --stack-name hospital-boxes-api-dev \
    --query 'Stacks[0].Outputs[?OutputKey==`UserPoolId` || OutputKey==`ApiGatewayUrl`].[OutputKey,OutputValue]' \
    --output table
```

**Deberías ver:**
```
----------------------------------------------------------------------------------------
|                                  DescribeStacks                                      |
+-----------------------+----------------------------------------------------------+
|  UserPoolId          |  us-east-1_XXXXXXXXX                                     |
|  ApiGatewayUrl       |  https://XXXXXXXXXX.execute-api.us-east-1.amazonaws.com  |
+-----------------------+----------------------------------------------------------+
```

## Paso 5: Verificar usuarios de prueba

```bash
USER_POOL_ID=$(aws cloudformation describe-stacks \
    --stack-name hospital-boxes-api-dev \
    --query 'Stacks[0].Outputs[?OutputKey==`UserPoolId`].OutputValue' \
    --output text)

aws cognito-idp list-users --user-pool-id $USER_POOL_ID
```

**Si NO hay usuarios:**

```bash
# Crear usuario admin manualmente
aws cognito-idp admin-create-user \
    --user-pool-id $USER_POOL_ID \
    --username admin@hospital.test \
    --user-attributes \
        Name=email,Value=admin@hospital.test \
        Name=given_name,Value=Admin \
        Name=family_name,Value=User \
        Name=email_verified,Value=true

# Establecer contraseña
aws cognito-idp admin-set-user-password \
    --user-pool-id $USER_POOL_ID \
    --username admin@hospital.test \
    --password "Admin123!" \
    --permanent
```

## Paso 6: Obtener JWT Token

```bash
cd ~/ProyectoVisualizacionBoxes/chaos-experiments
./get-cognito-jwt.sh --verbose
```

**Output esperado:**
```
============================================================
🔑 Obteniendo JWT Token desde Cognito User Pool
============================================================

📦 Obteniendo información del stack...
✅ User Pool ID: us-east-1_XXXXXXXXX
✅ Client ID: XXXXXXXXXXXXXXXXXXXXXXXXXX
✅ API Endpoint: https://XXXXXXXXXX.execute-api.us-east-1.amazonaws.com

👤 Obteniendo credenciales de usuario de prueba...
✅ Usando usuario: admin@hospital.test
   (Usuario administrador de prueba)

🔐 Autenticando usuario: admin@hospital.test...
✅ Autenticación exitosa!
   Token expira en: 3600 segundos

📝 Actualizando archivo .env...
✅ Archivo .env actualizado

============================================================
✅ JWT Token obtenido exitosamente
============================================================

🔗 API Endpoint: https://XXXXXXXXXX.execute-api.us-east-1.amazonaws.com
👤 Usuario: admin@hospital.test
⏰ Válido por: 3600 segundos (~60 minutos)

eyJraWQiOiJ... (token largo)
```

## Paso 7: Verificar .env actualizado

```bash
cat .env
```

**Debería contener:**
```
JWT_TOKEN=eyJraWQiOiJ...
API_ENDPOINT=https://XXXXXXXXXX.execute-api.us-east-1.amazonaws.com
```

## Paso 8: Ejecutar primer experimento

```bash
cd bash-scripts
./01-dos-attack.sh
```

**Output esperado (si funciona):**
```
✅ Ataque completado
📊 Resultados guardados en: ../results/dos-attack-YYYYMMDD-HHMMSS.log

📈 Análisis de Resultados:
---
Total Requests: 1000
Successful (200): 850 (85%)        ← DEBERÍA SER >0%
Not Found (404): 0 (0%)            ← DEBERÍA SER 0%
Throttled (429): 150 (15%)
Client Errors (4xx): 0 (0%)
Server Errors (5xx): 0 (0%)
...

💡 Interpretación:
   ✅ Sistema resistió bien la carga (>80% exitosos)
```

## Troubleshooting

### Si todavía obtienes 404:

1. **Verificar que el endpoint sea correcto:**
   ```bash
   cat .env | grep API_ENDPOINT
   ```
   Debería ser la URL del Output `ApiGatewayUrl` (sin /dev al final)

2. **Probar endpoint manualmente:**
   ```bash
   JWT_TOKEN=$(cat .env | grep JWT_TOKEN | cut -d'=' -f2)
   API_ENDPOINT=$(cat .env | grep API_ENDPOINT | cut -d'=' -f2)
   
   curl -v -H "Authorization: Bearer $JWT_TOKEN" \
       "${API_ENDPOINT}/dev/api/boxes"
   ```

3. **Verificar que el path sea correcto:**
   - El endpoint es `/dev/api/boxes` o solo `/api/boxes`?
   - Revisar en API Gateway console

### Si el usuario no existe:

Ver **Paso 5** arriba para crear manualmente

### Si boto3 no está instalado:

```bash
source ~/.venv/bin/activate
pip install boto3
```

### Si el token expira:

```bash
# Borrar token viejo
sed -i '/^JWT_TOKEN=/d' .env

# Obtener nuevo token
./get-cognito-jwt.sh --verbose
```

## Paso 9: Ejecutar suite completa (una vez funcione)

```bash
cd ~/ProyectoVisualizacionBoxes/chaos-experiments
./run-all-chaos-experiments.sh
```

---

## Resumen del Cambio

**Antes:** Usábamos JWT de API externa (serverless-auth) → 404 porque API Gateway no lo validaba

**Ahora:** Usamos JWT de nuestro Cognito User Pool → API Gateway valida y permite acceso

**Clave:** El JWT debe venir del **mismo Cognito User Pool** configurado en `serverless.yml` como authorizer
