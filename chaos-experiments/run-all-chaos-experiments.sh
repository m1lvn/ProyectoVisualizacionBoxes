#!/bin/bash
# ════════════════════════════════════════════════════════════════
# CHAOS ENGINEERING - EJECUTAR SUITE COMPLETA DE EXPERIMENTOS
# ════════════════════════════════════════════════════════════════
#
# Este script ejecuta todos los experimentos de chaos engineering
# de forma secuencial y genera un reporte consolidado.
#
# USO:
#   ./run-all-chaos-experiments.sh
#   ./run-all-chaos-experiments.sh --skip-fis
#   ./run-all-chaos-experiments.sh --dry-run
#   ./run-all-chaos-experiments.sh --delay 30
#

# set -e  # Disabled for debugging - exits on any error

# Parsing arguments
SKIP_FIS=false  # Deprecated - Now all experiments are Bash
DRY_RUN=false
DELAY_BETWEEN_EXPERIMENTS=60

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-fis)
            SKIP_FIS=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --delay)
            DELAY_BETWEEN_EXPERIMENTS="$2"
            shift 2
            ;;
        *)
            echo "Uso: $0 [--skip-fis] [--dry-run] [--delay SECONDS]"
            exit 1
            ;;
    esac
done

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "   🔥 CHAOS ENGINEERING - SUITE COMPLETA DE EXPERIMENTOS"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Proyecto: Sistema de Visualización de Boxes Hospitalarios"
echo "Fecha: $(date +'%Y-%m-%d %H:%M:%S')"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo "🔍 MODO DRY RUN - No se ejecutarán cambios reales"
    echo ""
fi

# ═══════════════════════════════════════════════════════════════
# Configuración
# ═══════════════════════════════════════════════════════════════

SUITE_START_TIME=$(date +%s)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULTS_DIR="results/suite-$TIMESTAMP"

if [ "$DRY_RUN" = false ]; then
    mkdir -p "$RESULTS_DIR"
    echo "📁 Directorio de resultados: $RESULTS_DIR"
    echo ""
fi

# ═══════════════════════════════════════════════════════════════
# Pre-requisitos
# ═══════════════════════════════════════════════════════════════

echo "════════════════════════════════════════════════════════════════"
echo "   FASE 0: VERIFICACIÓN DE PRE-REQUISITOS"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar AWS CLI
echo "[✓] Verificando AWS CLI..."
if ! command -v aws &> /dev/null; then
    echo "    ❌ AWS CLI no instalado"
    exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "    ❌ AWS CLI no configurado"
    echo "    Ejecuta: aws configure"
    exit 1
fi

echo "    ✅ AWS configurado - Account: $AWS_ACCOUNT_ID"

# Verificar JWT Token
echo "[✓] Verificando JWT Token..."

if [ -f "get-jwt-from-secrets.sh" ]; then
    # Intentar obtener token con modo verbose para debug
    TOKEN_OUTPUT=$(./get-jwt-from-secrets.sh --verbose 2>&1)
    TOKEN_EXIT_CODE=$?
    TOKEN=$(echo "$TOKEN_OUTPUT" | tail -n1)
    
    if [ $TOKEN_EXIT_CODE -ne 0 ] || [ -z "$TOKEN" ] || [[ "$TOKEN" == *"ERROR"* ]]; then
        echo "    ⚠️  JWT Token no disponible desde Secrets Manager"
        echo ""
        echo "    [DEBUG] Detalles del error:"
        echo "$TOKEN_OUTPUT" | grep -E "\[ERROR\]|\[*\]|Secret:|Region:" | sed 's/^/    /'
        echo ""
        
        # Intentar leer directamente desde .env como alternativa
        if [ -f ".env" ]; then
            FALLBACK_TOKEN=$(grep "^JWT_TOKEN=" .env | cut -d'=' -f2- | xargs)
            if [ -n "$FALLBACK_TOKEN" ]; then
                echo "    ✅ JWT encontrado en .env (usando fallback)"
                TOKEN="$FALLBACK_TOKEN"
            else
                echo "    ⚠️  JWT no encontrado en .env tampoco"
                echo "    Ejecuta: ./setup-jwt-secrets-manager.sh"
                
                read -p "    ¿Continuar sin JWT? (algunos experimentos fallarán) (yes/no): " confirm
                if [ "$confirm" != "yes" ]; then
                    exit 1
                fi
            fi
        else
            echo "    Ejecuta: ./setup-jwt-secrets-manager.sh"
            
            read -p "    ¿Continuar sin JWT? (algunos experimentos fallarán) (yes/no): " confirm
            if [ "$confirm" != "yes" ]; then
                exit 1
            fi
        fi
    else
        echo "    ✅ JWT Token disponible"
    fi
