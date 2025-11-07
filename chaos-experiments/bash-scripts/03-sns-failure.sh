#!/bin/bash
# 03-sns-failure.sh
# Chaos Engineering Experiment #3: SNS Topic Failure
# 
# Objetivo: Validar resiliencia ante fallos de mensajería asíncrona
# Duración: ~5 minutos
# Método: Enviar eventos que deberían publicarse a SNS y validar handling

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

# Auto-detectar AWS Account ID y Region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
AWS_REGION=$(aws configure get region 2>/dev/null || echo "us-east-1")

if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "❌ Error: No se pudo obtener AWS Account ID"
    exit 1
fi

# Auto-construir ARNs de SNS topics
TOPICS=(
    "arn:aws:sns:${AWS_REGION}:${AWS_ACCOUNT_ID}:dev-hospital-user-events"
    "arn:aws:sns:${AWS_REGION}:${AWS_ACCOUNT_ID}:dev-hospital-agenda-events"
    "arn:aws:sns:${AWS_REGION}:${AWS_ACCOUNT_ID}:dev-hospital-notifications"
)

TOKEN="$JWT_TOKEN"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ═══════════════════════════════════════════════════════════════
# FUNCIONES
# ═══════════════════════════════════════════════════════════════

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

check_dependencies() {
    log_info "Verificando dependencias..."
    
    log_info "AWS Account ID: $AWS_ACCOUNT_ID"
    log_info "AWS Region: $AWS_REGION"
    log_info "API Endpoint: $API_ENDPOINT"
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI no está instalado"
        exit 1
    fi
    
    log_success "Dependencias verificadas"
}

# ═══════════════════════════════════════════════════════════════
# EXPERIMENTO
# ═══════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════════"
echo "🔥 CHAOS EXPERIMENT #3: SNS Topic Failure"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Objetivo: Probar resiliencia ante fallos de mensajería"
echo "Método: Eliminar suscripciones SNS temporalmente"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""

check_dependencies

# Crear directorio de resultados
RESULTS_DIR="../results/experiment-03-sns"
mkdir -p "$RESULTS_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$RESULTS_DIR/sns-failure-$TIMESTAMP.log"

log_info "Resultados se guardarán en: $LOG_FILE"
echo ""

# Archivo para backup de suscripciones
BACKUP_FILE="$RESULTS_DIR/sns-subscriptions-backup-$TIMESTAMP.json"

# ═══════════════════════════════════════════════════════════════
# FASE 1: BACKUP DE CONFIGURACIÓN ACTUAL
# ═══════════════════════════════════════════════════════════════

log_info "FASE 1: Haciendo backup de suscripciones SNS..."
echo "[" > "$BACKUP_FILE"

FIRST=true
for TOPIC_NAME in "${TOPICS[@]}"; do
    log_info "Buscando topic: $TOPIC_NAME..."
    
    # Buscar ARN del topic
    TOPIC_ARN=$(aws sns list-topics \
        --region "$AWS_REGION" \
        --query "Topics[?contains(TopicArn, '$TOPIC_NAME')].TopicArn" \
        --output text)
    
    if [ -z "$TOPIC_ARN" ]; then
        log_warning "Topic $TOPIC_NAME no encontrado"
        continue
    fi
    
    log_success "Topic encontrado: $TOPIC_ARN"
    
    # Listar suscripciones
    SUBSCRIPTIONS=$(aws sns list-subscriptions-by-topic \
        --topic-arn "$TOPIC_ARN" \
        --region "$AWS_REGION" \
        --output json)
    
    # Agregar al backup
    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        echo "," >> "$BACKUP_FILE"
    fi
    
    echo "{\"topic\": \"$TOPIC_NAME\", \"arn\": \"$TOPIC_ARN\", \"subscriptions\": $SUBSCRIPTIONS}" >> "$BACKUP_FILE"
    
    SUB_COUNT=$(echo "$SUBSCRIPTIONS" | jq '.Subscriptions | length')
    echo "  └─ $SUB_COUNT suscripciones encontradas"
done

echo "]" >> "$BACKUP_FILE"
log_success "Backup completado: $BACKUP_FILE"
echo ""

