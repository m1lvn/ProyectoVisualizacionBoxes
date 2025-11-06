#!/bin/bash
# ════════════════════════════════════════════════════════════════
# Obtener JWT Token desde AWS Secrets Manager
# ════════════════════════════════════════════════════════════════
# 
# Este script obtiene el JWT Token almacenado en AWS Secrets Manager
# y lo retorna para uso en otros scripts de chaos engineering.
#
# USO:
#   TOKEN=$(./get-jwt-from-secrets.sh)
#   ./get-jwt-from-secrets.sh --verbose
#

SECRET_NAME="chaos-engineering/jwt-token"
REGION="us-east-1"
VERBOSE=false

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --secret-name)
            SECRET_NAME="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

if [ "$VERBOSE" = true ]; then
    echo "[*] Obteniendo JWT desde AWS Secrets Manager..." >&2
    echo "    Secret: $SECRET_NAME" >&2
    echo "    Region: $REGION" >&2
fi

# Intentar obtener el secret desde AWS Secrets Manager
SECRET_JSON=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --region "$REGION" \
    --query SecretString \
    --output text 2>&1)

if [ $? -ne 0 ]; then
    if [ "$VERBOSE" = true ]; then
        echo "" >&2
        echo "[ERROR] No se pudo obtener el secret desde AWS Secrets Manager" >&2
        echo "$SECRET_JSON" >&2
        echo "" >&2
        echo "Soluciones:" >&2
        echo "  1. Ejecuta: ./setup-jwt-secrets-manager.sh" >&2
        echo "  2. O configura JWT_TOKEN en .env manualmente" >&2
    fi
    
    # Fallback: intentar leer desde .env
    if [ -f ".env" ]; then
        TOKEN=$(grep "^JWT_TOKEN=" .env | cut -d'=' -f2- | xargs)
        
        if [ -n "$TOKEN" ]; then
            if [ "$VERBOSE" = true ]; then
                echo "[*] JWT obtenido desde .env (fallback)" >&2
            fi
            echo "$TOKEN"
            exit 0
        fi
    fi
    
    if [ "$VERBOSE" = true ]; then
        echo "" >&2
        echo "[ERROR] No se encontró JWT en Secrets Manager ni en .env" >&2
    fi
    exit 1
fi

# Parsear el JSON y extraer el JWT token
JWT_TOKEN=$(echo "$SECRET_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin)['jwtToken'])" 2>/dev/null)

if [ -z "$JWT_TOKEN" ]; then
    if [ "$VERBOSE" = true ]; then
        echo "[ERROR] JWT Token está vacío en Secrets Manager" >&2
    fi
    exit 1
fi

if [ "$VERBOSE" = true ]; then
    echo "[OK] JWT Token obtenido exitosamente" >&2
    echo "     Preview: ${JWT_TOKEN:0:50}..." >&2
fi

# Retornar el token
echo "$JWT_TOKEN"
