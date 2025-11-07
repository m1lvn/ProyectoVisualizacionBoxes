#!/bin/bash
# Chaos Experiment 2: Lambda Latency Injection
# Objetivo: Simular latencia alta en Lambda functions

echo "═══════════════════════════════════════════════════"
echo "🔥 CHAOS EXPERIMENT: Lambda Latency Injection"
echo "═══════════════════════════════════════════════════"

# Obtener directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

# Cargar variables de entorno si existen
if [ -f "$ENV_FILE" ]; then
    echo "📄 Cargando variables desde .env..."
    export $(cat "$ENV_FILE" | grep -v '^#' | grep -v '^$' | xargs)
fi

# Auto-detectar AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "❌ Error: No se pudo obtener AWS Account ID"
    echo "   Asegúrate de tener AWS CLI configurado: aws configure"
    exit 1
fi

# Usar API_ENDPOINT desde .env si existe
if [ -n "$API_ENDPOINT" ]; then
    # Asegurar que tiene /boxes al final
    if [[ ! "$API_ENDPOINT" == */boxes ]]; then
        API_ENDPOINT="${API_ENDPOINT}/boxes"
    fi
    echo "✅ API Endpoint cargado desde .env"
else
    # Intentar auto-detectar desde API Gateway
    echo "🔍 Auto-detectando API Gateway..."
    API_ID=$(aws apigateway get-rest-apis --query "items[?name=='hospital-boxes-api-dev'].id" --output text 2>/dev/null)
    if [ -n "$API_ID" ]; then
        AWS_REGION=$(aws configure get region 2>/dev/null || echo "us-east-1")
        API_ENDPOINT="https://${API_ID}.execute-api.${AWS_REGION}.amazonaws.com/dev/api/boxes"
        echo "✅ API Endpoint auto-detectado: $API_ENDPOINT"
    else
        # Fallback final: preguntar al usuario
        echo "⚠️  No se pudo auto-detectar el API endpoint"
        read -p "Ingresa el API endpoint (ej: https://xxxxx.execute-api.us-east-1.amazonaws.com/dev/api/boxes): " API_ENDPOINT
    fi
fi

# Configuración
LAMBDA_FUNCTION="getBoxes"
LATENCY_MS=5000

echo ""
echo "⚙️  Configuración:"
echo "   - AWS Account: $AWS_ACCOUNT_ID"
echo "   - Lambda: $LAMBDA_FUNCTION"
echo "   - Latencia inyectada: ${LATENCY_MS}ms"
echo "   - API Endpoint: $API_ENDPOINT"
echo ""

# Obtener JWT Token automáticamente
echo "🔐 Obteniendo JWT Token..."

# Intentar obtener desde JWT_TOKEN variable de entorno (cargada desde .env)
if [ -n "$JWT_TOKEN" ]; then
    TOKEN="$JWT_TOKEN"
    echo "✅ JWT Token cargado desde .env"
# Intentar obtener desde AWS Secrets Manager
elif command -v aws &> /dev/null; then
    TOKEN=$(aws secretsmanager get-secret-value \
        --secret-id chaos-engineering/jwt-token \
        --region us-east-1 \
        --query 'SecretString' --output text 2>/dev/null | \
        python3 -c "import sys, json; print(json.load(sys.stdin)['jwtToken'])" 2>/dev/null)
    
    if [ -n "$TOKEN" ]; then
        echo "✅ JWT Token obtenido desde Secrets Manager"
    fi
fi

# Fallback final: preguntar al usuario
if [ -z "$TOKEN" ]; then
    echo "⚠️  No se pudo obtener JWT automáticamente"
    read -p "🔑 Ingrese su JWT token: " TOKEN
fi

# 1. Baseline sin latencia
echo ""
echo "📊 PASO 1: Baseline (sin latencia)"
echo "---"

# Crear directorio de resultados si no existe
RESULTS_DIR="$SCRIPT_DIR/../results"
mkdir -p "$RESULTS_DIR"

BASELINE_FILE="$RESULTS_DIR/baseline-$(date +%Y%m%d-%H%M%S).log"
echo "Baseline Results - $(date)" > "$BASELINE_FILE"

for i in {1..20}; do
    START=$(date +%s%N)
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
        "$API_ENDPOINT" \
        -H "Authorization: Bearer $TOKEN")
    END=$(date +%s%N)
    
    DURATION=$(( (END - START) / 1000000 ))
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d':' -f2)
    
    echo "Request $i: ${DURATION}ms | Status=$HTTP_CODE" | tee -a "$BASELINE_FILE"
done

AVG_BASELINE=$(cat "$BASELINE_FILE" | grep "Request" | cut -d':' -f2 | cut -d'm' -f1 | \
               awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; }')
echo ""
echo "✅ Latencia baseline promedio: ${AVG_BASELINE}ms"

# 2. Crear código con latencia
echo ""
echo "💉 PASO 2: Inyectando latencia en Lambda..."
echo "---"

