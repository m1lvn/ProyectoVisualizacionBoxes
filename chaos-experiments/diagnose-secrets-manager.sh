#!/bin/bash
# ════════════════════════════════════════════════════════════════
# Diagnóstico de AWS Secrets Manager para Chaos Engineering
# ════════════════════════════════════════════════════════════════

echo "════════════════════════════════════════════════════════════════"
echo "   🔍 DIAGNÓSTICO AWS SECRETS MANAGER"
echo "════════════════════════════════════════════════════════════════"
echo ""

SECRET_NAME="chaos-engineering/jwt-token"
REGION="us-east-1"

# ═══════════════════════════════════════════════════════════════
# 1. Verificar AWS CLI y credenciales
# ═══════════════════════════════════════════════════════════════
echo "[1/7] Verificando AWS CLI..."

if ! command -v aws &> /dev/null; then
    echo "    ❌ AWS CLI no instalado"
    exit 1
fi

CALLER_IDENTITY=$(aws sts get-caller-identity 2>&1)
if [ $? -ne 0 ]; then
    echo "    ❌ AWS CLI no configurado o sin credenciales"
    echo "$CALLER_IDENTITY"
    exit 1
fi

ACCOUNT_ID=$(echo "$CALLER_IDENTITY" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
USER_ARN=$(echo "$CALLER_IDENTITY" | grep -o '"Arn": "[^"]*"' | cut -d'"' -f4)

echo "    ✅ AWS CLI configurado"
echo "    Account: $ACCOUNT_ID"
echo "    User/Role: $USER_ARN"
echo ""

# ═══════════════════════════════════════════════════════════════
# 2. Verificar permisos ListSecrets
# ═══════════════════════════════════════════════════════════════
echo "[2/7] Verificando permiso: secretsmanager:ListSecrets..."

LIST_OUTPUT=$(timeout 5s aws secretsmanager list-secrets --region $REGION 2>&1)
LIST_EXIT_CODE=$?

if [ $LIST_EXIT_CODE -eq 0 ]; then
    echo "    ✅ Permiso ListSecrets: OK"
    SECRET_COUNT=$(echo "$LIST_OUTPUT" | python3 -c "import sys, json; print(len(json.load(sys.stdin).get('SecretList', [])))" 2>/dev/null || echo "0")
    echo "    Secrets encontrados: $SECRET_COUNT"
elif [ $LIST_EXIT_CODE -eq 124 ]; then
    echo "    ⏱️  Timeout (5s) - Request colgado"
    echo "    Esto indica problemas de permisos o red"
else
    echo "    ❌ Permiso ListSecrets: DENEGADO"
    echo "$LIST_OUTPUT" | grep -i "AccessDenied\|not authorized\|UnauthorizedException" | head -n2 | sed 's/^/    /'
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# 3. Verificar si el secret existe
# ═══════════════════════════════════════════════════════════════
echo "[3/7] Verificando existencia del secret: $SECRET_NAME..."

DESCRIBE_OUTPUT=$(timeout 5s aws secretsmanager describe-secret \
    --secret-id "$SECRET_NAME" \
    --region $REGION 2>&1)
DESCRIBE_EXIT_CODE=$?

if [ $DESCRIBE_EXIT_CODE -eq 0 ]; then
    echo "    ✅ Secret existe"
    
    # Extraer información
    LAST_CHANGED=$(echo "$DESCRIBE_OUTPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('LastChangedDate', 'N/A'))" 2>/dev/null)
    echo "    Última modificación: $LAST_CHANGED"
elif [ $DESCRIBE_EXIT_CODE -eq 124 ]; then
    echo "    ⏱️  Timeout (5s)"
elif echo "$DESCRIBE_OUTPUT" | grep -qi "ResourceNotFoundException"; then
    echo "    ❌ Secret NO existe"
    echo "    Ejecuta: ./setup-jwt-secrets-manager.sh"
else
    echo "    ❌ Error al verificar secret"
    echo "$DESCRIBE_OUTPUT" | head -n3 | sed 's/^/    /'
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# 4. Verificar permiso GetSecretValue
# ═══════════════════════════════════════════════════════════════
echo "[4/7] Verificando permiso: secretsmanager:GetSecretValue..."

GET_OUTPUT=$(timeout 5s aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --region $REGION 2>&1)
GET_EXIT_CODE=$?

if [ $GET_EXIT_CODE -eq 0 ]; then
    echo "    ✅ Permiso GetSecretValue: OK"
    
    # Verificar contenido
    SECRET_STRING=$(echo "$GET_OUTPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('SecretString', ''))" 2>/dev/null)
    if [ -n "$SECRET_STRING" ]; then
        # Intentar parsear JWT
        JWT_TOKEN=$(echo "$SECRET_STRING" | python3 -c "import sys, json; print(json.load(sys.stdin).get('jwtToken', ''))" 2>/dev/null)
        
        if [ -n "$JWT_TOKEN" ]; then
            echo "    ✅ JWT Token encontrado"
            echo "    Preview: ${JWT_TOKEN:0:50}..."
        else
            echo "    ⚠️  Secret existe pero no contiene 'jwtToken'"
            echo "    Contenido: $SECRET_STRING" | head -c 100
        fi
    else
        echo "    ⚠️  Secret existe pero está vacío"
    fi
elif [ $GET_EXIT_CODE -eq 124 ]; then
    echo "    ⏱️  Timeout (5s) - Request colgado"
    echo "    💡 AWS Academy puede no tener permisos GetSecretValue"
elif echo "$GET_OUTPUT" | grep -qi "AccessDenied\|not authorized\|UnauthorizedException"; then
    echo "    ❌ Permiso GetSecretValue: DENEGADO"
    echo ""
    echo "    ⚠️  Tu usuario/role NO tiene permiso para leer secrets"
    echo "    User/Role: $USER_ARN"
    echo ""
    echo "$GET_OUTPUT" | grep -i "error\|denied\|unauthorized" | head -n3 | sed 's/^/    /'
elif echo "$GET_OUTPUT" | grep -qi "ResourceNotFoundException"; then
    echo "    ⚠️  Secret no existe"
    echo "    Ejecuta: ./setup-jwt-secrets-manager.sh"
else
    echo "    ❌ Error desconocido"
    echo "$GET_OUTPUT" | head -n3 | sed 's/^/    /'
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# 5. Verificar .env como fallback
# ═══════════════════════════════════════════════════════════════
echo "[5/7] Verificando .env como fallback..."

if [ -f ".env" ]; then
    echo "    ✅ Archivo .env existe"
    
    JWT_FROM_ENV=$(grep "^JWT_TOKEN=" .env | cut -d'=' -f2- | xargs)
    if [ -n "$JWT_FROM_ENV" ]; then
        echo "    ✅ JWT_TOKEN encontrado en .env"
        echo "    Preview: ${JWT_FROM_ENV:0:50}..."
    else
        echo "    ⚠️  JWT_TOKEN no configurado en .env"
    fi
else
    echo "    ⚠️  Archivo .env no existe"
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# 6. Verificar get-jwt-from-secrets.sh
# ═══════════════════════════════════════════════════════════════
echo "[6/7] Probando script get-jwt-from-secrets.sh..."

if [ -f "get-jwt-from-secrets.sh" ]; then
    echo "    ✅ Script existe"
    
    TEST_OUTPUT=$(./get-jwt-from-secrets.sh --verbose 2>&1)
    TEST_EXIT_CODE=$?
    
    if [ $TEST_EXIT_CODE -eq 0 ]; then
        echo "    ✅ Script funciona correctamente"
        TOKEN=$(echo "$TEST_OUTPUT" | tail -n1)
        echo "    Token preview: ${TOKEN:0:50}..."
    else
        echo "    ❌ Script falló con exit code: $TEST_EXIT_CODE"
        echo ""
        echo "    Output del script:"
        echo "$TEST_OUTPUT" | sed 's/^/    /'
    fi
else
    echo "    ❌ Script get-jwt-from-secrets.sh no encontrado"
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# 7. Resumen y Recomendaciones
# ═══════════════════════════════════════════════════════════════
echo "[7/7] Resumen y Recomendaciones..."
echo ""

if [ $GET_EXIT_CODE -eq 0 ] && [ -n "$JWT_TOKEN" ]; then
    echo "✅ ESTADO: TODO FUNCIONA CORRECTAMENTE"
    echo ""
    echo "   Secrets Manager: ✅ Accesible"
    echo "   JWT Token: ✅ Disponible"
    echo "   Script: ✅ Funcional"
    echo ""
    echo "🚀 Puedes ejecutar los experimentos de chaos:"
    echo "   ./run-all-chaos-experiments.sh"
    
elif [ $GET_EXIT_CODE -eq 124 ] || echo "$GET_OUTPUT" | grep -qi "AccessDenied"; then
    echo "⚠️  ESTADO: SECRETS MANAGER NO DISPONIBLE (Sin permisos)"
    echo ""
    echo "   Secrets Manager: ❌ Sin permisos GetSecretValue"
    echo "   Posible causa: AWS Academy Learner Lab restringe Secrets Manager"
    echo ""
    echo "💡 SOLUCIÓN: Usar .env como alternativa"
    echo ""
    echo "   1. Verifica que el JWT esté en .env:"
    echo "      cat .env | grep JWT_TOKEN"
    echo ""
    echo "   2. Si está vacío, ejecuta:"
    echo "      ./setup-jwt-secrets-manager.sh"
    echo "      Selecciona opción A (Cognito) o B (Manual)"
    echo ""
    echo "   3. El script run-all-chaos-experiments.sh usará .env automáticamente"
    echo ""
    
    if [ -n "$JWT_FROM_ENV" ]; then
        echo "   ✅ JWT ya disponible en .env - Puedes ejecutar experimentos"
    else
        echo "   ⚠️  JWT no encontrado en .env - Ejecuta setup primero"
    fi
    
elif echo "$GET_OUTPUT" | grep -qi "ResourceNotFoundException"; then
    echo "⚠️  ESTADO: SECRET NO CONFIGURADO"
    echo ""
    echo "   Secrets Manager: ✅ Accesible"
    echo "   JWT Token: ❌ No configurado"
    echo ""
    echo "💡 SOLUCIÓN:"
    echo "   ./setup-jwt-secrets-manager.sh"
    
else
    echo "❌ ESTADO: ERROR DESCONOCIDO"
    echo ""
    echo "   Revisa los logs anteriores para más detalles"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
