#!/bin/bash
# Chaos Experiment 2: Lambda Latency Injection
# Objetivo: Simular latencia alta en Lambda functions mediante carga

echo "═══════════════════════════════════════════════════"
echo "🔥 CHAOS EXPERIMENT: Lambda Latency Injection"
echo "═══════════════════════════════════════════════════"

# Obtener directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

# Cargar variables de entorno desde .env si no están exportadas
if [ -z "$JWT_TOKEN" ] || [ -z "$API_ENDPOINT" ]; then
    if [ -f "$ENV_FILE" ]; then
        echo "📄 Cargando variables desde .env..."
        export $(cat "$ENV_FILE" | grep -v '^#' | grep -v '^$' | xargs)
    fi
fi

# Validar variables requeridas
if [ -z "$JWT_TOKEN" ]; then
    echo "❌ Error: JWT_TOKEN no disponible"
    echo "   Ejecuta primero: ./run-all-chaos-experiments.sh"
    echo "   O manualmente: ../get-cognito-jwt.sh"
    exit 1
fi

if [ -z "$API_ENDPOINT" ]; then
    echo "❌ Error: API_ENDPOINT no disponible"
    echo "   Ejecuta primero: ./run-all-chaos-experiments.sh"
    exit 1
fi

# Configuración
ENDPOINT="/api/boxes"
REQUESTS=500
CONCURRENT=30
LATENCY_MS=2000  # Simular latencia mediante carga concurrente

TOKEN="$JWT_TOKEN"

echo ""
echo "⚙️  Configuración:"
echo "   - API: $API_ENDPOINT$ENDPOINT"
echo "   - Total requests: $REQUESTS"
echo "   - Concurrent: $CONCURRENT"
echo "   - Objetivo: Medir degradación de latencia bajo carga"
echo ""

# 1. Baseline sin carga
echo ""
echo "📊 PASO 1: Baseline (latencia normal)"
echo "---"

# Crear directorio de resultados si no existe
RESULTS_DIR="$SCRIPT_DIR/../results"
mkdir -p "$RESULTS_DIR"

RESULT_FILE="$RESULTS_DIR/lambda-latency-$(date +%Y%m%d-%H%M%S).log"
echo "Lambda Latency Test - $(date)" > "$RESULT_FILE"
echo "Baseline (10 requests secuenciales)" >> "$RESULT_FILE"
echo "---" >> "$RESULT_FILE"

for i in {1..10}; do
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\nTIME:%{time_total}" \
        --max-time 10 --connect-timeout 5 \
        "$API_ENDPOINT$ENDPOINT" \
        -H "Authorization: Bearer $TOKEN" 2>&1)
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "^HTTP_CODE:" | cut -d':' -f2)
    TIME=$(echo "$RESPONSE" | grep "^TIME:" | cut -d':' -f2)
    
    echo "  Request $i: Status=$HTTP_CODE | Time=${TIME}s"
    echo "Baseline-$i: $HTTP_CODE | ${TIME}s" >> "$RESULT_FILE"
done

AVG_BASELINE=$(grep "^Baseline-" "$RESULT_FILE" | cut -d'|' -f2 | tr -d 's ' | \
               awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; }')
echo ""
echo "✅ Latencia baseline promedio: ${AVG_BASELINE}s"

# 2. Carga concurrente para inducir latencia
echo ""
echo "💉 PASO 2: Carga concurrente (simular latencia)"
echo "---"
echo "💥 Enviando $REQUESTS requests con $CONCURRENT concurrentes..."

echo "" >> "$RESULT_FILE"
echo "Load Test ($REQUESTS requests, $CONCURRENT concurrent)" >> "$RESULT_FILE"
echo "---" >> "$RESULT_FILE"

send_request() {
    local id=$1
    local output_file=$2
    
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\nTIME:%{time_total}" \
        --max-time 10 --connect-timeout 5 \
        "$API_ENDPOINT$ENDPOINT" \
        -H "Authorization: Bearer $TOKEN" 2>&1)
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "^HTTP_CODE:" | cut -d':' -f2)
    TIME=$(echo "$RESPONSE" | grep "^TIME:" | cut -d':' -f2)
    
    echo "Request $id: $HTTP_CODE | ${TIME}s" >> "$output_file"
}

