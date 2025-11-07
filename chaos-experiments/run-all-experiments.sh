#!/bin/bash
# ════════════════════════════════════════════════════════════════
# Ejecutar Suite Completa de Experimentos de Chaos Engineering
# ════════════════════════════════════════════════════════════════
#
# Ejecuta todos los experimentos de forma automática
#
# Uso: ./run-all-experiments.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "   🔥 CHAOS ENGINEERING - SUITE COMPLETA"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Fecha: $(date +'%Y-%m-%d %H:%M:%S')"
echo ""

# ═══════════════════════════════════════════════════════════════
# 1. Verificar archivo .env
# ═══════════════════════════════════════════════════════════════

if [ ! -f "$ENV_FILE" ]; then
    log_error "Archivo .env no encontrado"
    echo ""
    echo "Por favor ejecuta primero:"
    echo "  ./setup.sh"
    echo ""
    exit 1
fi

log_info "Cargando configuración desde .env..."
export $(cat "$ENV_FILE" | grep -v '^#' | grep -v '^$' | xargs)

if [ -z "$JWT_TOKEN" ] || [ -z "$API_ENDPOINT" ]; then
    log_error "JWT_TOKEN o API_ENDPOINT no están configurados en .env"
    echo ""
    echo "Por favor ejecuta:"
    echo "  ./setup.sh"
    echo ""
    exit 1
fi

log_success "Configuración cargada"
echo "   API: $API_ENDPOINT"
echo "   Token: ${JWT_TOKEN:0:30}..."
echo ""

# ═══════════════════════════════════════════════════════════════
# 2. Validar token
# ═══════════════════════════════════════════════════════════════

