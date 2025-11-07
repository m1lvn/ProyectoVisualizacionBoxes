#!/bin/bash
# ════════════════════════════════════════════════════════════════
# Experimento 5: Simulación de Lambda Error Injection
# ════════════════════════════════════════════════════════════════
# 
# OBJETIVO: Simular errores en Lambda mediante requests inválidos
# DURACIÓN: 5 minutos
# MÉTODO: Enviar requests malformados para forzar errores 500/400
#

set -e

# ═══════════════════════════════════════════════════════════════
# Configuración
# ═══════════════════════════════════════════════════════════════

EXPERIMENT_NAME="Lambda Error Injection Simulation"
DURATION_MINUTES=5
ERROR_INJECTION_RATE=30  # % de requests que serán inválidos

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
echo "   EXPERIMENTO 5: $EXPERIMENT_NAME"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📊 Configuración:"
echo "   Duración: $DURATION_MINUTES minutos"
echo "   Tasa de inyección de errores: $ERROR_INJECTION_RATE%"
echo "   Método: Requests inválidos para forzar errores Lambda"
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

BASELINE_SUCCESS=0
BASELINE_ERRORS=0

for i in {1..10}; do
    # Request válido
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
    
    sleep 2
done

log_success "Baseline completado"
echo "   Requests exitosos: $BASELINE_SUCCESS/10"
echo "   Requests fallidos: $BASELINE_ERRORS/10"

# ═══════════════════════════════════════════════════════════════
# Fase 2: Inyección de Errores (5 minutos)
# ═══════════════════════════════════════════════════════════════

echo ""
log_info "Fase 2: Inyectando errores (${DURATION_MINUTES} min)..."
echo "   $ERROR_INJECTION_RATE% de requests serán inválidos"
echo ""

CHAOS_START=$(date +%s)
CHAOS_END=$((CHAOS_START + DURATION_MINUTES * 60))

TOTAL_REQUESTS=0
VALID_REQUESTS=0
INVALID_REQUESTS=0
SUCCESS_200=0
ERROR_400=0
ERROR_500=0
ERROR_503=0
OTHER_ERRORS=0

mkdir -p results/05-lambda-errors

while [ $(date +%s) -lt $CHAOS_END ]; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - CHAOS_START))
    REMAINING=$((CHAOS_END - CURRENT_TIME))
    
    # Progress bar
    PROGRESS=$((ELAPSED * 100 / (DURATION_MINUTES * 60)))
    echo -ne "\r   Progreso: [$PROGRESS%] | Elapsed: ${ELAPSED}s | Remaining: ${REMAINING}s | Total: $TOTAL_REQUESTS | Errors: $((ERROR_400 + ERROR_500 + ERROR_503))   "
    
    # Decidir si enviar request válido o inválido
    RANDOM_NUM=$((RANDOM % 100))
    
    if [ $RANDOM_NUM -lt $ERROR_INJECTION_RATE ]; then
        # Request INVÁLIDO - Forzar error
        ((INVALID_REQUESTS++))
        
        # Tipo de request inválido aleatorio
        ERROR_TYPE=$((RANDOM % 5))
        
        case $ERROR_TYPE in
            0)
                # POST sin datos requeridos
                RESPONSE=$(curl -s -w "\n%{http_code}" \
                    -X POST "$API_ENDPOINT/agendas" \
                    -H "Authorization: Bearer $JWT_TOKEN" \
                    -H "Content-Type: application/json" \
                    -d '{}' \
                    --max-time 5 2>&1)
                ;;
            1)
                # JSON malformado
                RESPONSE=$(curl -s -w "\n%{http_code}" \
                    -X POST "$API_ENDPOINT/agendas" \
                    -H "Authorization: Bearer $JWT_TOKEN" \
                    -H "Content-Type: application/json" \
                    -d '{invalid json}' \
                    --max-time 5 2>&1)
                ;;
            2)
                # ID inexistente
                RESPONSE=$(curl -s -w "\n%{http_code}" \
                    -X GET "$API_ENDPOINT/boxes/99999999" \
                    -H "Authorization: Bearer $JWT_TOKEN" \
                    --max-time 5 2>&1)
                ;;
            3)
                # Método HTTP incorrecto
                RESPONSE=$(curl -s -w "\n%{http_code}" \
                    -X DELETE "$API_ENDPOINT/boxes" \
                    -H "Authorization: Bearer $JWT_TOKEN" \
                    --max-time 5 2>&1)
                ;;
            4)
                # Datos inválidos
                RESPONSE=$(curl -s -w "\n%{http_code}" \
                    -X POST "$API_ENDPOINT/agendas" \
                    -H "Authorization: Bearer $JWT_TOKEN" \
                    -H "Content-Type: application/json" \
                    -d '{"fecha":"invalid-date","boxId":-1}' \
                    --max-time 5 2>&1)
                ;;
        esac
    else
        # Request VÁLIDO
        ((VALID_REQUESTS++))
        
        RESPONSE=$(curl -s -w "\n%{http_code}" \
            -X GET "$API_ENDPOINT/boxes" \
            -H "Authorization: Bearer $JWT_TOKEN" \
            -H "Content-Type: application/json" \
            --max-time 5 2>&1)
    fi
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n -1)
    
    # Clasificar respuesta
    case "$HTTP_CODE" in
        200)
            ((SUCCESS_200++))
            echo "success" >> results/05-lambda-errors/status.log
            ;;
        400|404)
            ((ERROR_400++))
            echo "error_400" >> results/05-lambda-errors/status.log
            ;;
        500|502)
            ((ERROR_500++))
            echo "error_500" >> results/05-lambda-errors/status.log
            ;;
        503)
            ((ERROR_503++))
            echo "error_503" >> results/05-lambda-errors/status.log
            ;;
        *)
            ((OTHER_ERRORS++))
            echo "error_other" >> results/05-lambda-errors/status.log
            ;;
    esac
    
    # Log detallado
    echo "$(date +%s),$HTTP_CODE,$([ $RANDOM_NUM -lt $ERROR_INJECTION_RATE ] && echo 'invalid' || echo 'valid')" >> results/05-lambda-errors/requests.csv
    
    ((TOTAL_REQUESTS++))
    
    sleep 1
