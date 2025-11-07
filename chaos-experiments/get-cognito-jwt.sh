#!/bin/bash

# Script para obtener JWT token desde Cognito User Pool
# Uso: ./get-cognito-jwt.sh [--verbose] [--user admin|personal|test]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/get-cognito-jwt.py"

# Verificar que el script Python existe
if [ ! -f "$PYTHON_SCRIPT" ]; then
    echo "❌ Error: No se encuentra get-cognito-jwt.py"
    exit 1
fi

# Activar entorno virtual si existe
if [ -f "$HOME/.venv/bin/activate" ]; then
    source "$HOME/.venv/bin/activate"
fi

# Verificar boto3
if ! python3 -c "import boto3" 2>/dev/null; then
    echo "❌ Error: boto3 no está instalado"
    echo "💡 Instalar con: pip install boto3"
    exit 1
fi

# Parsear argumentos
VERBOSE=false
USER_TYPE="admin"

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --user)
            USER_TYPE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Uso: $0 [--verbose] [--user admin|personal|test]"
            echo ""
            echo "Obtiene JWT token desde Cognito User Pool y actualiza .env"
            echo ""
            echo "Opciones:"
            echo "  --verbose, -v     Mostrar output detallado"
            echo "  --user TYPE       Tipo de usuario (admin|personal|test)"
            echo "  --help, -h        Mostrar esta ayuda"
            echo ""
            echo "Variables de entorno:"
            echo "  TEST_USER         Override del tipo de usuario (admin|personal|test)"
            exit 0
            ;;
        *)
            echo "❌ Argumento desconocido: $1"
            echo "Usa --help para ver opciones disponibles"
            exit 1
            ;;
    esac
done

# Exportar tipo de usuario
export TEST_USER="$USER_TYPE"

# Ejecutar script Python
if [ "$VERBOSE" = true ]; then
    JWT_TOKEN=$(python3 "$PYTHON_SCRIPT")
    EXIT_CODE=$?
else
    # Capturar solo errores, no el output informativo
    JWT_TOKEN=$(python3 "$PYTHON_SCRIPT" 2>/dev/null)
    EXIT_CODE=$?
fi

if [ $EXIT_CODE -ne 0 ]; then
    echo "❌ Error obteniendo JWT token" >&2
    echo "💡 Usa --verbose para ver detalles del error" >&2
    exit $EXIT_CODE
fi

# Verificar que obtuvimos un token
if [ -z "$JWT_TOKEN" ]; then
    echo "❌ No se obtuvo token JWT" >&2
    exit 1
fi

# Imprimir token en stdout (para captura en scripts)
echo "$JWT_TOKEN"

exit 0
