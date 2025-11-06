#!/bin/bash
# ════════════════════════════════════════════════════════════════
# Instalar dependencias para Chaos Engineering en Linux
# ════════════════════════════════════════════════════════════════

set -e

echo "════════════════════════════════════════════════════════════"
echo "   INSTALACIÓN DE DEPENDENCIAS - CHAOS ENGINEERING"
echo "════════════════════════════════════════════════════════════"
echo ""

# Detectar OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    echo "Sistema operativo detectado: $PRETTY_NAME"
else
    echo "⚠️  No se pudo detectar el sistema operativo"
    OS="unknown"
fi

echo ""

# ═══════════════════════════════════════════════════════════════
# 1. Actualizar repositorios
# ═══════════════════════════════════════════════════════════════

echo "[1/6] Actualizando repositorios..."

case "$OS" in
    ubuntu|debian)
        sudo apt-get update -qq
        ;;
    amzn|rhel|centos|fedora)
        sudo yum update -y -q
        ;;
    *)
        echo "⚠️  Sistema operativo no reconocido, saltando actualización..."
        ;;
esac

echo "   ✅ Repositorios actualizados"

# ═══════════════════════════════════════════════════════════════
# 2. Instalar AWS CLI
# ═══════════════════════════════════════════════════════════════

echo ""
echo "[2/6] Verificando AWS CLI..."

if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1)
    echo "   ✅ AWS CLI ya instalado: $AWS_VERSION"
else
    echo "   Instalando AWS CLI v2..."
    
    cd /tmp
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
    
    if command -v aws &> /dev/null; then
        echo "   ✅ AWS CLI instalado exitosamente"
    else
        echo "   ❌ Error instalando AWS CLI"
        exit 1
    fi
fi

# ═══════════════════════════════════════════════════════════════
# 3. Instalar Python3 y pip
# ═══════════════════════════════════════════════════════════════

echo ""
echo "[3/6] Verificando Python3..."

if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "   ✅ Python3 ya instalado: $PYTHON_VERSION"
else
    echo "   Instalando Python3..."
    
    case "$OS" in
        ubuntu|debian)
            sudo apt-get install -y -qq python3 python3-pip
            ;;
        amzn|rhel|centos|fedora)
            sudo yum install -y -q python3 python3-pip
            ;;
    esac
    
    if command -v python3 &> /dev/null; then
        echo "   ✅ Python3 instalado exitosamente"
    else
        echo "   ❌ Error instalando Python3"
        exit 1
    fi
fi

# ═══════════════════════════════════════════════════════════════
# 4. Instalar curl
# ═══════════════════════════════════════════════════════════════

echo ""
echo "[4/6] Verificando curl..."

if command -v curl &> /dev/null; then
    CURL_VERSION=$(curl --version | head -n1)
    echo "   ✅ curl ya instalado: $CURL_VERSION"
else
    echo "   Instalando curl..."
    
    case "$OS" in
        ubuntu|debian)
            sudo apt-get install -y -qq curl
            ;;
        amzn|rhel|centos|fedora)
            sudo yum install -y -q curl
            ;;
    esac
    
    if command -v curl &> /dev/null; then
        echo "   ✅ curl instalado exitosamente"
    else
        echo "   ❌ Error instalando curl"
        exit 1
    fi
fi

# ═══════════════════════════════════════════════════════════════
# 5. Instalar jq (opcional pero útil)
# ═══════════════════════════════════════════════════════════════

echo ""
echo "[5/6] Verificando jq..."

if command -v jq &> /dev/null; then
    JQ_VERSION=$(jq --version)
    echo "   ✅ jq ya instalado: $JQ_VERSION"
else
    echo "   Instalando jq..."
    
    case "$OS" in
        ubuntu|debian)
            sudo apt-get install -y -qq jq
            ;;
        amzn|rhel|centos|fedora)
            sudo yum install -y -q jq
            ;;
    esac
    
    if command -v jq &> /dev/null; then
        echo "   ✅ jq instalado exitosamente"
    else
        echo "   ⚠️  jq no se pudo instalar (opcional)"
    fi
fi

# ═══════════════════════════════════════════════════════════════
# 6. Dar permisos de ejecución a scripts
# ═══════════════════════════════════════════════════════════════

echo ""
echo "[6/6] Configurando permisos de scripts..."

# Scripts principales
chmod +x setup-jwt-secrets-manager.sh 2>/dev/null || true
chmod +x get-jwt-from-secrets.sh 2>/dev/null || true
chmod +x verify-fis-setup.sh 2>/dev/null || true
chmod +x run-fis-experiment.sh 2>/dev/null || true
chmod +x run-all-chaos-experiments.sh 2>/dev/null || true

# Scripts de experimentos
chmod +x bash-scripts/*.sh 2>/dev/null || true

echo "   ✅ Permisos configurados"

# ═══════════════════════════════════════════════════════════════
# Resumen
# ═══════════════════════════════════════════════════════════════

echo ""
echo "════════════════════════════════════════════════════════════"
echo "   ✅ INSTALACIÓN COMPLETADA"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Dependencias instaladas:"
echo "   ✅ AWS CLI $(aws --version 2>&1 | cut -d' ' -f1)"
echo "   ✅ Python3 $(python3 --version | cut -d' ' -f2)"
echo "   ✅ curl $(curl --version | head -n1 | cut -d' ' -f2)"

if command -v jq &> /dev/null; then
    echo "   ✅ jq $(jq --version)"
fi

echo ""
echo "Próximos pasos:"
echo ""
echo "1. Configurar AWS CLI (si aún no lo has hecho):"
echo "   aws configure"
echo ""
echo "2. Configurar JWT Token en Secrets Manager:"
echo "   ./setup-jwt-secrets-manager.sh"
echo ""
echo "3. Ejecutar suite de experimentos:"
echo "   ./run-all-chaos-experiments.sh"
echo ""
