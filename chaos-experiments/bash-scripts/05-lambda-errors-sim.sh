#!/bin/bash
# ════════════════════════════════════════════════════════════════
# Experimento 5: Simulación de Lambda Error Injection
# ════════════════════════════════════════════════════════════════
# 
# OBJETIVO: Simular errores en Lambda mediante requests inválidos
# DURACIÓN: 3 minutos
# MÉTODO: Enviar requests malformados para forzar errores 500/400

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

EXPERIMENT_NAME="Lambda Error Injection Simulation"
ENDPOINT="/api/agendas"
REQUESTS=300
ERROR_INJECTION_RATE=30  # % de requests que serán inválidos

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
echo "   EXPERIMENTO 5: $EXPERIMENT_NAME"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📊 Configuración:"
echo "   - API: $API_ENDPOINT$ENDPOINT"
echo "   - Total requests: $REQUESTS"
echo "   - Tasa de inyección de errores: $ERROR_INJECTION_RATE%"
echo "   - Método: Requests inválidos para forzar errores Lambda"
echo ""

# ═══════════════════════════════════════════════════════════════
# Crear directorio de resultados
# ═══════════════════════════════════════════════════════════════

RESULTS_DIR="$SCRIPT_DIR/../results"
mkdir -p "$RESULTS_DIR"
RESULT_FILE="$RESULTS_DIR/lambda-errors-$(date +%Y%m%d-%H%M%S).log"
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
# Fase 2: Inyección de Errores
# ═══════════════════════════════════════════════════════════════

echo ""
log_info "Fase 2: Inyectando errores..."
echo "   $ERROR_INJECTION_RATE% de requests serán inválidos"
echo "   Total requests a enviar: $REQUESTS"
echo ""