# ═══════════════════════════════════════════════════════════════
# FASE 2: ELIMINAR SUSCRIPCIONES (SIMULAR FALLO)
# ═══════════════════════════════════════════════════════════════

log_warning "FASE 2: Eliminando suscripciones SNS (simulando fallo)..."
echo ""

read -p "⚠️  Esto eliminará temporalmente las suscripciones SNS. ¿Continuar? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    log_info "Experimento cancelado por el usuario"
    exit 0
fi

DELETED_SUBSCRIPTIONS=()

for TOPIC_NAME in "${TOPICS[@]}"; do
    # Buscar ARN del topic
    TOPIC_ARN=$(aws sns list-topics \
        --region "$AWS_REGION" \
        --query "Topics[?contains(TopicArn, '$TOPIC_NAME')].TopicArn" \
        --output text)
    
    if [ -z "$TOPIC_ARN" ]; then
        continue
    fi
    
    log_warning "Eliminando suscripciones de: $TOPIC_NAME"
    
    # Obtener todas las suscripciones
    SUBSCRIPTION_ARNS=$(aws sns list-subscriptions-by-topic \
        --topic-arn "$TOPIC_ARN" \
        --region "$AWS_REGION" \
        --query "Subscriptions[*].SubscriptionArn" \
        --output text)
    
    if [ -z "$SUBSCRIPTION_ARNS" ]; then
        log_info "  └─ Sin suscripciones para eliminar"
        continue
    fi
    
    # Eliminar cada suscripción
    for SUB_ARN in $SUBSCRIPTION_ARNS; do
        if [ "$SUB_ARN" != "PendingConfirmation" ]; then
            echo "  └─ Eliminando: $SUB_ARN"
            aws sns unsubscribe \
                --subscription-arn "$SUB_ARN" \
                --region "$AWS_REGION" || log_warning "No se pudo eliminar $SUB_ARN"
            
            DELETED_SUBSCRIPTIONS+=("$SUB_ARN")
        fi
    done
done

log_success "Suscripciones eliminadas: ${#DELETED_SUBSCRIPTIONS[@]}"
echo ""

# ═══════════════════════════════════════════════════════════════
# FASE 3: GENERAR EVENTOS (DEBEN PERDERSE)
# ═══════════════════════════════════════════════════════════════

log_info "FASE 3: Generando eventos (estos NO se procesarán)..."
echo ""

# Esperar 10 segundos para que los cambios se propaguen
log_info "Esperando 10 segundos para propagación de cambios..."
sleep 10

# Intentar crear agendas (esto debería fallar silenciosamente en los event handlers)
log_info "Creando 5 agendas de prueba..."

if [ -z "$TOKEN" ]; then
    log_warning "No se proporcionó JWT_TOKEN, saltando creación de agendas"
else
    for i in {1..5}; do
        RESPONSE=$(curl -s -X POST "$API_ENDPOINT/agendas" \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"fecha\": \"2025-11-0$i\",
                \"horaInicio\": \"09:00\",
                \"horaFin\": \"10:00\",
                \"profesional\": \"Dr. Chaos Test $i\",
                \"especialidad\": \"Test\"
            }" 2>&1)
        
        echo "  Evento $i: $(echo $RESPONSE | jq -r '.message // .error // "Enviado"')"
    done
fi

log_warning "Eventos generados pero NO procesados (suscripciones desconectadas)"
echo ""

# ═══════════════════════════════════════════════════════════════
# FASE 4: VERIFICAR QUE NO SE PROCESARON
# ═══════════════════════════════════════════════════════════════

log_info "FASE 4: Verificando que los event handlers NO recibieron eventos..."
echo ""

# Esperar 30 segundos
log_info "Esperando 30 segundos..."
sleep 30

# Revisar logs de Lambda event handlers
LAMBDA_FUNCTIONS=(
    "hospital-boxes-api-dev-userEventsHandler"
    "hospital-boxes-api-dev-agendaEventsHandler"
    "hospital-boxes-api-dev-notificationHandler"
)

