#!/bin/bash
# ════════════════════════════════════════════════════════════════
# Experimento 4: Simulación de DynamoDB Throttling
# ════════════════════════════════════════════════════════════════
# 
# OBJETIVO: Simular throttling de DynamoDB mediante carga masiva
# DURACIÓN: 3 minutos
# MÉTODO: Requests concurrentes para forzar límites de capacidad

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
    exit 1
fi

if [ -z "$API_ENDPOINT" ]; then
    echo "❌ Error: API_ENDPOINT no disponible"
    exit 1
fi

# ═══════════════════════════════════════════════════════════════
# Configuración
# ═══════════════════════════════════════════════════════════════

EXPERIMENT_NAME="DynamoDB Throttling Simulation"
ENDPOINT="/api/boxes"
REQUESTS=800
CONCURRENT=50

TOKEN="$JWT_TOKEN"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ═══════════════════════════════════════════════════════════════
# Funciones
# ═══════════════════════════════════════════════════════════════

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ═══════════════════════════════════════════════════════════════
# Header
# ═══════════════════════════════════════════════════════════════

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "   EXPERIMENTO 4: $EXPERIMENT_NAME"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📊 Configuración:"
echo "   - API: $API_ENDPOINT$ENDPOINT"
echo "   - Total requests: $REQUESTS"
echo "   - Concurrent: $CONCURRENT"
echo "   - Método: Carga masiva para forzar throttling"
echo ""

# ═══════════════════════════════════════════════════════════════
# Crear directorio de resultados
# ═══════════════════════════════════════════════════════════════

RESULTS_DIR="$SCRIPT_DIR/../results"
mkdir -p "$RESULTS_DIR"
RESULT_FILE="$RESULTS_DIR/dynamodb-throttling-$(date +%Y%m%d-%H%M%S).log"

echo "DynamoDB Throttling Test - $(date)" > "$RESULT_FILE"
echo "API: $API_ENDPOINT$ENDPOINT" >> "$RESULT_FILE"
echo "Total Requests: $REQUESTS" >> "$RESULT_FILE"
echo "Concurrent: $CONCURRENT" >> "$RESULT_FILE"
echo "---" >> "$RESULT_FILE"

# ═══════════════════════════════════════════════════════════════
# Función para enviar requests
# ═══════════════════════════════════════════════════════════════

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

# ═══════════════════════════════════════════════════════════════
# Fase 1: Baseline (10 requests)
# ═══════════════════════════════════════════════════════════════

echo ""
log_info "Fase 1: Estableciendo baseline..."

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

log_success "Baseline completado"

# ═══════════════════════════════════════════════════════════════
# Fase 2: Carga masiva para forzar throttling
# ═══════════════════════════════════════════════════════════════

echo ""
log_info "Fase 2: Carga masiva ($REQUESTS requests, $CONCURRENT concurrentes)..."

echo "" >> "$RESULT_FILE"
echo "Load Test ($REQUESTS requests, $CONCURRENT concurrent)" >> "$RESULT_FILE"
echo "---" >> "$RESULT_FILE"

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
log_success "Carga masiva completada"

# ═══════════════════════════════════════════════════════════════
# Fase 3: Análisis de resultados
# ═══════════════════════════════════════════════════════════════

echo ""
log_info "Fase 3: Analizando resultados..."

# Contar respuestas
TOTAL=$(grep -c "^Request" "$RESULT_FILE" 2>/dev/null || echo "0")
SUCCESS=$(grep -c ": 200 |" "$RESULT_FILE" 2>/dev/null || echo "0")
THROTTLED=$(grep -c ": 429 |" "$RESULT_FILE" 2>/dev/null || echo "0")
ERRORS=$(grep -cE ": (4[0-9]{2}|5[0-9]{2}) \|" "$RESULT_FILE" 2>/dev/null || echo "0")

# Limpiar variables
TOTAL=$(echo "$TOTAL" | tr -d '\n' | tr -d '[:space:]')
SUCCESS=$(echo "$SUCCESS" | tr -d '\n' | tr -d '[:space:]')
THROTTLED=$(echo "$THROTTLED" | tr -d '\n' | tr -d '[:space:]')
ERRORS=$(echo "$ERRORS" | tr -d '\n' | tr -d '[:space:]')

TOTAL=${TOTAL//[^0-9]/}
SUCCESS=${SUCCESS//[^0-9]/}
THROTTLED=${THROTTLED//[^0-9]/}
ERRORS=${ERRORS//[^0-9]/}

TOTAL=${TOTAL:-0}
SUCCESS=${SUCCESS:-0}
THROTTLED=${THROTTLED:-0}
ERRORS=${ERRORS:-0}

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "   📊 RESULTADOS DEL EXPERIMENTO"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📈 Estadísticas de Requests:"
if [ "$TOTAL" -gt 0 ]; then
    echo "   Total enviados: $TOTAL"
    echo "   Exitosos (200): $SUCCESS ($(( SUCCESS * 100 / TOTAL ))%)"
    echo "   Throttling (429): $THROTTLED ($(( THROTTLED * 100 / TOTAL ))%)"
    echo "   Otros errores: $ERRORS ($(( ERRORS * 100 / TOTAL ))%)"
    echo ""
    
    if [ "$THROTTLED" -gt 0 ]; then
        log_success "✅ Throttling detectado - Sistema bajo presión de DynamoDB"
    elif [ "$SUCCESS" -gt $(( TOTAL * 80 / 100 )) ]; then
        log_success "✅ Sistema manejó bien la carga (>80% exitosos)"
    else
        log_warning "⚠️  Sistema tuvo problemas bajo carga (<80% exitosos)"
    fi
fi

echo ""
log_success "Resultados guardados en: $RESULT_FILE"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "   ✅ EXPERIMENTO COMPLETADO"
echo "════════════════════════════════════════════════════════════════"
echo ""
