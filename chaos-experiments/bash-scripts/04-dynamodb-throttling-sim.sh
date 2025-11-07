#!/bin/bash
# ════════════════════════════════════════════════════════════════
# Experimento 4: Simulación de DynamoDB Throttling
# ════════════════════════════════════════════════════════════════
# 
# OBJETIVO: Simular throttling de DynamoDB mediante carga masiva
# DURACIÓN: 5 minutos
# MÉTODO: Requests concurrentes para forzar límites de capacidad
#

set -e

# ═══════════════════════════════════════════════════════════════
# Configuración
# ═══════════════════════════════════════════════════════════════

EXPERIMENT_NAME="DynamoDB Throttling Simulation"
DURATION_MINUTES=5
CONCURRENT_REQUESTS=50
REQUEST_INTERVAL=0.1  # segundos entre oleadas

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
echo "   Duración: $DURATION_MINUTES minutos"
echo "   Requests concurrentes: $CONCURRENT_REQUESTS"
echo "   Método: Carga masiva para forzar throttling"
echo ""

# ═══════════════════════════════════════════════════════════════
# Obtener JWT y API URL
# ═══════════════════════════════════════════════════════════════

log_info "Obteniendo configuración..."

# JWT Token
if [ -f "get-jwt-from-secrets.sh" ]; then
    JWT_TOKEN=$(./get-jwt-from-secrets.sh 2>/dev/null || echo "")
fi

if [ -z "$JWT_TOKEN" ] && [ -f ".env" ]; then
    JWT_TOKEN=$(grep JWT_TOKEN .env | cut -d'=' -f2)
fi

if [ -z "$JWT_TOKEN" ]; then
    log_error "JWT Token no encontrado"
    echo "Ejecuta: ./setup-jwt-secrets-manager.sh"
    exit 1
fi

# API Endpoint
AWS_REGION=$(aws configure get region || echo "us-east-1")
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")

# Auto-detectar API Gateway
API_GATEWAY_ID=$(aws apigateway get-rest-apis \
    --query 'items[?name==`dev-serverless-api`].id' \
    --output text 2>/dev/null | head -n1)

if [ -z "$API_GATEWAY_ID" ]; then
    API_GATEWAY_ID=$(aws apigateway get-rest-apis \
        --query 'items[0].id' \
        --output text 2>/dev/null | head -n1)
fi

if [ -n "$API_GATEWAY_ID" ]; then
    API_ENDPOINT="https://${API_GATEWAY_ID}.execute-api.${AWS_REGION}.amazonaws.com/dev/api"
else
    log_warning "No se pudo auto-detectar API Gateway, usando .env"
    API_ENDPOINT=$(grep API_ENDPOINT .env 2>/dev/null | cut -d'=' -f2 || echo "")
fi

if [ -z "$API_ENDPOINT" ]; then
    log_error "API_ENDPOINT no configurado"
    exit 1
fi

log_success "Configuración obtenida"
echo "   API: $API_ENDPOINT"

# ═══════════════════════════════════════════════════════════════
# Fase 1: Baseline (30 segundos)
# ═══════════════════════════════════════════════════════════════

echo ""
log_info "Fase 1: Estableciendo baseline (30s)..."

BASELINE_START=$(date +%s)
BASELINE_SUCCESS=0
BASELINE_ERRORS=0

for i in {1..10}; do
    RESPONSE=$(curl -s -w "\n%{http_code}" \
        -X GET "$API_ENDPOINT/boxes" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -H "Content-Type: application/json" \
        --max-time 10 2>&1)
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        ((BASELINE_SUCCESS++))
    else
        ((BASELINE_ERRORS++))
    fi
    
    sleep 1
done

BASELINE_END=$(date +%s)
BASELINE_DURATION=$((BASELINE_END - BASELINE_START))

log_success "Baseline completado"
echo "   Requests exitosos: $BASELINE_SUCCESS/10"
echo "   Requests fallidos: $BASELINE_ERRORS/10"
echo "   Duración: ${BASELINE_DURATION}s"

# ═══════════════════════════════════════════════════════════════
# Fase 2: Inyección de Carga (5 minutos)
# ═══════════════════════════════════════════════════════════════

echo ""
log_info "Fase 2: Inyectando carga masiva (${DURATION_MINUTES} min)..."
echo "   Se generarán $CONCURRENT_REQUESTS requests concurrentes cada ${REQUEST_INTERVAL}s"
echo ""

