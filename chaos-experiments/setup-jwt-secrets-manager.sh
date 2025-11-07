#!/bin/bash
# ════════════════════════════════════════════════════════════════
# Setup JWT Token en AWS Secrets Manager
# ════════════════════════════════════════════════════════════════
# 
# Este script configura el JWT Token en AWS Secrets Manager para
# automatizar completamente el proceso de autenticación en los
# experimentos de Chaos Engineering.
#
# USO:
#   ./setup-jwt-secrets-manager.sh
#

set -e

echo "════════════════════════════════════════════════════════════"
echo "   SETUP JWT EN AWS SECRETS MANAGER"
echo "════════════════════════════════════════════════════════════"
echo ""

# Configuración
SECRET_NAME="chaos-engineering/jwt-token"
REGION="us-east-1"

# Verificar AWS CLI
echo "[1/5] Verificando AWS CLI..."
if ! command -v aws &> /dev/null; then
    echo "   ❌ AWS CLI no está instalado"
    echo "   Instala con: sudo apt install awscli"
    exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "   ❌ AWS CLI no configurado o sin permisos"
    echo "   Ejecuta: aws configure"
    exit 1
fi

echo "   ✅ AWS CLI configurado"
echo "   Account: $AWS_ACCOUNT_ID"

echo ""
echo "[2/5] Obteniendo JWT Token..."
echo "   Tienes 3 opciones:"
echo ""
echo "   A) Obtener automáticamente desde Cognito (requiere configuración)"
echo "   B) Ingresar manualmente (⭐ RECOMENDADO - copiar desde navegador)"
echo "   C) Leer desde .env existente"
echo ""
echo "   💡 TIP para opción B:"
echo "      1. Abre tu app en navegador (ya autenticado)"
echo "      2. DevTools (F12) → Network → Headers"
echo "      3. Busca 'Authorization: Bearer <token>'"
echo "      4. Copia solo el token (sin 'Bearer')"
echo ""

read -p "Selecciona opción (A/B/C) [B por defecto]: " option
option=${option:-B}

JWT_TOKEN=""

case "${option^^}" in
    A)
        echo ""
        echo "   Intentando obtener desde Cognito..."
        
        # Verificar que Python3 esté disponible
        if ! command -v python3 &> /dev/null; then
            echo "   ⚠️  Python3 no encontrado. Instálalo primero."
            echo "   Usa opción B (manual)."
            exit 1
        fi
        
        # Verificar que existan las credenciales
        if [ -z "$COGNITO_USERNAME" ] || [ -z "$COGNITO_PASSWORD" ]; then
            echo ""
            echo "   📋 Ingresa tus credenciales de Cognito:"
            read -p "      Username (email): " COGNITO_USERNAME
            read -sp "      Password: " COGNITO_PASSWORD
            echo ""
        fi
        
        # Llamar al script Python que hace el login
        JWT_TOKEN=$(python3 "$(dirname "$0")/get-jwt-cognito.py" "$COGNITO_USERNAME" "$COGNITO_PASSWORD")
        
        if [ $? -ne 0 ] || [ -z "$JWT_TOKEN" ]; then
            echo ""
            echo "   ⚠️  No se pudo obtener automáticamente"
            echo "   Usa opción B (manual) o verifica tus credenciales."
            exit 1
        fi
        
        echo ""
        echo "   ✅ JWT obtenido desde Cognito"
        ;;
    
    B)
        echo ""
        echo "   📋 Cómo obtener el JWT Token:"
        echo "   1. Abre http://3.95.177.254:8000/auth/login"
        echo "   2. Haz login con tus credenciales"
        echo "   3. Abre Developer Tools (F12)"
        echo "   4. Ve a Application > Cookies o Session Storage"
        echo "   5. Busca 'jwt_token'"
        echo "   6. Copia el valor completo"
        echo ""
        
        read -p "   Pega el JWT Token aquí: " JWT_TOKEN
        JWT_TOKEN=$(echo "$JWT_TOKEN" | xargs)
        
        # Validar formato JWT
        if [[ ! "$JWT_TOKEN" =~ ^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$ ]]; then
            echo ""
            echo "   ⚠️  El token no tiene formato JWT válido (xxx.yyy.zzz)"
            read -p "   ¿Continuar de todas formas? (yes/no): " confirm
            
            if [ "$confirm" != "yes" ]; then
                echo "   Operación cancelada"
                exit 0
            fi
        fi
        ;;
    
    C)
        echo ""
        echo "   Leyendo desde .env..."
        
        if [ ! -f ".env" ]; then
            echo "   ❌ Archivo .env no encontrado"
            exit 1
        fi
        
        JWT_TOKEN=$(grep "^JWT_TOKEN=" .env | cut -d'=' -f2- | xargs)
        
        if [ -z "$JWT_TOKEN" ]; then
            echo "   ❌ JWT_TOKEN no encontrado en .env"
            exit 1
        fi
        
        echo "   ✅ JWT Token encontrado en .env"
        ;;
    
    *)
        echo "   ❌ Opción inválida"
        exit 1
        ;;
