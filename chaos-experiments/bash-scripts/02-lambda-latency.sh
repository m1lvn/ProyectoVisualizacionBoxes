#!/bin/bash
# Chaos Experiment 2: Lambda Latency Injection
# Objetivo: Simular latencia alta en Lambda functions

echo "═══════════════════════════════════════════════════"
echo "🔥 CHAOS EXPERIMENT: Lambda Latency Injection"
echo "═══════════════════════════════════════════════════"

# Configuración
LAMBDA_FUNCTION="getBoxes"
LATENCY_MS=5000
API_ENDPOINT="https://44wvhl6j05.execute-api.us-east-1.amazonaws.com/api/boxes"

echo "⚙️  Configuración:"
echo "   - Lambda: $LAMBDA_FUNCTION"
echo "   - Latencia inyectada: ${LATENCY_MS}ms"
echo "   - API Endpoint: $API_ENDPOINT"
echo ""

read -p "🔑 Ingrese su JWT token: " TOKEN

# 1. Baseline sin latencia
echo ""
echo "📊 PASO 1: Baseline (sin latencia)"
echo "---"

BASELINE_FILE="../results/baseline-$(date +%Y%m%d-%H%M%S).log"
echo "Baseline Results - $(date)" > $BASELINE_FILE

for i in {1..20}; do
    START=$(date +%s%N)
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
        "$API_ENDPOINT" \
        -H "Authorization: Bearer $TOKEN")
    END=$(date +%s%N)
    
    DURATION=$(( (END - START) / 1000000 ))
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d':' -f2)
    
    echo "Request $i: ${DURATION}ms | Status=$HTTP_CODE" | tee -a $BASELINE_FILE
done

AVG_BASELINE=$(cat $BASELINE_FILE | grep "Request" | cut -d':' -f2 | cut -d'm' -f1 | \
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