CHAOS_START=$(date +%s)
CHAOS_END=$((CHAOS_START + DURATION_MINUTES * 60))

TOTAL_REQUESTS=0
SUCCESS_REQUESTS=0
ERROR_REQUESTS=0
THROTTLE_ERRORS=0
TIMEOUT_ERRORS=0
RESPONSE_TIMES=()

mkdir -p results/04-dynamodb-throttling

while [ $(date +%s) -lt $CHAOS_END ]; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - CHAOS_START))
    REMAINING=$((CHAOS_END - CURRENT_TIME))
    
    # Progress bar
    PROGRESS=$((ELAPSED * 100 / (DURATION_MINUTES * 60)))
    echo -ne "\r   Progreso: [$PROGRESS%] | Elapsed: ${ELAPSED}s | Remaining: ${REMAINING}s | Requests: $TOTAL_REQUESTS | Throttles: $THROTTLE_ERRORS   "
    
    # Lanzar oleada de requests concurrentes
    for i in $(seq 1 $CONCURRENT_REQUESTS); do
        {
            START_TIME=$(date +%s%3N)  # milliseconds
            
            RESPONSE=$(curl -s -w "\n%{http_code}" \
                -X GET "$API_ENDPOINT/boxes" \
                -H "Authorization: Bearer $JWT_TOKEN" \
                -H "Content-Type: application/json" \
                --max-time 5 2>&1)
            
            END_TIME=$(date +%s%3N)
            RESPONSE_TIME=$((END_TIME - START_TIME))
            
            HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
            BODY=$(echo "$RESPONSE" | head -n -1)
            
            # Registrar resultado
            echo "$CURRENT_TIME,$HTTP_CODE,$RESPONSE_TIME" >> results/04-dynamodb-throttling/requests.csv
            
            if [ "$HTTP_CODE" = "200" ]; then
                echo "success" >> results/04-dynamodb-throttling/status.log
            elif [ "$HTTP_CODE" = "429" ] || echo "$BODY" | grep -qi "throttl\|rate limit"; then
                echo "throttle" >> results/04-dynamodb-throttling/status.log
            elif [ "$HTTP_CODE" = "000" ] || [ -z "$HTTP_CODE" ]; then
                echo "timeout" >> results/04-dynamodb-throttling/status.log
            else
                echo "error" >> results/04-dynamodb-throttling/status.log
            fi
        } &
    done
    
    # Esperar a que terminen los requests de esta oleada
    wait
    
    # Actualizar contadores
    TOTAL_REQUESTS=$((TOTAL_REQUESTS + CONCURRENT_REQUESTS))
    SUCCESS_REQUESTS=$(grep -c "success" results/04-dynamodb-throttling/status.log 2>/dev/null || echo 0)
    THROTTLE_ERRORS=$(grep -c "throttle" results/04-dynamodb-throttling/status.log 2>/dev/null || echo 0)
    TIMEOUT_ERRORS=$(grep -c "timeout" results/04-dynamodb-throttling/status.log 2>/dev/null || echo 0)
    ERROR_REQUESTS=$(grep -c "error" results/04-dynamodb-throttling/status.log 2>/dev/null || echo 0)
    
    sleep $REQUEST_INTERVAL
done

echo ""  # Nueva línea después del progress bar
log_success "Carga masiva completada"

# ═══════════════════════════════════════════════════════════════
# Fase 3: Recuperación (30 segundos)
# ═══════════════════════════════════════════════════════════════

echo ""
log_info "Fase 3: Verificando recuperación del sistema (30s)..."

sleep 10  # Esperar a que el sistema se estabilice

RECOVERY_SUCCESS=0
RECOVERY_ERRORS=0

for i in {1..10}; do
    RESPONSE=$(curl -s -w "\n%{http_code}" \
        -X GET "$API_ENDPOINT/boxes" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -H "Content-Type: application/json" \
        --max-time 10 2>&1)
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        ((RECOVERY_SUCCESS++))
    else
        ((RECOVERY_ERRORS++))
    fi
    
    sleep 2
done

log_success "Verificación de recuperación completada"
echo "   Requests exitosos: $RECOVERY_SUCCESS/10"
echo "   Requests fallidos: $RECOVERY_ERRORS/10"