else
    echo "    ⚠️  Script get-jwt-from-secrets.sh no encontrado"
fi

# ═══════════════════════════════════════════════════════════════
# Verificar scripts bash de simulación
# ═══════════════════════════════════════════════════════════════
echo "[✓] Verificando Bash simulation scripts..."

if [ -f "bash-scripts/04-dynamodb-throttling-sim.sh" ]; then
    echo "    ✅ DynamoDB throttling simulation disponible"
else
    echo "    ❌ bash-scripts/04-dynamodb-throttling-sim.sh NO ENCONTRADO"
    echo "    Este script simula throttling de DynamoDB"
    exit 1
fi

if [ -f "bash-scripts/05-lambda-errors-sim.sh" ]; then
    echo "    ✅ Lambda error injection simulation disponible"
else
    echo "    ❌ bash-scripts/05-lambda-errors-sim.sh NO ENCONTRADO"
    echo "    Este script simula inyección de errores en Lambda"
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "   ✅ PRE-REQUISITOS VERIFICADOS"
echo "   📝 Se ejecutarán 5 experimentos Bash"
echo "════════════════════════════════════════════════════════════════"
echo ""

sleep 2

# ═══════════════════════════════════════════════════════════════
# Definir experimentos
# ═══════════════════════════════════════════════════════════════

# Crear array de experimentos
declare -a EXPERIMENTS
EXPERIMENT_COUNT=0

# Experimento 1: DoS Attack
EXPERIMENTS[$EXPERIMENT_COUNT]="1|DoS Attack Simulation|Bash|bash-scripts/01-dos-attack.ps1|5|true|false"
((EXPERIMENT_COUNT++))

# Experimento 2: Lambda Latency
EXPERIMENTS[$EXPERIMENT_COUNT]="2|Lambda Latency Injection|Bash|bash-scripts/02-lambda-latency.sh|15|true|true"
((EXPERIMENT_COUNT++))

# Experimento 3: SNS Failure
EXPERIMENTS[$EXPERIMENT_COUNT]="3|SNS Topic Failure|Bash|bash-scripts/03-sns-failure.sh|10|false|true"
((EXPERIMENT_COUNT++))

# Experimento 4: DynamoDB Throttling Simulation
EXPERIMENTS[$EXPERIMENT_COUNT]="4|DynamoDB Throttling Simulation|Bash|bash-scripts/04-dynamodb-throttling-sim.sh|5|true|false"
((EXPERIMENT_COUNT++))

# Experimento 5: Lambda Error Injection Simulation
EXPERIMENTS[$EXPERIMENT_COUNT]="5|Lambda Error Injection Simulation|Bash|bash-scripts/05-lambda-errors-sim.sh|5|false|false"
((EXPERIMENT_COUNT++))

