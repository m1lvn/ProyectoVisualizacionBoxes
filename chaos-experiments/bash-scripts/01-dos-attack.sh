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
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\nTIME:%{time_total}" \
        --max-time 10 \
        "$API_ENDPOINT$ENDPOINT" \
        -H "Authorization: Bearer $TOKEN" 2>&1)
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "^HTTP_CODE:" | cut -d':' -f2 | tr -d ' ')
    TIME=$(echo "$RESPONSE" | grep "^TIME:" | cut -d':' -f2 | tr -d ' ')
    
    # Si no capturó código, mostrar error
    if [ -z "$HTTP_CODE" ]; then
        HTTP_CODE="ERROR"
        TIME="N/A"
    fi
    
    echo "  Request $i: Status=$HTTP_CODE | Time=${TIME}s"
done

echo ""
read -p "🚨 ¿Iniciar ataque DoS? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
    echo ""
    echo "💥 Iniciando ataque DoS..."
    echo "⏱️  Timestamp: $(date)"
    
    # Crear directorio de resultados si no existe
    RESULTS_DIR="$SCRIPT_DIR/../results"
    mkdir -p "$RESULTS_DIR"
    
    # Crear archivo de resultados
    RESULT_FILE="$RESULTS_DIR/dos-attack-$(date +%Y%m%d-%H%M%S).log"
    echo "DoS Attack Results - $(date)" > "$RESULT_FILE"
    echo "API: $API_ENDPOINT$ENDPOINT" >> "$RESULT_FILE"
    echo "Total Requests: $REQUESTS" >> "$RESULT_FILE"
    echo "Concurrent: $CONCURRENT" >> "$RESULT_FILE"
    echo "---" >> "$RESULT_FILE"
    
    # Bombardear con requests
    echo "💥 Enviando $REQUESTS requests con $CONCURRENT concurrentes..."
    
    for i in $(seq 1 $REQUESTS); do
        (
            # Timeout de 10 segundos por request
            RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\nTIME:%{time_total}" \
                --max-time 10 \
                --connect-timeout 5 \
                "$API_ENDPOINT$ENDPOINT" \
                -H "Authorization: Bearer $TOKEN" \
                2>&1)
            
            EXIT_CODE=$?
            
            if [ $EXIT_CODE -eq 0 ]; then
                HTTP_CODE=$(echo "$RESPONSE" | grep "^HTTP_CODE:" | cut -d':' -f2 | tr -d ' ')
                TIME=$(echo "$RESPONSE" | grep "^TIME:" | cut -d':' -f2 | tr -d ' ')
                
                # Si no se capturó código HTTP, marcarlo como error
                if [ -z "$HTTP_CODE" ]; then
                    HTTP_CODE="ERROR"
                    TIME="0"
                fi
            else
                # Curl falló (timeout, conexión rechazada, etc.)
                if [ $EXIT_CODE -eq 28 ]; then
                    HTTP_CODE="TIMEOUT"
                elif [ $EXIT_CODE -eq 7 ]; then
                    HTTP_CODE="CONNECTION_REFUSED"
                else
                    HTTP_CODE="CURL_ERROR_$EXIT_CODE"
                fi
                TIME="0"
            fi
            
            echo "Request $i: $HTTP_CODE | ${TIME}s" >> "$RESULT_FILE"
            
            # Mostrar cada 50 requests
            if [ $(($i % 50)) -eq 0 ]; then
                echo "  Progress: $i/$REQUESTS requests enviados..."
            fi
        ) &
        
        # Control de concurrencia
        if [ $(jobs -r | wc -l) -ge $CONCURRENT ]; then
            wait -n
        fi
    done
    
    echo "  ⏳ Esperando que terminen todos los requests..."
    wait
    
    echo ""
    echo "✅ Ataque completado"
    echo "📊 Resultados guardados en: $RESULT_FILE"
    
    # Análisis de resultados
    echo ""
    echo "📈 Análisis de Resultados:"
    echo "---"
    
    if [ -f "$RESULT_FILE" ]; then
        # Contar cada tipo de resultado (asegurar que sean números)
        TOTAL=$(grep -c "Request" "$RESULT_FILE" 2>/dev/null || echo "0")
        SUCCESS=$(grep -c ": 200 " "$RESULT_FILE" 2>/dev/null || echo "0")
        THROTTLED=$(grep -c ": 429 " "$RESULT_FILE" 2>/dev/null || echo "0")
        ERRORS_5XX=$(grep -c ": 50[0-9] " "$RESULT_FILE" 2>/dev/null || echo "0")
        TIMEOUTS=$(grep -c "TIMEOUT" "$RESULT_FILE" 2>/dev/null || echo "0")
        CONN_REFUSED=$(grep -c "CONNECTION_REFUSED" "$RESULT_FILE" 2>/dev/null || echo "0")
        OTHER_ERRORS=$(grep -cE "ERROR|CURL_ERROR" "$RESULT_FILE" 2>/dev/null || echo "0")
        
        # Validar que todas las variables son números
        TOTAL=${TOTAL//[^0-9]/}
        SUCCESS=${SUCCESS//[^0-9]/}
        THROTTLED=${THROTTLED//[^0-9]/}
        ERRORS_5XX=${ERRORS_5XX//[^0-9]/}
        TIMEOUTS=${TIMEOUTS//[^0-9]/}
        CONN_REFUSED=${CONN_REFUSED//[^0-9]/}
        OTHER_ERRORS=${OTHER_ERRORS//[^0-9]/}
        
        # Asignar 0 si están vacíos
        TOTAL=${TOTAL:-0}
        SUCCESS=${SUCCESS:-0}
        THROTTLED=${THROTTLED:-0}
        ERRORS_5XX=${ERRORS_5XX:-0}
        TIMEOUTS=${TIMEOUTS:-0}
        CONN_REFUSED=${CONN_REFUSED:-0}
        OTHER_ERRORS=${OTHER_ERRORS:-0}
        
        echo "Total Requests: $TOTAL"
        
        if [ "$TOTAL" -gt 0 ]; then
            echo "Successful (200): $SUCCESS ($(( SUCCESS * 100 / TOTAL ))%)"
            echo "Throttled (429): $THROTTLED ($(( THROTTLED * 100 / TOTAL ))%)"
            echo "Server Errors (5xx): $ERRORS_5XX ($(( ERRORS_5XX * 100 / TOTAL ))%)"
            echo "Timeouts: $TIMEOUTS ($(( TIMEOUTS * 100 / TOTAL ))%)"
            echo "Connection Refused: $CONN_REFUSED ($(( CONN_REFUSED * 100 / TOTAL ))%)"
            echo "Other Errors: $OTHER_ERRORS ($(( OTHER_ERRORS * 100 / TOTAL ))%)"
            
            # Latencia promedio (solo requests exitosos)
            AVG_TIME=$(grep ": 200 " "$RESULT_FILE" | cut -d'|' -f2 | cut -d's' -f1 | \
                       awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; else print "N/A" }')
            echo "Latencia promedio (200 OK): ${AVG_TIME}s"
            
            echo ""
            echo "💡 Interpretación:"
            if [ "$SUCCESS" -gt $(( TOTAL * 80 / 100 )) ]; then
                echo "   ✅ Sistema resistió bien la carga (>80% exitosos)"
            elif [ "$SUCCESS" -gt $(( TOTAL * 50 / 100 )) ]; then
                echo "   ⚠️  Sistema tiene limitaciones (50-80% exitosos)"
            else
                echo "   ❌ Sistema no soporta esta carga (<50% exitosos)"
            fi
            
            if [ "$THROTTLED" -gt 0 ]; then
                echo "   🚦 Rate limiting activo (bueno para protección)"
            fi
            
            if [ "$TIMEOUTS" -gt $(( TOTAL * 20 / 100 )) ]; then
                echo "   ⏱️  Muchos timeouts - revisar capacidad Lambda/DynamoDB"
            fi
        else
            echo "⚠️  No se encontraron resultados en el archivo"
        fi
    else
        echo "❌ Archivo de resultados no encontrado: $RESULT_FILE"
    fi
    
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