log_info "Validando token..."
RESPONSE=$(curl -s -w "\n%{http_code}" \
    --max-time 10 \
    "$API_ENDPOINT/api/boxes" \
    -H "Authorization: Bearer $JWT_TOKEN" 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" != "200" ]; then
    log_error "Token inválido o expirado (HTTP $HTTP_CODE)"
    echo ""
    echo "El token puede haber expirado. Ejecuta:"
    echo "  ./setup.sh"
    echo ""
    exit 1
fi

log_success "Token válido"
echo ""

# ═══════════════════════════════════════════════════════════════
# 3. Crear directorio de resultados
# ═══════════════════════════════════════════════════════════════

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULTS_DIR="$SCRIPT_DIR/results/suite-$TIMESTAMP"
mkdir -p "$RESULTS_DIR"

log_info "Directorio de resultados: $RESULTS_DIR"
echo ""

# ═══════════════════════════════════════════════════════════════
# 4. Definir experimentos
# ═══════════════════════════════════════════════════════════════

EXPERIMENTS=(
    "01-dos-attack.sh|DoS Attack|1000 requests con 50 concurrentes"
    "02-lambda-latency.sh|Lambda Latency|500 requests bajo carga"
    "03-sns-failure.sh|SNS Resilience|Test de mensajería asíncrona"
    "04-dynamodb-throttling-sim.sh|DynamoDB Throttling|800 requests para forzar límites"
    "05-lambda-errors-sim.sh|Lambda Error Injection|300 requests con 30% errores"
)

TOTAL_EXPERIMENTS=${#EXPERIMENTS[@]}

echo "════════════════════════════════════════════════════════════════"
echo "   📊 EXPERIMENTOS A EJECUTAR: $TOTAL_EXPERIMENTS"
echo "════════════════════════════════════════════════════════════════"
echo ""

for experiment in "${EXPERIMENTS[@]}"; do
    IFS='|' read -r script name description <<< "$experiment"
    echo "  ✓ $name"
    echo "    $description"
    echo ""
done

read -p "🚨 ¿Continuar con la ejecución? (yes/no): " confirm
echo ""

if [ "$confirm" != "yes" ]; then
    log_error "Ejecución cancelada por el usuario"
    exit 0
fi

# ═══════════════════════════════════════════════════════════════
# 5. Ejecutar experimentos
# ═══════════════════════════════════════════════════════════════

SUITE_START=$(date +%s)
SUCCESSFUL=0
FAILED=0

declare -a EXPERIMENT_RESULTS

for i in "${!EXPERIMENTS[@]}"; do
    IFS='|' read -r script name description <<< "${EXPERIMENTS[$i]}"
    
    EXPERIMENT_NUM=$((i + 1))
    
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "   EXPERIMENTO $EXPERIMENT_NUM/$TOTAL_EXPERIMENTS: $name"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    SCRIPT_PATH="$SCRIPT_DIR/bash-scripts/$script"
    
    if [ ! -f "$SCRIPT_PATH" ]; then
        log_error "Script no encontrado: $script"
        EXPERIMENT_RESULTS+=("❌|$name|FAILED|Script not found|0")
        ((FAILED++))
        continue
    fi
    
    # Ejecutar experimento
    EXP_START=$(date +%s)
    
    # Responder automáticamente "yes" a la confirmación del script
    if echo "yes" | bash "$SCRIPT_PATH" > "$RESULTS_DIR/${script%.sh}.log" 2>&1; then
        EXP_END=$(date +%s)
        EXP_DURATION=$((EXP_END - EXP_START))
        
        log_success "✅ $name completado en ${EXP_DURATION}s"
        EXPERIMENT_RESULTS+=("✅|$name|SUCCESS||$EXP_DURATION")
        ((SUCCESSFUL++))
    else
        EXP_END=$(date +%s)
        EXP_DURATION=$((EXP_END - EXP_START))
        
        log_error "❌ $name falló"
        EXPERIMENT_RESULTS+=("❌|$name|FAILED||$EXP_DURATION")
        ((FAILED++))
    fi
    
    # Esperar entre experimentos (excepto el último)
    if [ $EXPERIMENT_NUM -lt $TOTAL_EXPERIMENTS ]; then
        echo ""
        log_info "Esperando 30 segundos antes del siguiente experimento..."
        sleep 30
    fi
done

SUITE_END=$(date +%s)
SUITE_DURATION=$((SUITE_END - SUITE_START))

# ═══════════════════════════════════════════════════════════════
# 6. Generar reporte
# ═══════════════════════════════════════════════════════════════

REPORT_FILE="$RESULTS_DIR/SUITE-REPORT.md"

cat > "$REPORT_FILE" << EOF
# Chaos Engineering - Reporte de Suite Completa

## 📊 Resumen Ejecutivo

- **Fecha:** $(date '+%Y-%m-%d %H:%M:%S')
- **Duración Total:** ${SUITE_DURATION}s ($(($SUITE_DURATION / 60))m $(($SUITE_DURATION % 60))s)
- **Experimentos Totales:** $TOTAL_EXPERIMENTS
- **Exitosos:** $SUCCESSFUL ($(($SUCCESSFUL * 100 / $TOTAL_EXPERIMENTS))%)
- **Fallidos:** $FAILED ($(($FAILED * 100 / $TOTAL_EXPERIMENTS))%)

## 📈 Resultados por Experimento

| # | Experimento | Estado | Duración |
|---|-------------|--------|----------|
EOF

for i in "${!EXPERIMENT_RESULTS[@]}"; do
    IFS='|' read -r icon name status error duration <<< "${EXPERIMENT_RESULTS[$i]}"
    echo "| $((i + 1)) | $name | $icon $status | ${duration}s |" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" << EOF

## 🔍 Logs Individuales

EOF

for i in "${!EXPERIMENTS[@]}"; do
    IFS='|' read -r script name description <<< "${EXPERIMENTS[$i]}"
    echo "- **$name**: \`${script%.sh}.log\`" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" << EOF

## 💡 Interpretación

EOF

if [ $SUCCESSFUL -eq $TOTAL_EXPERIMENTS ]; then
    cat >> "$REPORT_FILE" << EOF
✅ **Todos los experimentos completados exitosamente**

El sistema demostró resiliencia bajo todas las condiciones de stress probadas:
- Soportó carga masiva (DoS)
- Mantuvo latencias aceptables bajo presión
- Manejó errores de mensajería (SNS)
- Resistió throttling de DynamoDB
- Validó correctamente requests inválidos
EOF
elif [ $SUCCESSFUL -gt $(($TOTAL_EXPERIMENTS / 2)) ]; then
    cat >> "$REPORT_FILE" << EOF
⚠️ **Mayoría de experimentos exitosos con algunas fallas**

El sistema mostró resiliencia general pero hay áreas de mejora:
- Revisar logs de experimentos fallidos
- Considerar aumentar capacidad en componentes bajo presión
- Verificar timeouts y circuit breakers
EOF
else
    cat >> "$REPORT_FILE" << EOF
❌ **Múltiples fallas detectadas**

El sistema requiere atención:
- Revisar configuración de infraestructura
- Aumentar capacidad de recursos (Lambda, DynamoDB)
- Implementar/mejorar circuit breakers
- Revisar manejo de errores
EOF
fi

# ═══════════════════════════════════════════════════════════════
# 7. Mostrar resumen
# ═══════════════════════════════════════════════════════════════

echo ""
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "   ✅ SUITE COMPLETADA"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📊 Resumen:"
echo "   Total: $TOTAL_EXPERIMENTS experimentos"
echo "   Exitosos: $SUCCESSFUL"
echo "   Fallidos: $FAILED"
echo "   Duración: ${SUITE_DURATION}s ($(($SUITE_DURATION / 60))m $(($SUITE_DURATION % 60))s)"
echo ""
echo "📁 Resultados:"
echo "   $RESULTS_DIR/"
echo "   - SUITE-REPORT.md"

for i in "${!EXPERIMENTS[@]}"; do
    IFS='|' read -r script name description <<< "${EXPERIMENTS[$i]}"
    echo "   - ${script%.sh}.log"
done

echo ""
echo "📝 Ver reporte completo:"
echo "   cat $REPORT_FILE"
echo ""