# Todos los experimentos están disponibles (no hay filtrado)
FILTERED_EXPERIMENTS=("${EXPERIMENTS[@]}")
FILTERED_COUNT=${#FILTERED_EXPERIMENTS[@]}

echo "📋 Experimentos a ejecutar: $FILTERED_COUNT"
echo ""

for exp in "${FILTERED_EXPERIMENTS[@]}"; do
    IFS='|' read -r id name category script duration critical requires_bash <<< "$exp"
    
    if [ "$critical" = "true" ]; then
        STATUS="🔴 Crítico"
    else
        STATUS="🟡 Opcional"
    fi
    
    echo "   [$id] $name - $category - $STATUS"
done

# Calcular tiempo estimado
TOTAL_DURATION=0
for exp in "${FILTERED_EXPERIMENTS[@]}"; do
    IFS='|' read -r id name category script duration critical requires_bash <<< "$exp"
    TOTAL_DURATION=$((TOTAL_DURATION + duration))
done

TOTAL_DELAY=$(( (FILTERED_COUNT - 1) * DELAY_BETWEEN_EXPERIMENTS ))
TOTAL_TIME=$(( (TOTAL_DURATION * 60 + TOTAL_DELAY) / 60 ))

echo ""
echo "Tiempo estimado: $TOTAL_TIME minutos"
echo ""

if [ "$DRY_RUN" = false ]; then
    read -p "¿Iniciar suite de experimentos? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Operación cancelada"
        exit 0
    fi
fi

echo ""

# ═══════════════════════════════════════════════════════════════
# Ejecutar experimentos
# ═══════════════════════════════════════════════════════════════

declare -a RESULTS
RESULT_COUNT=0
EXPERIMENT_NUMBER=1

for exp in "${FILTERED_EXPERIMENTS[@]}"; do
    IFS='|' read -r id name category script duration critical requires_bash <<< "$exp"
    
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "   EXPERIMENTO $EXPERIMENT_NUMBER/$FILTERED_COUNT: $name"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "Categoría: $category"
    echo "Duración estimada: $duration minutos"
    echo "Script: $script"
    echo ""
    
    EXP_START_TIME=$(date +%s)
    SUCCESS=true
    ERROR_MESSAGE=""
    
    if [ "$DRY_RUN" = true ]; then
        echo "🔍 DRY RUN - Simulando experimento..."
        sleep 2
    else
        # Parsear el script y argumentos
        read -ra SCRIPT_PARTS <<< "$script"
        SCRIPT_PATH="${SCRIPT_PARTS[0]}"
        SCRIPT_ARGS=("${SCRIPT_PARTS[@]:1}")
        
        if [ -f "$SCRIPT_PATH" ]; then
            # Dar permisos de ejecución
            chmod +x "$SCRIPT_PATH" 2>/dev/null || true
            
            # Ejecutar script
            if [ ${#SCRIPT_ARGS[@]} -gt 0 ]; then
                "./$SCRIPT_PATH" "${SCRIPT_ARGS[@]}" || {
                    SUCCESS=false
                    ERROR_MESSAGE="Script returned exit code: $?"
                }
            else
                "./$SCRIPT_PATH" || {
                    SUCCESS=false
                    ERROR_MESSAGE="Script returned exit code: $?"
                }
            fi
        else
            echo "    ❌ Script no encontrado: $SCRIPT_PATH"
            SUCCESS=false
            ERROR_MESSAGE="Script not found"
        fi
    fi
    
    EXP_END_TIME=$(date +%s)
    EXP_DURATION=$((EXP_END_TIME - EXP_START_TIME))
    
    # Registrar resultado
    RESULTS[$RESULT_COUNT]="$id|$name|$category|$SUCCESS|$EXP_DURATION|$ERROR_MESSAGE"
    ((RESULT_COUNT++))
    
    if [ "$SUCCESS" = true ]; then
        echo ""
        echo "✅ Experimento completado exitosamente (${EXP_DURATION}s)"
    else
        echo ""
        echo "❌ Experimento falló: $ERROR_MESSAGE"
    fi
    
    # Delay entre experimentos (excepto el último)
    if [ $EXPERIMENT_NUMBER -lt $FILTERED_COUNT ]; then
        echo ""
        echo "⏱️  Esperando $DELAY_BETWEEN_EXPERIMENTS segundos antes del siguiente experimento..."
        
        if [ "$DRY_RUN" = false ]; then
            sleep "$DELAY_BETWEEN_EXPERIMENTS"
        else
            sleep 2
        fi
    fi
    
    ((EXPERIMENT_NUMBER++))
done

# ═══════════════════════════════════════════════════════════════
# Reporte final
# ═══════════════════════════════════════════════════════════════

SUITE_END_TIME=$(date +%s)
SUITE_DURATION=$(( (SUITE_END_TIME - SUITE_START_TIME) / 60 ))

echo ""
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "   ✅ SUITE DE EXPERIMENTOS COMPLETADA"
echo "════════════════════════════════════════════════════════════════"
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0

for result in "${RESULTS[@]}"; do
    IFS='|' read -r id name category success duration error <<< "$result"
    if [ "$success" = "true" ]; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi
done

echo "📊 Resumen de Resultados:"
echo ""
echo "   Total de experimentos: $RESULT_COUNT"
echo "   ✅ Exitosos: $SUCCESS_COUNT"
echo "   ❌ Fallidos: $FAIL_COUNT"
echo "   ⏱️  Duración total: $SUITE_DURATION minutos"
echo ""

echo "📋 Detalle por experimento:"
echo ""

for result in "${RESULTS[@]}"; do
    IFS='|' read -r id name category success duration error <<< "$result"
    
    if [ "$success" = "true" ]; then
        STATUS="✅"
    else
        STATUS="❌"
    fi
    
    echo "   $STATUS [$id] $name"
    echo "      Categoría: $category | Duración: ${duration}s"
    
    if [ "$success" != "true" ]; then
        echo "      Error: $error"
    fi
    echo ""
done

# Guardar resultados
if [ "$DRY_RUN" = false ]; then
    SUMMARY_FILE="$RESULTS_DIR/suite-summary.json"
    
    # Construir JSON manualmente
    cat > "$SUMMARY_FILE" <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%S")Z",
  "duration": $SUITE_DURATION,
  "totalExperiments": $RESULT_COUNT,
  "successCount": $SUCCESS_COUNT,
  "failCount": $FAIL_COUNT,
  "experiments": [
EOF
    
    FIRST=true
    for result in "${RESULTS[@]}"; do
        IFS='|' read -r id name category success duration error <<< "$result"
        
        if [ "$FIRST" = false ]; then
            echo "," >> "$SUMMARY_FILE"
        fi
        FIRST=false
        
        cat >> "$SUMMARY_FILE" <<EOF
    {
      "id": $id,
      "name": "$name",
      "category": "$category",
      "success": $success,
      "duration": $duration,
      "error": "$error"
    }
EOF
    done
    
    echo "" >> "$SUMMARY_FILE"
    echo "  ]" >> "$SUMMARY_FILE"
    echo "}" >> "$SUMMARY_FILE"
    
    echo "💾 Resumen guardado en: $SUMMARY_FILE"
    echo ""
    
    # Generar reporte markdown
    REPORT_FILE="$RESULTS_DIR/SUITE-REPORT.md"
    
    cat > "$REPORT_FILE" <<EOF
# 🔥 Reporte de Suite de Chaos Engineering

## Información General

- **Fecha de Ejecución:** $(date +"%Y-%m-%d %H:%M:%S")
- **Duración Total:** $SUITE_DURATION minutos
- **Total de Experimentos:** $RESULT_COUNT
- **Experimentos Exitosos:** $SUCCESS_COUNT ✅
- **Experimentos Fallidos:** $FAIL_COUNT ❌
- **Tasa de Éxito:** $(( SUCCESS_COUNT * 100 / RESULT_COUNT ))%

## Resultados por Experimento

| # | Experimento | Categoría | Estado | Duración |
|---|-------------|-----------|--------|----------|
EOF
    
    for result in "${RESULTS[@]}"; do
        IFS='|' read -r id name category success duration error <<< "$result"
        
        if [ "$success" = "true" ]; then
            STATUS="✅ Exitoso"
        else
            STATUS="❌ Fallido"
        fi
        
        echo "| $id | $name | $category | $STATUS | ${duration}s |" >> "$REPORT_FILE"
    done
    
    cat >> "$REPORT_FILE" <<EOF

## Análisis de Resultados

### Experimentos Exitosos

EOF
    
    for result in "${RESULTS[@]}"; do
        IFS='|' read -r id name category success duration error <<< "$result"
        
        if [ "$success" = "true" ]; then
            cat >> "$REPORT_FILE" <<EOF

#### $name

- **Duración:** $duration segundos
- **Categoría:** $category
- **Resultado:** ✅ El experimento se ejecutó correctamente

EOF
        fi
    done
    
    if [ $FAIL_COUNT -gt 0 ]; then
        cat >> "$REPORT_FILE" <<EOF

### Experimentos Fallidos

EOF
        
        for result in "${RESULTS[@]}"; do
            IFS='|' read -r id name category success duration error <<< "$result"
            
            if [ "$success" != "true" ]; then
                cat >> "$REPORT_FILE" <<EOF

#### $name

- **Duración:** $duration segundos
- **Categoría:** $category
- **Error:** $error
- **Acción Requerida:** Investigar y corregir el problema

EOF
            fi
        done
    fi
    
    # Conclusión basada en resultados
    if [ $SUCCESS_COUNT -eq $RESULT_COUNT ]; then
        CONCLUSION="✅ Todos los experimentos se ejecutaron exitosamente. El sistema ha demostrado resiliencia ante los fallos simulados."
    elif [ $SUCCESS_COUNT -gt $FAIL_COUNT ]; then
        CONCLUSION="⚠️ La mayoría de los experimentos fueron exitosos, pero hay algunos fallos que requieren atención."
    else
        CONCLUSION="❌ Varios experimentos fallaron. Se requiere investigación y corrección de los problemas identificados."
    fi
    
    cat >> "$REPORT_FILE" <<EOF

## Conclusiones

$CONCLUSION

## Próximos Pasos

1. Analizar los resultados individuales de cada experimento
2. Revisar logs en CloudWatch para detalles adicionales
3. Implementar mejoras de resiliencia según hallazgos
4. Re-ejecutar experimentos fallidos después de correcciones

---

*Generado automáticamente por run-all-chaos-experiments.sh*
*Fecha: $(date +"%Y-%m-%d %H:%M:%S")*
EOF
    
    echo "📄 Reporte completo generado: $REPORT_FILE"
    echo ""
fi

echo "════════════════════════════════════════════════════════════════"
echo ""

if [ "$DRY_RUN" = false ]; then
    echo "📁 Todos los resultados están en: $RESULTS_DIR"
    echo ""
fi

echo "¡Gracias por ejecutar los experimentos de Chaos Engineering! 🎉"
echo ""