# Backup del código original
HANDLER_PATH="../../serverless-api/src/handlers/boxes.js"
BACKUP_PATH="../../serverless-api/src/handlers/boxes.js.backup"

if [ ! -f "$HANDLER_PATH" ]; then
    echo "❌ Error: No se encuentra el archivo $HANDLER_PATH"
    exit 1
fi

echo "💾 Creando backup..."
cp "$HANDLER_PATH" "$BACKUP_PATH"

# Inyectar código de latencia
echo "📝 Modificando código..."
sed -i "1a\\
// 🔥 CHAOS ENGINEERING: Latencia artificial de ${LATENCY_MS}ms\\
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));\\
const originalHandler = module.exports.getBoxes;\\
module.exports.getBoxes = async (event) => {\\
  await sleep($LATENCY_MS);\\
  return originalHandler(event);\\
};" "$HANDLER_PATH"

# Desplegar Lambda modificada
echo ""
echo "📦 Desplegando Lambda con latencia..."
cd ../../serverless-api
serverless deploy function -f $LAMBDA_FUNCTION --verbose
cd ../chaos-experiments/bash-scripts

echo ""
echo "⏱️  Esperando 10 segundos para que el despliegue tome efecto..."
sleep 10

# 3. Pruebas con latencia
echo ""
echo "🔥 PASO 3: Pruebas con latencia artificial"
echo "---"

CHAOS_FILE="../results/chaos-latency-$(date +%Y%m%d-%H%M%S).log"
echo "Chaos Latency Results - $(date)" > $CHAOS_FILE

for i in {1..20}; do
    START=$(date +%s%N)
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
        "$API_ENDPOINT" \
        -H "Authorization: Bearer $TOKEN")
    END=$(date +%s%N)
    
    DURATION=$(( (END - START) / 1000000 ))
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d':' -f2)
    
    echo "Request $i: ${DURATION}ms | Status=$HTTP_CODE" | tee -a $CHAOS_FILE
done

AVG_CHAOS=$(cat $CHAOS_FILE | grep "Request" | cut -d':' -f2 | cut -d'm' -f1 | \
            awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; }')

echo ""
echo "⚠️  Latencia promedio con chaos: ${AVG_CHAOS}ms"
echo "📊 Incremento de latencia: $(( AVG_CHAOS - AVG_BASELINE ))ms"

# 4. Restaurar código original
echo ""
echo "✅ PASO 4: Restaurando código original..."
echo "---"

mv "$BACKUP_PATH" "$HANDLER_PATH"

echo "📦 Re-desplegando Lambda original..."
cd ../../serverless-api
serverless deploy function -f $LAMBDA_FUNCTION --verbose
cd ../chaos-experiments/bash-scripts

echo ""
echo "⏱️  Esperando 10 segundos..."
sleep 10

# 5. Validación post-restauración
echo ""
echo "🔍 PASO 5: Validación post-restauración"
echo "---"

RECOVERY_FILE="../results/recovery-$(date +%Y%m%d-%H%M%S).log"
echo "Recovery Results - $(date)" > $RECOVERY_FILE

for i in {1..10}; do
    START=$(date +%s%N)
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
        "$API_ENDPOINT" \
        -H "Authorization: Bearer $TOKEN")
    END=$(date +%s%N)
    
    DURATION=$(( (END - START) / 1000000 ))
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d':' -f2)
    
    echo "Request $i: ${DURATION}ms | Status=$HTTP_CODE" | tee -a $RECOVERY_FILE
done

AVG_RECOVERY=$(cat $RECOVERY_FILE | grep "Request" | cut -d':' -f2 | cut -d'm' -f1 | \
               awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; }')

echo ""
echo "═══════════════════════════════════════════════════"
echo "📊 RESUMEN DE RESULTADOS"
echo "═══════════════════════════════════════════════════"
echo "Latencia baseline:     ${AVG_BASELINE}ms"
echo "Latencia con chaos:    ${AVG_CHAOS}ms"
echo "Latencia post-recovery: ${AVG_RECOVERY}ms"
echo ""
echo "Incremento durante chaos: $(( AVG_CHAOS - AVG_BASELINE ))ms"
echo "Recuperación:             $(( AVG_RECOVERY - AVG_BASELINE ))ms"
echo ""

if [ "$AVG_RECOVERY" -lt $(( AVG_BASELINE + 100 )) ]; then
    echo "✅ Sistema recuperado exitosamente"
else
    echo "⚠️  Advertencia: Sistema aún degradado"
fi

echo ""
echo "📁 Archivos de resultados:"
echo "   - Baseline:  $BASELINE_FILE"
echo "   - Chaos:     $CHAOS_FILE"
echo "   - Recovery:  $RECOVERY_FILE"

echo "═══════════════════════════════════════════════════"
echo "✅ Experimento completado"
echo "═══════════════════════════════════════════════════"
