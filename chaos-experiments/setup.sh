#!/bin/bash
# ════════════════════════════════════════════════════════════════
# Setup para Chaos Engineering
# ════════════════════════════════════════════════════════════════
# 
# Este script configura automáticamente:
# 1. Obtiene JWT token de Cognito User Pool
# 2. Detecta API Gateway endpoint
# 3. Actualiza archivo .env
#
# Uso: ./setup.sh [--verbose]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
VERBOSE=false

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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

verbose_log() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Parsear argumentos
# ═══════════════════════════════════════════════════════════════

for arg in "$@"; do
    case $arg in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
    esac
done

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "   🔧 SETUP DE CHAOS ENGINEERING"
echo "════════════════════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════════════════
# 1. Verificar Python 3
# ═══════════════════════════════════════════════════════════════

log_info "Verificando Python 3..."
if ! command -v python3 &> /dev/null; then
    log_error "Python 3 no está instalado"
    exit 1
fi
verbose_log "Python 3 encontrado: $(python3 --version)"

# ═══════════════════════════════════════════════════════════════
# 2. Instalar dependencias Python si es necesario
# ═══════════════════════════════════════════════════════════════

log_info "Verificando dependencias Python..."
if ! python3 -c "import boto3" &> /dev/null; then
    log_warning "Instalando boto3..."
    pip3 install boto3 --quiet
fi
verbose_log "boto3 instalado correctamente"

# ═══════════════════════════════════════════════════════════════
# 3. Ejecutar script Python para obtener JWT y API endpoint
# ═══════════════════════════════════════════════════════════════

log_info "Obteniendo configuración de AWS..."
log_info "  - Consultando CloudFormation stack"
log_info "  - Autenticando con Cognito User Pool"
log_info "  - Detectando API Gateway endpoint"
echo ""

if [ "$VERBOSE" = true ]; then
    python3 "$SCRIPT_DIR/get-cognito-jwt.py" --verbose
else
    python3 "$SCRIPT_DIR/get-cognito-jwt.py"
fi

if [ $? -ne 0 ]; then
    log_error "Falló la obtención de JWT o endpoint"
    exit 1
fi

# ═══════════════════════════════════════════════════════════════
# 4. Verificar que .env fue creado/actualizado
# ═══════════════════════════════════════════════════════════════

if [ ! -f "$ENV_FILE" ]; then
    log_error "Archivo .env no fue creado"
    exit 1
fi

# Cargar variables del .env
export $(cat "$ENV_FILE" | grep -v '^#' | grep -v '^$' | xargs)

if [ -z "$JWT_TOKEN" ]; then
    log_error "JWT_TOKEN no está en .env"
    exit 1
fi

if [ -z "$API_ENDPOINT" ]; then
    log_error "API_ENDPOINT no está en .env"
    exit 1
fi

# ═══════════════════════════════════════════════════════════════
# 5. Validar token con request de prueba
# ═══════════════════════════════════════════════════════════════

log_info "Validando token con API..."
RESPONSE=$(curl -s -w "\n%{http_code}" \
    --max-time 10 \
    "$API_ENDPOINT/api/boxes" \
    -H "Authorization: Bearer $JWT_TOKEN" 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "200" ]; then
    log_success "✅ Token válido - API respondió correctamente"
else
    log_error "❌ Token inválido o API no responde (HTTP $HTTP_CODE)"
    exit 1
fi

# ═══════════════════════════════════════════════════════════════
# Resumen
# ═══════════════════════════════════════════════════════════════

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "   ✅ CONFIGURACIÓN COMPLETADA"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📊 Configuración guardada en: $ENV_FILE"
echo ""
echo "🔑 JWT Token: ${JWT_TOKEN:0:50}..."
echo "🌐 API Endpoint: $API_ENDPOINT"
echo ""
echo "⏱️  Token válido por: 60 minutos"
echo ""
echo "🚀 Para ejecutar los experimentos:"
echo "   ./run-all-experiments.sh"
echo ""
