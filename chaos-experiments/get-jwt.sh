#!/bin/bash
# ════════════════════════════════════════════════════════════════
# Script para obtener JWT Token automáticamente desde Cognito
# ════════════════════════════════════════════════════════════════

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Cargar variables de .env
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

API_ENDPOINT="${API_ENDPOINT:-https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api}"

# Solicitar credenciales
echo -e "${CYAN}🔐 Obtener JWT Token desde Cognito${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""

if [ -z "$1" ]; then
    read -p "Usuario (email): " USERNAME
else
    USERNAME="$1"
fi

if [ -z "$2" ]; then
    read -sp "Password: " PASSWORD
    echo ""
else
    PASSWORD="$2"
fi

echo ""
echo -e "${YELLOW}📡 Conectando a: $API_ENDPOINT${NC}"

# Hacer login
RESPONSE=$(curl -s -X POST "$API_ENDPOINT/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}")

# Verificar si el login fue exitoso
if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo ""
    echo -e "${GREEN}✅ Login exitoso!${NC}"
    echo ""
    
    # Extraer el JWT token
    JWT_TOKEN=$(echo "$RESPONSE" | grep -o '"idToken":"[^"]*' | sed 's/"idToken":"//')
    EXPIRES_IN=$(echo "$RESPONSE" | grep -o '"expiresIn":[0-9]*' | sed 's/"expiresIn"://')
    
    # Actualizar el archivo .env
    if grep -q "JWT_TOKEN=" .env; then
        sed -i "s|JWT_TOKEN=.*|JWT_TOKEN=$JWT_TOKEN|" .env
    else
        echo "JWT_TOKEN=$JWT_TOKEN" >> .env
    fi
    
    echo -e "${GREEN}✅ JWT Token guardado en .env${NC}"
    echo ""
    echo -e "${CYAN}📋 Token (primeros 50 caracteres):${NC}"
    echo -e "${NC}${JWT_TOKEN:0:50}...${NC}"
    echo ""
    
    MINUTES=$((EXPIRES_IN / 60))
    echo -e "${YELLOW}⏱️  Expira en: $EXPIRES_IN segundos ($MINUTES minutos)${NC}"
    echo ""
    echo -e "${GREEN}✨ Ahora puedes ejecutar los experimentos de chaos:${NC}"
    echo -e "   ${NC}cd bash-scripts${NC}"
    echo -e "   ${NC}./01-dos-attack.sh${NC}"
    
else
    echo ""
    echo -e "${RED}❌ Error en login:${NC}"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
    echo ""
    echo -e "${YELLOW}💡 Verifica que:${NC}"
    echo -e "   ${NC}1. El usuario existe en Cognito${NC}"
    echo -e "   ${NC}2. El password es correcto${NC}"
    echo -e "   ${NC}3. El usuario está confirmado${NC}"
    echo -e "   ${NC}4. La API está desplegada correctamente${NC}"
    exit 1
fi
