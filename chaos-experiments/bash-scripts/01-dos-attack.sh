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
echo "[DEBUG] Variables de entorno:"
echo "   - API_ENDPOINT from env: '${API_ENDPOINT}'"
echo "   - Full URL: '${API_ENDPOINT}${ENDPOINT}'"
echo ""

# Validar que el endpoint no esté vacío
if [ -z "$API_ENDPOINT" ]; then
    echo "❌ ERROR: API_ENDPOINT está vacío"
    echo "   Configura API_ENDPOINT en .env o edita el script"
    exit 1
fi

# Test de conectividad
echo "🔍 Testeando conectividad al endpoint..."
TEST_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" --max-time 5 "${API_ENDPOINT}${ENDPOINT}" 2>&1)
TEST_EXIT=$?
if [ $TEST_EXIT -ne 0 ]; then
    echo "⚠️  WARNING: No se pudo conectar al endpoint"
    echo "   Exit code: $TEST_EXIT"
    if [ $TEST_EXIT -eq 6 ]; then
        echo "   Error 6: Could not resolve host"
        echo "   Verifica que el URL sea correcto: ${API_ENDPOINT}${ENDPOINT}"
    fi
    echo ""
    read -p "¿Continuar de todos modos? (yes/no): " continue_confirm
    if [ "$continue_confirm" != "yes" ]; then
        exit 1
    fi
else
    echo "✅ Conectividad OK"
fi
echo ""

# Obtener token de autenticación desde Cognito User Pool
if [ -z "$JWT_TOKEN" ]; then
    echo "⚠️  JWT_TOKEN no encontrado en .env"
    echo ""
    echo "🔄 Obteniendo JWT desde Cognito User Pool..."
    cd "$SCRIPT_DIR/.."
    
    # Usar el nuevo script de Cognito
    if [ -f "./get-cognito-jwt.sh" ]; then
        JWT_TOKEN=$(./get-cognito-jwt.sh --verbose --user admin)
        EXIT_CODE=$?
        
        if [ $EXIT_CODE -ne 0 ] || [ -z "$JWT_TOKEN" ]; then
            echo "❌ Error obteniendo JWT desde Cognito"
            echo "💡 Verifica que los usuarios de prueba existan en Cognito User Pool"
            exit 1
        fi
        
        # Actualizar variable de entorno
        export JWT_TOKEN="$JWT_TOKEN"
        echo "✅ JWT obtenido desde Cognito User Pool"
    else
        echo "❌ Error: get-cognito-jwt.sh no encontrado"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
