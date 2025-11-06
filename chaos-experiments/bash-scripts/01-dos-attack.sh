#!/bin/bash
# Chaos Experiment 1: DoS Attack Simulation
# Objetivo: Probar rate limiting y throttling de API Gateway

echo "═══════════════════════════════════════════════════"
echo "🔥 CHAOS EXPERIMENT: DoS Attack Simulation"
echo "═══════════════════════════════════════════════════"

# Cargar variables de entorno
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | grep -v '^#' | grep -v '^$' | xargs)
fi

# Configuración
API_ENDPOINT="${API_ENDPOINT:-https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api}"
ENDPOINT="/boxes"
REQUESTS=1000
CONCURRENT=50

echo "⚙️  Configuración:"
echo "   - API: $API_ENDPOINT$ENDPOINT"
echo "   - Total requests: $REQUESTS"
echo "   - Concurrent: $CONCURRENT"
echo ""

# Obtener token de autenticación
if [ -z "$JWT_TOKEN" ]; then
    echo "⚠️  JWT_TOKEN no encontrado en .env"
    echo ""
    echo "🔄 Obteniendo token automáticamente..."
    cd "$SCRIPT_DIR/.."
    source ./get-jwt.sh
    cd "$SCRIPT_DIR"
    
    # Recargar variables
    export $(cat "$ENV_FILE" | grep -v '^#' | grep -v '^$' | xargs)
fi

TOKEN="$JWT_TOKEN"
echo "✅ Token cargado correctamente"

echo ""
echo "📊 Ejecutando baseline (10 requests secuenciales)..."
for i in {1..10}; do
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}|TIME:%{time_total}" \
        "$API_ENDPOINT$ENDPOINT" \
        -H "Authorization: Bearer $TOKEN")
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d':' -f2 | cut -d'|' -f1)
    TIME=$(echo "$RESPONSE" | grep "TIME" | cut -d':' -f2)
    
    echo "  Request $i: Status=$HTTP_CODE | Time=${TIME}s"
done

echo ""
read -p "🚨 ¿Iniciar ataque DoS? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
    echo ""
    echo "💥 Iniciando ataque DoS..."
    echo "⏱️  Timestamp: $(date)"
    
    # Crear archivo de resultados
    RESULT_FILE="../results/dos-attack-$(date +%Y%m%d-%H%M%S).log"
    echo "DoS Attack Results - $(date)" > $RESULT_FILE
    echo "API: $API_ENDPOINT$ENDPOINT" >> $RESULT_FILE
    echo "Total Requests: $REQUESTS" >> $RESULT_FILE
    echo "Concurrent: $CONCURRENT" >> $RESULT_FILE
    echo "---" >> $RESULT_FILE
    
    # Bombardear con requests
    for i in $(seq 1 $REQUESTS); do
        (
            RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}|TIME:%{time_total}" \
                "$API_ENDPOINT$ENDPOINT" \
                -H "Authorization: Bearer $TOKEN" \
                2>&1)
            
            HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d':' -f2 | cut -d'|' -f1)
            TIME=$(echo "$RESPONSE" | grep "TIME" | cut -d':' -f2)
            
            echo "Request $i: $HTTP_CODE | ${TIME}s" >> $RESULT_FILE
            echo "Request $i: Status=$HTTP_CODE | Time=${TIME}s"
        ) &
        
        # Control de concurrencia
        if [ $(jobs -r | wc -l) -ge $CONCURRENT ]; then
            wait -n
        fi
    done
    
    wait
    
    echo ""
    echo "✅ Ataque completado"
    echo "📊 Resultados guardados en: $RESULT_FILE"
    
    # Análisis de resultados
    echo ""
    echo "📈 Análisis de Resultados:"
    echo "---"
    
    TOTAL=$(grep -c "Request" $RESULT_FILE)
    SUCCESS=$(grep -c "200" $RESULT_FILE)
    THROTTLED=$(grep -c "429" $RESULT_FILE)
    ERRORS=$(grep -c "500\|502\|503\|504" $RESULT_FILE)
    
    echo "Total Requests: $TOTAL"
    echo "Successful (200): $SUCCESS ($(( SUCCESS * 100 / TOTAL ))%)"
    echo "Throttled (429): $THROTTLED ($(( THROTTLED * 100 / TOTAL ))%)"
    echo "Errors (5xx): $ERRORS ($(( ERRORS * 100 / TOTAL ))%)"
    
    # Latencia promedio
    AVG_TIME=$(grep "Request" $RESULT_FILE | cut -d'|' -f2 | cut -d's' -f1 | \
               awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; }')
    echo "Latencia promedio: ${AVG_TIME}s"
    
    echo ""
    echo "📊 Revisar métricas en CloudWatch:"
    echo "   aws cloudwatch get-metric-statistics \\"
    echo "     --namespace AWS/ApiGateway \\"
    echo "     --metric-name Count \\"
    echo "     --dimensions Name=ApiName,Value=hospital-boxes-api-dev \\"
    echo "     --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \\"
    echo "     --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \\"
    echo "     --period 60 \\"
    echo "     --statistics Sum"
fi

echo "═══════════════════════════════════════════════════"
echo "✅ Experimento completado"
echo "═══════════════════════════════════════════════════"