esac

# Verificar que tenemos un token
if [ -z "$JWT_TOKEN" ]; then
    echo ""
    echo "   ❌ No se obtuvo JWT Token"
    exit 1
fi

echo ""
echo "   ✅ JWT Token obtenido"
echo "   Preview: ${JWT_TOKEN:0:50}..."

# Crear secret en AWS Secrets Manager
echo ""
echo "[3/5] Creando/Actualizando secret en AWS Secrets Manager..."

# Preparar el secreto (JSON con metadata adicional)
SECRET_VALUE=$(cat <<EOF
{
  "jwtToken": "$JWT_TOKEN",
  "createdAt": "$(date -u +"%Y-%m-%d %H:%M:%S")",
  "createdBy": "$(aws sts get-caller-identity --query Arn --output text)",
  "purpose": "Chaos Engineering Experiments"
}
EOF
)

# Verificar si el secret ya existe
if aws secretsmanager describe-secret --secret-id "$SECRET_NAME" --region "$REGION" &>/dev/null; then
    echo "   Secret ya existe, actualizando..."
    
    aws secretsmanager put-secret-value \
        --secret-id "$SECRET_NAME" \
        --secret-string "$SECRET_VALUE" \
        --region "$REGION" \
        --output json > /dev/null
    
    echo "   ✅ Secret actualizado exitosamente"
else
    echo "   Secret no existe, creando nuevo..."
    
    aws secretsmanager create-secret \
        --name "$SECRET_NAME" \
        --description "JWT Token for Chaos Engineering experiments - Hospital Boxes API" \
        --secret-string "$SECRET_VALUE" \
        --region "$REGION" \
        --tags Key=Project,Value=hospital-boxes Key=Purpose,Value=chaos-engineering \
        --output json > /dev/null
    
    echo "   ✅ Secret creado exitosamente"
fi

# Actualizar .env también (backup local)
echo ""
echo "[4/5] Actualizando .env local (backup)..."

if [ -f ".env" ]; then
    if grep -q "^JWT_TOKEN=" .env; then
        sed -i "s|^JWT_TOKEN=.*|JWT_TOKEN=$JWT_TOKEN|" .env
    else
        echo "" >> .env
        echo "JWT_TOKEN=$JWT_TOKEN" >> .env
    fi
    echo "   ✅ .env actualizado"
else
    echo "   ⚠️  .env no encontrado, creando..."
    echo "JWT_TOKEN=$JWT_TOKEN" > .env
    echo "   ✅ .env creado"
fi

# Verificar que funciona
echo ""
echo "[5/5] Verificando configuración..."

RETRIEVED=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --region "$REGION" \
    --query SecretString \
    --output text)

RETRIEVED_TOKEN=$(echo "$RETRIEVED" | python3 -c "import sys, json; print(json.load(sys.stdin)['jwtToken'])" 2>/dev/null || echo "")

if [ "$RETRIEVED_TOKEN" = "$JWT_TOKEN" ]; then
    echo "   ✅ Verificación exitosa"
else
    echo "   ⚠️  Token almacenado difiere del original"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "   ✅ JWT TOKEN CONFIGURADO EN AWS SECRETS MANAGER"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Información del Secret:"
echo "   Name: $SECRET_NAME"
echo "   Region: $REGION"
echo ""
echo "Los scripts de chaos engineering ahora obtendrán"
echo "el JWT automáticamente desde AWS Secrets Manager."
echo ""
echo "Próximos pasos:"
echo "   cd bash-scripts"
echo "   ./01-dos-attack.sh"
echo ""