else
    echo "ℹ️  Usando JWT_TOKEN desde .env"
    echo "⚠️  NOTA: Verifica que sea un token válido de Cognito User Pool"
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
    
    # [DEBUG] Mostrar una muestra del archivo
    echo ""
    echo "[DEBUG] Primeras 10 líneas del archivo de resultados:"
    head -n 15 "$RESULT_FILE" | tail -n 10
    echo ""
    echo "[DEBUG] Últimas 5 líneas del archivo:"
    tail -n 5 "$RESULT_FILE"
    echo ""
    
    # Análisis de resultados
    echo ""
    echo "📈 Análisis de Resultados:"
    echo "---"
    
    if [ -f "$RESULT_FILE" ]; then
        # Contar cada tipo de resultado (asegurar que sean números)
        echo "[DEBUG] Contando resultados..."
        TOTAL=$(grep -c "Request" "$RESULT_FILE" 2>/dev/null || echo "0")
        echo "[DEBUG] TOTAL raw: '$TOTAL'"
        
        # Buscar códigos HTTP específicos (sin requerir espacio después)
        SUCCESS=$(grep -cE "Request [0-9]+: 200 " "$RESULT_FILE" 2>/dev/null || echo "0")
        echo "[DEBUG] SUCCESS raw: '$SUCCESS'"
        echo "[DEBUG] Líneas con 200:"
        grep -E "Request [0-9]+: 200 " "$RESULT_FILE" 2>/dev/null | head -n 3 || echo "Ninguna"
        
        NOT_FOUND=$(grep -cE "Request [0-9]+: 404 " "$RESULT_FILE" 2>/dev/null || echo "0")
        echo "[DEBUG] NOT_FOUND raw: '$NOT_FOUND'"
        echo "[DEBUG] Líneas con 404:"
        grep -E "Request [0-9]+: 404 " "$RESULT_FILE" 2>/dev/null | head -n 3 || echo "Ninguna"
        
        THROTTLED=$(grep -cE "Request [0-9]+: 429 " "$RESULT_FILE" 2>/dev/null || echo "0")
        CLIENT_ERRORS=$(grep -cE "Request [0-9]+: 4[0-9]{2} " "$RESULT_FILE" 2>/dev/null || echo "0")
        ERRORS_5XX=$(grep -cE "Request [0-9]+: 5[0-9]{2} " "$RESULT_FILE" 2>/dev/null || echo "0")
        TIMEOUTS=$(grep -c "TIMEOUT" "$RESULT_FILE" 2>/dev/null || echo "0")
        echo "[DEBUG] TIMEOUTS raw: '$TIMEOUTS'"
        echo "[DEBUG] Líneas con TIMEOUT:"
        grep "TIMEOUT" "$RESULT_FILE" 2>/dev/null | head -n 3 || echo "Ninguna"
        
        CONN_REFUSED=$(grep -c "CONNECTION_REFUSED" "$RESULT_FILE" 2>/dev/null || echo "0")
        OTHER_ERRORS=$(grep -cE "ERROR|CURL_ERROR" "$RESULT_FILE" 2>/dev/null || echo "0")
        echo "[DEBUG] OTHER_ERRORS raw: '$OTHER_ERRORS'"
        echo "[DEBUG] Líneas con ERROR:"
        grep -E "ERROR|CURL_ERROR" "$RESULT_FILE" 2>/dev/null | head -n 3 || echo "Ninguna"
        
        # Validar que todas las variables son números (remover newlines y no-dígitos)
        TOTAL=$(echo "$TOTAL" | tr -d '\n' | tr -d '[:space:]')
        TOTAL=${TOTAL//[^0-9]/}
        SUCCESS=$(echo "$SUCCESS" | tr -d '\n' | tr -d '[:space:]')
        SUCCESS=${SUCCESS//[^0-9]/}
        NOT_FOUND=$(echo "$NOT_FOUND" | tr -d '\n' | tr -d '[:space:]')
        NOT_FOUND=${NOT_FOUND//[^0-9]/}
        THROTTLED=$(echo "$THROTTLED" | tr -d '\n' | tr -d '[:space:]')
        THROTTLED=${THROTTLED//[^0-9]/}
        CLIENT_ERRORS=$(echo "$CLIENT_ERRORS" | tr -d '\n' | tr -d '[:space:]')
        CLIENT_ERRORS=${CLIENT_ERRORS//[^0-9]/}
        ERRORS_5XX=$(echo "$ERRORS_5XX" | tr -d '\n' | tr -d '[:space:]')
        ERRORS_5XX=${ERRORS_5XX//[^0-9]/}
        TIMEOUTS=$(echo "$TIMEOUTS" | tr -d '\n' | tr -d '[:space:]')
        TIMEOUTS=${TIMEOUTS//[^0-9]/}
        CONN_REFUSED=$(echo "$CONN_REFUSED" | tr -d '\n' | tr -d '[:space:]')
        CONN_REFUSED=${CONN_REFUSED//[^0-9]/}
        OTHER_ERRORS=$(echo "$OTHER_ERRORS" | tr -d '\n' | tr -d '[:space:]')
        OTHER_ERRORS=${OTHER_ERRORS//[^0-9]/}
        
        # Asignar 0 si están vacíos
        TOTAL=${TOTAL:-0}
        SUCCESS=${SUCCESS:-0}
        NOT_FOUND=${NOT_FOUND:-0}
        THROTTLED=${THROTTLED:-0}
        CLIENT_ERRORS=${CLIENT_ERRORS:-0}
        ERRORS_5XX=${ERRORS_5XX:-0}
        TIMEOUTS=${TIMEOUTS:-0}
        CONN_REFUSED=${CONN_REFUSED:-0}
        OTHER_ERRORS=${OTHER_ERRORS:-0}
        
        echo "Total Requests: $TOTAL"
        
        if [ "$TOTAL" -gt 0 ]; then
            echo "Successful (200): $SUCCESS ($(( SUCCESS * 100 / TOTAL ))%)"
            echo "Not Found (404): $NOT_FOUND ($(( NOT_FOUND * 100 / TOTAL ))%)"
            echo "Throttled (429): $THROTTLED ($(( THROTTLED * 100 / TOTAL ))%)"
            echo "Client Errors (4xx): $CLIENT_ERRORS ($(( CLIENT_ERRORS * 100 / TOTAL ))%)"
            echo "Server Errors (5xx): $ERRORS_5XX ($(( ERRORS_5XX * 100 / TOTAL ))%)"
            echo "Timeouts: $TIMEOUTS ($(( TIMEOUTS * 100 / TOTAL ))%)"
            echo "Connection Refused: $CONN_REFUSED ($(( CONN_REFUSED * 100 / TOTAL ))%)"
            echo "Other Errors: $OTHER_ERRORS ($(( OTHER_ERRORS * 100 / TOTAL ))%)"
            
            # Latencia promedio (solo requests exitosos)
            AVG_TIME=$(grep -E "Request [0-9]+: 200 " "$RESULT_FILE" | grep -oE "[0-9]+\.[0-9]+s" | tr -d 's' | \
                       awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; else print "N/A" }')
            echo "Latencia promedio (200 OK): ${AVG_TIME}s"
            
            echo ""
            echo "💡 Interpretación:"
            if [ "$NOT_FOUND" -gt $(( TOTAL * 90 / 100 )) ]; then
                echo "   ⚠️  Problema de ruta: 404 Not Found en la mayoría de requests"
                echo "   🔍 Verifica que la ruta sea correcta: ${API_ENDPOINT}${ENDPOINT}"
                echo "   💡 Posibles causas:"
                echo "      - El endpoint /boxes no existe en tu API"
                echo "      - Falta autenticación (JWT token inválido)"
                echo "      - El stage 'dev' no está configurado"
            elif [ "$SUCCESS" -gt $(( TOTAL * 80 / 100 )) ]; then
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
