#!/bin/bash
# ════════════════════════════════════════════════════════════════
# Ejecutar experimento AWS FIS de forma automatizada
# ════════════════════════════════════════════════════════════════
#
# USO:
#   ./run-fis-experiment.sh dynamodb-throttling
#   ./run-fis-experiment.sh lambda-error-injection --duration 5
#   ./run-fis-experiment.sh dynamodb-throttling --dry-run
#

set -e

# Parsear argumentos
EXPERIMENT_NAME=""
DURATION_MINUTES=5
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --duration|-d)
            DURATION_MINUTES="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        dynamodb-throttling|lambda-error-injection)
            EXPERIMENT_NAME="$1"
            shift
            ;;
        *)
            echo "Uso: $0 <dynamodb-throttling|lambda-error-injection> [--duration MINS] [--dry-run]"
            exit 1
            ;;
    esac
done

if [ -z "$EXPERIMENT_NAME" ]; then
    echo "Error: Debes especificar el nombre del experimento"
    echo "Uso: $0 <dynamodb-throttling|lambda-error-injection>"
    exit 1
fi

echo "════════════════════════════════════════════════════════════"
echo "   AWS FIS - EJECUTAR EXPERIMENTO"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Experimento: $EXPERIMENT_NAME"
echo "Duración: $DURATION_MINUTES minutos"
echo "Dry Run: $DRY_RUN"
echo ""

REGION="us-east-1"
TEMPLATE_FILE="aws-fis/$EXPERIMENT_NAME.json"

# Verificar que el template existe
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "❌ Template no encontrado: $TEMPLATE_FILE"
    exit 1
fi

echo "[1/5] Creando experiment template en AWS..."

if [ "$DRY_RUN" = true ]; then
    echo "   🔍 DRY RUN - No se creará el template"
    TEMPLATE_ID="dry-run-template-id"
else
    CREATE_OUTPUT=$(aws fis create-experiment-template \
        --cli-input-json "file://$TEMPLATE_FILE" \
        --region "$REGION" \
        --output json)
    
    TEMPLATE_ID=$(echo "$CREATE_OUTPUT" | python3 -c "import sys, json; print(json.load(sys.stdin)['experimentTemplate']['id'])")
    
    echo "   ✅ Template creado: $TEMPLATE_ID"
fi

echo ""
echo "[2/5] Iniciando experimento..."

if [ "$DRY_RUN" = true ]; then
    echo "   🔍 DRY RUN - No se iniciará el experimento"
    EXPERIMENT_ID="dry-run-experiment-id"
else
    START_OUTPUT=$(aws fis start-experiment \
        --experiment-template-id "$TEMPLATE_ID" \
        --tags Key=Name,Value="$EXPERIMENT_NAME" Key=AutomatedBy,Value=BashScript \
        --region "$REGION" \
        --output json)
    
    EXPERIMENT_ID=$(echo "$START_OUTPUT" | python3 -c "import sys, json; print(json.load(sys.stdin)['experiment']['id'])")
    CURRENT_STATE=$(echo "$START_OUTPUT" | python3 -c "import sys, json; print(json.load(sys.stdin)['experiment']['state']['status'])")
    
    echo "   ✅ Experimento iniciado: $EXPERIMENT_ID"
    echo "   Estado: $CURRENT_STATE"
fi

echo ""
echo "[3/5] Monitoreando experimento..."
echo "   Duración esperada: $DURATION_MINUTES minutos"
echo ""

START_TIME=$(date +%s)
CHECK_INTERVAL=10

if [ "$DRY_RUN" = false ]; then
    while true; do
        sleep $CHECK_INTERVAL
        
        STATUS_OUTPUT=$(aws fis get-experiment \
            --id "$EXPERIMENT_ID" \
            --region "$REGION" \
            --output json)
        
        CURRENT_STATE=$(echo "$STATUS_OUTPUT" | python3 -c "import sys, json; print(json.load(sys.stdin)['experiment']['state']['status'])")
        
        ELAPSED=$(( $(date +%s) - START_TIME ))
        
        echo "   ⏱️  ${ELAPSED}s | Estado: $CURRENT_STATE"
        
        if [[ "$CURRENT_STATE" == "completed" ]] || [[ "$CURRENT_STATE" == "stopped" ]] || [[ "$CURRENT_STATE" == "failed" ]]; then
            echo ""
            case "$CURRENT_STATE" in
                completed)
                    echo "   ✅ Experimento completado"
                    ;;
                stopped)
                    echo "   ⚠️  Experimento detenido manualmente"
                    ;;
                failed)
                    echo "   ❌ Experimento falló"
                    ;;
            esac
            break
        fi
        
        # Timeout de seguridad (1.5x la duración esperada)
        TIMEOUT=$(( DURATION_MINUTES * 60 * 3 / 2 ))
        if [ $ELAPSED -gt $TIMEOUT ]; then
            echo ""
            echo "   ⚠️  Timeout alcanzado, deteniendo experimento..."
            
            aws fis stop-experiment --id "$EXPERIMENT_ID" --region "$REGION" > /dev/null
            break
        fi
    done