read -p "🚨 ¿Iniciar test de error injection? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
    echo ""
    log_info "💥 Iniciando test de inyección de errores..."
    echo "⏱️  Timestamp: $(date)"
    
    VALID_COUNT=0
    INVALID_COUNT=0
    
    for i in $(seq 1 $REQUESTS); do
        # Decidir si enviar request válido o inválido (basado en ERROR_INJECTION_RATE%)
        RANDOM_NUM=$((RANDOM % 100))
        
        if [ $RANDOM_NUM -lt $ERROR_INJECTION_RATE ]; then
            # Request INVÁLIDO
            ((INVALID_COUNT++))
            
            # Tipo de error aleatorio
            ERROR_TYPE=$((RANDOM % 5))
            
            case $ERROR_TYPE in
                0)
                    # POST sin datos requeridos
                    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\nTIME:%{time_total}" \
                        --max-time 5 --connect-timeout 3 \
                        -X POST "$API_ENDPOINT$ENDPOINT" \
                        -H "Authorization: Bearer $TOKEN" \
                        -H "Content-Type: application/json" \
                        -d '{}' 2>&1)
                    ;;
                1)
                    # JSON malformado
                    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\nTIME:%{time_total}" \
                        --max-time 5 --connect-timeout 3 \
                        -X POST "$API_ENDPOINT$ENDPOINT" \
                        -H "Authorization: Bearer $TOKEN" \
                        -H "Content-Type: application/json" \
                        -d '{invalid json' 2>&1)
                    ;;
                2)
                    # ID inexistente
                    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\nTIME:%{time_total}" \
                        --max-time 5 --connect-timeout 3 \
                        -X GET "$API_ENDPOINT/boxes/99999999" \
                        -H "Authorization: Bearer $TOKEN" 2>&1)
                    ;;
                3)
                    # Método HTTP no permitido
                    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\nTIME:%{time_total}" \
                        --max-time 5 --connect-timeout 3 \
                        -X DELETE "$API_ENDPOINT/boxes" \
                        -H "Authorization: Bearer $TOKEN" 2>&1)
                    ;;
                4)
                    # Datos inválidos
                    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\nTIME:%{time_total}" \
                        --max-time 5 --connect-timeout 3 \
                        -X POST "$API_ENDPOINT$ENDPOINT" \
                        -H "Authorization: Bearer $TOKEN" \
                        -H "Content-Type: application/json" \
                        -d '{"fecha":"invalid-date","boxId":-1}' 2>&1)
                    ;;
            esac
        else
            # Request VÁLIDO
            ((VALID_COUNT++))
            
            RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\nTIME:%{time_total}" \
                --max-time 5 --connect-timeout 3 \
                -X GET "$API_ENDPOINT/boxes" \
                -H "Authorization: Bearer $TOKEN" 2>&1)
        fi
        
        EXIT_CODE=$?
        
        if [ $EXIT_CODE -eq 0 ]; then
            HTTP_CODE=$(echo "$RESPONSE" | grep "^HTTP_CODE:" | cut -d':' -f2 | tr -d ' ')
            TIME=$(echo "$RESPONSE" | grep "^TIME:" | cut -d':' -f2 | tr -d ' ')
            
            if [ -z "$HTTP_CODE" ]; then
                HTTP_CODE="ERROR"
                TIME="0"
            fi
        else
            if [ $EXIT_CODE -eq 28 ]; then
                HTTP_CODE="TIMEOUT"
            else
                HTTP_CODE="CURL_ERROR_$EXIT_CODE"
            fi
            TIME="0"
        fi
        
        echo "Request $i: $HTTP_CODE | ${TIME}s" >> "$RESULT_FILE"
        
        if [ $(($i % 50)) -eq 0 ]; then
            echo "  Progress: $i/$REQUESTS requests (Válidos: $VALID_COUNT, Inválidos: $INVALID_COUNT)"
        fi
    done
    
    echo ""
    log_success "✅ Test completado"
    echo "   Requests válidos enviados: $VALID_COUNT"
    echo "   Requests inválidos enviados: $INVALID_COUNT"
    echo "📊 Resultados guardados en: $RESULT_FILE"
    
    # ═══════════════════════════════════════════════════════════════
    # Análisis de Resultados
    # ═══════════════════════════════════════════════════════════════
    
    echo ""
    echo "📈 Análisis de Resultados:"
    echo "---"
    
    if [ -f "$RESULT_FILE" ]; then
        # Contar resultados
        TOTAL=$(grep -c "Request" "$RESULT_FILE" 2>/dev/null || echo "0")
        SUCCESS=$(grep -cE "Request [0-9]+: 200 " "$RESULT_FILE" 2>/dev/null || echo "0")
        ERROR_400=$(grep -cE "Request [0-9]+: (400|404) " "$RESULT_FILE" 2>/dev/null || echo "0")
        ERROR_500=$(grep -cE "Request [0-9]+: (500|502|503) " "$RESULT_FILE" 2>/dev/null || echo "0")
        TIMEOUTS=$(grep -c "TIMEOUT" "$RESULT_FILE" 2>/dev/null || echo "0")
        OTHER_ERRORS=$(grep -cE "ERROR|CURL_ERROR" "$RESULT_FILE" 2>/dev/null || echo "0")
        
        # Limpiar variables
        TOTAL=$(echo "$TOTAL" | tr -d '\n' | tr -d '[:space:]')
        TOTAL=${TOTAL//[^0-9]/}
        SUCCESS=$(echo "$SUCCESS" | tr -d '\n' | tr -d '[:space:]')
        SUCCESS=${SUCCESS//[^0-9]/}
        ERROR_400=$(echo "$ERROR_400" | tr -d '\n' | tr -d '[:space:]')
        ERROR_400=${ERROR_400//[^0-9]/}
        ERROR_500=$(echo "$ERROR_500" | tr -d '\n' | tr -d '[:space:]')
        ERROR_500=${ERROR_500//[^0-9]/}
        TIMEOUTS=$(echo "$TIMEOUTS" | tr -d '\n' | tr -d '[:space:]')
        TIMEOUTS=${TIMEOUTS//[^0-9]/}
        OTHER_ERRORS=$(echo "$OTHER_ERRORS" | tr -d '\n' | tr -d '[:space:]')
        OTHER_ERRORS=${OTHER_ERRORS//[^0-9]/}
        
        # Asignar 0 si vacíos
        TOTAL=${TOTAL:-0}
        SUCCESS=${SUCCESS:-0}
        ERROR_400=${ERROR_400:-0}
        ERROR_500=${ERROR_500:-0}
        TIMEOUTS=${TIMEOUTS:-0}
        OTHER_ERRORS=${OTHER_ERRORS:-0}
        
        echo "Total Requests: $TOTAL"
        
        if [ "$TOTAL" -gt 0 ]; then
            echo "Successful (200): $SUCCESS ($(( SUCCESS * 100 / TOTAL ))%)"
            echo "Client Errors (400/404): $ERROR_400 ($(( ERROR_400 * 100 / TOTAL ))%)"
            echo "Server Errors (500/502/503): $ERROR_500 ($(( ERROR_500 * 100 / TOTAL ))%)"
            echo "Timeouts: $TIMEOUTS ($(( TIMEOUTS * 100 / TOTAL ))%)"
            echo "Other Errors: $OTHER_ERRORS ($(( OTHER_ERRORS * 100 / TOTAL ))%)"
            
            echo ""
            echo "💡 Interpretación:"
            
            # Esperamos ~30% de requests con error (por diseño)
            EXPECTED_ERRORS=$(( TOTAL * ERROR_INJECTION_RATE / 100 ))
            ACTUAL_ERRORS=$(( ERROR_400 + ERROR_500 ))
            
            echo "   Errores esperados (~${ERROR_INJECTION_RATE}%): $EXPECTED_ERRORS"
            echo "   Errores detectados: $ACTUAL_ERRORS"
            
            if [ "$ERROR_400" -gt 0 ]; then
                log_success "✅ Validación de input funcionando (detecta requests inválidos)"
            fi
            
            if [ "$ERROR_500" -gt 0 ]; then
                log_warning "⚠️  Errores 500 detectados - verificar manejo de errores en Lambda"
            else
                log_success "✅ No se detectaron errores 500 - Lambda manejó bien los errores"
            fi
            
            if [ "$SUCCESS" -gt $(( TOTAL * 60 / 100 )) ]; then
                log_success "✅ Sistema mantiene >60% de requests exitosos con errores inyectados"
            else
                log_warning "⚠️  Tasa de éxito baja (<60%) - revisar resiliencia"
            fi
        else
            echo "⚠️  No se encontraron resultados en el archivo"
        fi
    else
        echo "❌ Archivo de resultados no encontrado: $RESULT_FILE"
    fi
    
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "   ✅ EXPERIMENTO COMPLETADO"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
else
    echo "❌ Test cancelado por el usuario"
    exit 0
fi