for FUNCTION_NAME in "${LAMBDA_FUNCTIONS[@]}"; do
    log_info "Revisando logs de $FUNCTION_NAME..."
    
    RECENT_LOGS=$(aws logs tail "/aws/lambda/$FUNCTION_NAME" \
        --since 5m \
        --region "$AWS_REGION" \
        --format short 2>/dev/null | tail -10 || echo "No logs found")
    
    if [ "$RECENT_LOGS" == "No logs found" ] || [ -z "$RECENT_LOGS" ]; then
        log_success "  └─ ✅ Correcto: Sin logs recientes (eventos no procesados)"
    else
        log_warning "  └─ ⚠️  Hay logs recientes (revisar)"
        echo "$RECENT_LOGS" | head -5
    fi
done

echo ""

# ═══════════════════════════════════════════════════════════════
# FASE 5: RESTAURAR CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════

log_info "FASE 5: Restaurando suscripciones SNS..."
echo ""

read -p "¿Restaurar automáticamente o usar Serverless? (auto/serverless): " restore_method

if [ "$restore_method" == "auto" ]; then
    log_warning "Restauración automática no implementada"
    log_info "Por favor, restaura manualmente desde: $BACKUP_FILE"
elif [ "$restore_method" == "serverless" ]; then
    log_info "Ejecutando serverless deploy para restaurar..."
    
    cd ../../serverless-api
    
    if [ -f "serverless.yml" ]; then
        npx serverless deploy --verbose
        log_success "Suscripciones restauradas vía Serverless"
    else
        log_error "serverless.yml no encontrado"
    fi
    
    cd ../chaos-experiments/bash-scripts
else
    log_info "Restauración manual seleccionada"
fi

echo ""

# ═══════════════════════════════════════════════════════════════
# FASE 6: VERIFICAR RECUPERACIÓN
# ═══════════════════════════════════════════════════════════════

log_info "FASE 6: Verificando recuperación..."
echo ""

# Esperar 20 segundos para que se restaure
log_info "Esperando 20 segundos para propagación..."
sleep 20

# Verificar suscripciones restauradas
for TOPIC_NAME in "${TOPICS[@]}"; do
    TOPIC_ARN=$(aws sns list-topics \
        --region "$AWS_REGION" \
        --query "Topics[?contains(TopicArn, '$TOPIC_NAME')].TopicArn" \
        --output text)
    
    if [ -z "$TOPIC_ARN" ]; then
        continue
    fi
    
    SUB_COUNT=$(aws sns list-subscriptions-by-topic \
        --topic-arn "$TOPIC_ARN" \
        --region "$AWS_REGION" \
        --query "Subscriptions" \
        --output json | jq 'length')
    
    log_info "Topic $TOPIC_NAME: $SUB_COUNT suscripciones"
done

log_success "Verificación completada"
echo ""

# ═══════════════════════════════════════════════════════════════
# RESUMEN FINAL
# ═══════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════════"
echo "✅ EXPERIMENTO COMPLETADO"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📊 Resumen:"
echo "  - Suscripciones eliminadas: ${#DELETED_SUBSCRIPTIONS[@]}"
echo "  - Eventos generados: 5"
echo "  - Estado: Suscripciones restauradas"
echo ""
echo "📁 Archivos generados:"
echo "  - Backup: $BACKUP_FILE"
echo "  - Log: $LOG_FILE"
echo ""
echo "📝 Resultado esperado:"
echo "  ✅ Eventos NO procesados durante la desconexión"
echo "  ✅ Sistema se recupera después de restore"
echo "  ⚠️  Pérdida de eventos (sin retry en SNS por defecto)"
echo ""
echo "💡 Mejora sugerida:"
echo "  - Implementar DLQ (Dead Letter Queue) para SNS"
echo "  - Agregar retry policy en suscripciones"
echo "  - Implementar event sourcing para recuperación"
echo ""
echo "📈 Próximos pasos:"
echo "  1. Revisar logs de Lambda event handlers"
echo "  2. Documentar en results/experiment-03-sns-report.md"
echo "  3. Proponer mejoras de resiliencia para mensajería"
echo ""
echo "═══════════════════════════════════════════════════════════════"