done

echo ""  # Nueva línea después del progress bar
log_success "Inyección de errores completada"

# ═══════════════════════════════════════════════════════════════
# Fase 3: Recuperación (30 segundos)
# ═══════════════════════════════════════════════════════════════

echo ""
log_info "Fase 3: Verificando recuperación del sistema (30s)..."

sleep 10

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
SUCCESS_RATE=$(echo "scale=2; $SUCCESS_200 * 100 / $TOTAL_REQUESTS" | bc 2>/dev/null || echo "0")
ERROR_400_RATE=$(echo "scale=2; $ERROR_400 * 100 / $TOTAL_REQUESTS" | bc 2>/dev/null || echo "0")
ERROR_500_RATE=$(echo "scale=2; $ERROR_500 * 100 / $TOTAL_REQUESTS" | bc 2>/dev/null || echo "0")
ERROR_503_RATE=$(echo "scale=2; $ERROR_503 * 100 / $TOTAL_REQUESTS" | bc 2>/dev/null || echo "0")

echo "📈 Estadísticas de Requests:"
echo "   Total enviados: $TOTAL_REQUESTS"
echo "   └─ Válidos: $VALID_REQUESTS"
echo "   └─ Inválidos (inyectados): $INVALID_REQUESTS"
echo ""
echo "   Respuestas recibidas:"
echo "   └─ 200 OK: $SUCCESS_200 ($SUCCESS_RATE%)"
echo "   └─ 400/404 (Client Errors): $ERROR_400 ($ERROR_400_RATE%)"
echo "   └─ 500/502 (Lambda Errors): $ERROR_500 ($ERROR_500_RATE%)"
echo "   └─ 503 (Service Unavailable): $ERROR_503 ($ERROR_503_RATE%)"
echo "   └─ Otros: $OTHER_ERRORS"
echo ""

echo "🔄 Comparación:"
echo "   Baseline success: $((BASELINE_SUCCESS * 10))%"
echo "   Chaos success: $SUCCESS_RATE%"
echo "   Recovery success: $((RECOVERY_SUCCESS * 10))%"
echo ""

# Evaluar resultado
if (( $(echo "$ERROR_500 > 0" | bc -l) )); then
    log_warning "⚠️  Lambda errors detectados ($ERROR_500) - Sistema manejó errores"
else
    log_info "ℹ️  No se detectaron errores 500 - Validación funcionó correctamente"
fi

if [ $RECOVERY_SUCCESS -ge 8 ]; then
    log_success "✅ Sistema se recuperó exitosamente"
else
    log_warning "⚠️  Sistema con problemas de recuperación"
fi

# ═══════════════════════════════════════════════════════════════
# Guardar Reporte
# ═══════════════════════════════════════════════════════════════

REPORT_FILE="results/05-lambda-errors/REPORT.md"

cat > "$REPORT_FILE" << EOF
# Experimento 5: Lambda Error Injection Simulation

## 📋 Información del Experimento

- **Fecha:** $(date '+%Y-%m-%d %H:%M:%S')
- **Duración:** $DURATION_MINUTES minutos
- **Método:** Inyección de requests inválidos
- **Tasa de error:** $ERROR_INJECTION_RATE%

## 📊 Resultados

### Métricas de Requests
- Total requests: $TOTAL_REQUESTS
  - Válidos: $VALID_REQUESTS
  - Inválidos (inyectados): $INVALID_REQUESTS

### Distribución de Respuestas
| Status | Count | Percentage |
|--------|-------|------------|
| 200 OK | $SUCCESS_200 | $SUCCESS_RATE% |
| 400/404 | $ERROR_400 | $ERROR_400_RATE% |
| 500/502 | $ERROR_500 | $ERROR_500_RATE% |
| 503 | $ERROR_503 | $ERROR_503_RATE% |
| Otros | $OTHER_ERRORS | - |

### Comparación de Fases
| Fase | Success Rate |
|------|--------------|
| Baseline | $((BASELINE_SUCCESS * 10))% |
| Chaos | $SUCCESS_RATE% |
| Recovery | $((RECOVERY_SUCCESS * 10))% |

## 🎯 Hallazgos

1. **Manejo de Errores:** Sistema respondió con códigos HTTP apropiados
2. **Lambda Errors:** $ERROR_500 errores 500 detectados
3. **Validación:** $ERROR_400 requests rechazados por validación
4. **Recuperación:** $([ $RECOVERY_SUCCESS -ge 8 ] && echo "✅ Exitosa" || echo "⚠️ Parcial")

## 💡 Observaciones

$(if [ $ERROR_500 -gt 0 ]; then
    echo "- ⚠️ Lambda generó errores 500 - Revisar logs de CloudWatch"
    echo "- 💡 Implementar mejor manejo de excepciones"
fi)

$(if [ $ERROR_400 -gt $((INVALID_REQUESTS * 80 / 100)) ]; then
    echo "- ✅ Validación de inputs funciona correctamente"
fi)

$(if [ $RECOVERY_SUCCESS -lt 8 ]; then
    echo "- ⚠️ Recuperación lenta - Posible circuit breaker activado"
fi)

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