# ═══════════════════════════════════════════════════════════════
# Análisis de Resultados
# ═══════════════════════════════════════════════════════════════

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "   📊 RESULTADOS DEL EXPERIMENTO"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Calcular métricas
THROTTLE_RATE=$(echo "scale=2; $THROTTLE_ERRORS * 100 / $TOTAL_REQUESTS" | bc 2>/dev/null || echo "0")
ERROR_RATE=$(echo "scale=2; $ERROR_REQUESTS * 100 / $TOTAL_REQUESTS" | bc 2>/dev/null || echo "0")
SUCCESS_RATE=$(echo "scale=2; $SUCCESS_REQUESTS * 100 / $TOTAL_REQUESTS" | bc 2>/dev/null || echo "0")

echo "📈 Estadísticas de Requests:"
echo "   Total enviados: $TOTAL_REQUESTS"
echo "   Exitosos (200): $SUCCESS_REQUESTS ($SUCCESS_RATE%)"
echo "   Throttling: $THROTTLE_ERRORS ($THROTTLE_RATE%)"
echo "   Timeouts: $TIMEOUT_ERRORS"
echo "   Otros errores: $ERROR_REQUESTS ($ERROR_RATE%)"
echo ""

echo "🔄 Comparación Baseline vs Chaos:"
echo "   Baseline success rate: $((BASELINE_SUCCESS * 10))%"
echo "   Chaos success rate: $SUCCESS_RATE%"
echo "   Recovery success rate: $((RECOVERY_SUCCESS * 10))%"
echo ""

# Evaluar resultado
if (( $(echo "$THROTTLE_RATE > 10" | bc -l) )); then
    log_success "✅ Throttling detectado ($THROTTLE_RATE%) - Sistema bajo presión"
else
    log_warning "⚠️  Poco throttling ($THROTTLE_RATE%) - Posible capacidad sobredimensionada"
fi

if [ $RECOVERY_SUCCESS -ge 8 ]; then
    log_success "✅ Sistema se recuperó exitosamente"
else
    log_warning "⚠️  Sistema con problemas de recuperación"
fi

# ═══════════════════════════════════════════════════════════════
# Guardar Reporte
# ═══════════════════════════════════════════════════════════════

REPORT_FILE="results/04-dynamodb-throttling/REPORT.md"

cat > "$REPORT_FILE" << EOF
# Experimento 4: DynamoDB Throttling Simulation

## 📋 Información del Experimento

- **Fecha:** $(date '+%Y-%m-%d %H:%M:%S')
- **Duración:** $DURATION_MINUTES minutos
- **Método:** Carga masiva concurrente
- **Requests concurrentes:** $CONCURRENT_REQUESTS

## 📊 Resultados

### Métricas Generales
- Total requests: $TOTAL_REQUESTS
- Requests exitosos: $SUCCESS_REQUESTS ($SUCCESS_RATE%)
- Throttling errors: $THROTTLE_ERRORS ($THROTTLE_RATE%)
- Timeout errors: $TIMEOUT_ERRORS
- Otros errores: $ERROR_REQUESTS ($ERROR_RATE%)

### Comparación de Fases
| Fase | Success Rate |
|------|--------------|
| Baseline | $((BASELINE_SUCCESS * 10))% |
| Chaos | $SUCCESS_RATE% |
| Recovery | $((RECOVERY_SUCCESS * 10))% |

## 🎯 Hallazgos

1. **Throttling Detectado:** $THROTTLE_RATE% de requests throttled
2. **Recuperación:** Sistema se recuperó con $((RECOVERY_SUCCESS * 10))% de éxito
3. **Resiliencia:** $([ $RECOVERY_SUCCESS -ge 8 ] && echo "✅ Alta" || echo "⚠️ Mejorable")

## 💡 Recomendaciones

$(if (( $(echo "$THROTTLE_RATE > 20" | bc -l) )); then
    echo "- ⚠️ Considerar aumentar capacidad de DynamoDB"
    echo "- ✅ Circuit breaker debería activarse con este nivel de throttling"
fi)

$(if [ $RECOVERY_SUCCESS -lt 8 ]; then
    echo "- ⚠️ Mejorar mecanismos de recuperación"
    echo "- 💡 Implementar retry con exponential backoff"
fi)

- ✅ Monitorear métricas de DynamoDB en CloudWatch
- ✅ Configurar alarmas para throttling > 5%

## 📁 Archivos Generados

- \`requests.csv\` - Log de todos los requests
- \`status.log\` - Status de cada request
- \`REPORT.md\` - Este reporte

EOF

log_success "Reporte guardado en: $REPORT_FILE"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "   ✅ EXPERIMENTO COMPLETADO"
echo "════════════════════════════════════════════════════════════════"
echo ""