else
    echo "   🔍 DRY RUN - Simulando monitoreo por 5 segundos..."
    sleep 5
    CURRENT_STATE="completed"
fi

echo ""
echo "[4/5] Recopilando métricas de CloudWatch..."

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
METRICS_FILE="results/experiment-$EXPERIMENT_NAME-$TIMESTAMP.json"
mkdir -p results

if [ "$DRY_RUN" = false ]; then
    END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S")
    START_TIME_METRICS=$(date -u -d "-$(( DURATION_MINUTES + 2 )) minutes" +"%Y-%m-%dT%H:%M:%S")
    
    # Lambda errors
    LAMBDA_ERRORS=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/Lambda \
        --metric-name Errors \
        --start-time "$START_TIME_METRICS" \
        --end-time "$END_TIME" \
        --period 60 \
        --statistics Sum \
        --region "$REGION" \
        --output json 2>/dev/null || echo '{"Datapoints":[]}')
    
    LAMBDA_ERRORS_COUNT=$(echo "$LAMBDA_ERRORS" | python3 -c "import sys, json; print(len(json.load(sys.stdin)['Datapoints']))" 2>/dev/null || echo 0)
    echo "   ✅ Lambda errors: $LAMBDA_ERRORS_COUNT datapoints"
    
    # DynamoDB throttles
    DYNAMO_THROTTLES=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/DynamoDB \
        --metric-name UserErrors \
        --dimensions Name=TableName,Value=HospitalData \
        --start-time "$START_TIME_METRICS" \
        --end-time "$END_TIME" \
        --period 60 \
        --statistics Sum \
        --region "$REGION" \
        --output json 2>/dev/null || echo '{"Datapoints":[]}')
    
    DYNAMO_THROTTLES_COUNT=$(echo "$DYNAMO_THROTTLES" | python3 -c "import sys, json; print(len(json.load(sys.stdin)['Datapoints']))" 2>/dev/null || echo 0)
    echo "   ✅ DynamoDB throttles: $DYNAMO_THROTTLES_COUNT datapoints"
    
    # Guardar métricas
    cat > "$METRICS_FILE" <<EOF
{
  "experimentId": "$EXPERIMENT_ID",
  "experimentName": "$EXPERIMENT_NAME",
  "startTime": "$START_TIME_METRICS",
  "endTime": "$END_TIME",
  "metrics": {
    "lambdaErrors": $LAMBDA_ERRORS,
    "dynamoThrottles": $DYNAMO_THROTTLES
  }
}
EOF
    
    echo "   ✅ Métricas guardadas en: $METRICS_FILE"
else
    echo "   🔍 DRY RUN - No se recopilan métricas"
fi

echo ""
echo "[5/5] Generando reporte..."

if [ "$DRY_RUN" = false ]; then
    REPORT_FILE="results/REPORT-$EXPERIMENT_NAME-$TIMESTAMP.md"
    
    cat > "$REPORT_FILE" <<EOF
# Reporte de Experimento AWS FIS

## Información General

- **Experimento ID:** $EXPERIMENT_ID
- **Template ID:** $TEMPLATE_ID
- **Nombre:** $EXPERIMENT_NAME
- **Fecha:** $(date +"%Y-%m-%d %H:%M:%S")
- **Estado Final:** $CURRENT_STATE

## Configuración

\`\`\`json
$(cat "$TEMPLATE_FILE")
\`\`\`

## Métricas

Ver archivo de métricas completo: \`$METRICS_FILE\`

### Resumen

- Lambda Errors: $LAMBDA_ERRORS_COUNT datapoints
- DynamoDB Throttles: $DYNAMO_THROTTLES_COUNT datapoints

## Próximos Pasos

1. Analizar métricas detalladas
2. Documentar hallazgos
3. Proponer mejoras de resiliencia

---

*Generado automáticamente por run-fis-experiment.sh*
EOF
    
    echo "   ✅ Reporte generado: $REPORT_FILE"
else
    echo "   🔍 DRY RUN - No se genera reporte"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "   ✅ EXPERIMENTO FIS COMPLETADO"
echo "════════════════════════════════════════════════════════════"
echo ""

if [ "$DRY_RUN" = false ]; then
    echo "Archivos generados:"
    echo "   - Métricas: $METRICS_FILE"
    echo "   - Reporte: $REPORT_FILE"
    echo ""
    echo "Ver en AWS Console:"
    echo "   https://console.aws.amazon.com/fis/home?region=$REGION#Experiments/$EXPERIMENT_ID"
    echo ""
fi