# Enviar requests en paralelo
for i in $(seq 1 $REQUESTS); do
    send_request $i "$RESULT_FILE" &
    
    # Controlar concurrencia
    if [ $((i % CONCURRENT)) -eq 0 ]; then
        wait
        echo "  Progress: $i/$REQUESTS requests enviados..."
    fi
done

wait
echo "  ⏳ Todos los requests completados"

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

# 3. Analizar resultados
echo ""
echo "📊 PASO 3: Análisis de resultados"
echo "---"

# Contar respuestas
TOTAL=$(grep -c "^Request" "$RESULT_FILE" 2>/dev/null || echo "0")
SUCCESS=$(grep -c ": 200 |" "$RESULT_FILE" 2>/dev/null || echo "0")
ERRORS=$(grep -cE ": (4[0-9]{2}|5[0-9]{2}) \|" "$RESULT_FILE" 2>/dev/null || echo "0")
TIMEOUTS=$(grep -c "TIMEOUT" "$RESULT_FILE" 2>/dev/null || echo "0")

# Limpiar variables
TOTAL=$(echo "$TOTAL" | tr -d '\n' | tr -d '[:space:]')
SUCCESS=$(echo "$SUCCESS" | tr -d '\n' | tr -d '[:space:]')
ERRORS=$(echo "$ERRORS" | tr -d '\n' | tr -d '[:space:]')
TIMEOUTS=$(echo "$TIMEOUTS" | tr -d '\n' | tr -d '[:space:]')

# Validar números
TOTAL=${TOTAL//[^0-9]/}
SUCCESS=${SUCCESS//[^0-9]/}
ERRORS=${ERRORS//[^0-9]/}
TIMEOUTS=${TIMEOUTS//[^0-9]/}

TOTAL=${TOTAL:-0}
SUCCESS=${SUCCESS:-0}
ERRORS=${ERRORS:-0}
TIMEOUTS=${TIMEOUTS:-0}

# Calcular latencias
AVG_LOAD=$(grep "^Request" "$RESULT_FILE" | grep ": 200 |" | cut -d'|' -f2 | tr -d 's ' | \
           awk '{ sum += $1; n++ } END { if (n > 0) printf "%.3f", sum / n; else print "N/A" }')

P95_LOAD=$(grep "^Request" "$RESULT_FILE" | grep ": 200 |" | cut -d'|' -f2 | tr -d 's ' | \
           sort -n | awk '{times[NR]=$1} END {print times[int(NR*0.95)]}')

echo ""
echo "✅ Experimento completado"
echo "📊 Resultados guardados en: $RESULT_FILE"
echo ""
echo "📈 Análisis de Resultados:"
echo "---"

if [ "$TOTAL" -gt 0 ]; then
    echo "Total Requests: $TOTAL"
    echo "Successful (200): $SUCCESS ($(( SUCCESS * 100 / TOTAL ))%)"
    echo "Errors (4xx/5xx): $ERRORS ($(( ERRORS * 100 / TOTAL ))%)"
    echo "Timeouts: $TIMEOUTS ($(( TIMEOUTS * 100 / TOTAL ))%)"
    echo ""
    echo "Latencia baseline: ${AVG_BASELINE}s"
    echo "Latencia bajo carga: ${AVG_LOAD}s"
    echo "P95 bajo carga: ${P95_LOAD}s"
    echo ""
    
    # Calcular degradación
    if [[ "$AVG_BASELINE" != "N/A" ]] && [[ "$AVG_LOAD" != "N/A" ]]; then
        DEGRADATION=$(echo "$AVG_LOAD $AVG_BASELINE" | awk '{printf "%.1f", ($1 - $2) / $2 * 100}')
        echo "Degradación de latencia: ${DEGRADATION}%"
        echo ""
        
        if (( $(echo "$DEGRADATION > 50" | bc -l) )); then
            echo "⚠️  Alta degradación de latencia bajo carga"
        elif (( $(echo "$DEGRADATION > 20" | bc -l) )); then
            echo "� Degradación moderada de latencia"
        else
            echo "✅ Sistema mantiene buen rendimiento bajo carga"
        fi
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════"
echo "✅ Experimento completado"
echo "═══════════════════════════════════════════════════"
