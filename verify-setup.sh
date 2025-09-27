#!/bin/bash
# Script de verificación para AWS Academy + Serverless Framework
# Ejecutar en EC2 después de configurar credenciales

echo "🔍 VERIFICADOR DE CONFIGURACIÓN AWS ACADEMY + SERVERLESS"
echo "======================================================"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error_count=0

# 1. Verificar Node.js
echo -e "\n📦 Verificando Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✅ Node.js instalado: $NODE_VERSION${NC}"
else
    echo -e "${RED}❌ Node.js no instalado${NC}"
    ((error_count++))
fi

# 2. Verificar npm
echo -e "\n📦 Verificando npm..."
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✅ npm instalado: $NPM_VERSION${NC}"
else
    echo -e "${RED}❌ npm no instalado${NC}"
    ((error_count++))
fi

# 3. Verificar Serverless Framework
echo -e "\n⚡ Verificando Serverless Framework..."
if command -v serverless &> /dev/null; then
    SLS_VERSION=$(serverless --version | head -n 1)
    echo -e "${GREEN}✅ Serverless Framework instalado: $SLS_VERSION${NC}"
else
    echo -e "${RED}❌ Serverless Framework no instalado${NC}"
    echo -e "${YELLOW}💡 Para instalar: npm install -g serverless${NC}"
    ((error_count++))
fi

# 4. Verificar AWS CLI
echo -e "\n☁️  Verificando AWS CLI..."
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version)
    echo -e "${GREEN}✅ AWS CLI instalado: $AWS_VERSION${NC}"
else
    echo -e "${YELLOW}⚠️  AWS CLI no instalado (opcional pero recomendado)${NC}"
fi

# 5. Verificar credenciales AWS
echo -e "\n🔐 Verificando credenciales AWS..."
if aws sts get-caller-identity &> /dev/null; then
    ACCOUNT_INFO=$(aws sts get-caller-identity)
    ACCOUNT_ID=$(echo $ACCOUNT_INFO | jq -r '.Account' 2>/dev/null || echo "N/A")
    USER_ARN=$(echo $ACCOUNT_INFO | jq -r '.Arn' 2>/dev/null || echo "N/A")
    echo -e "${GREEN}✅ Credenciales AWS válidas${NC}"
    echo -e "   Account ID: $ACCOUNT_ID"
    echo -e "   User ARN: $USER_ARN"
else
    echo -e "${RED}❌ Credenciales AWS no válidas o no configuradas${NC}"
    echo -e "${YELLOW}💡 Ejecuta: ./configure-aws-academy.sh${NC}"
    ((error_count++))
fi

# 6. Verificar región AWS
echo -e "\n🌍 Verificando región AWS..."
AWS_REGION=$(aws configure get region 2>/dev/null || echo "not-set")
if [ "$AWS_REGION" = "not-set" ]; then
    echo -e "${YELLOW}⚠️  Región AWS no configurada (usando us-east-1 por defecto)${NC}"
else
    echo -e "${GREEN}✅ Región AWS configurada: $AWS_REGION${NC}"
fi

# 7. Verificar estructura del proyecto
echo -e "\n📁 Verificando estructura del proyecto..."
if [ -f "serverless-api/serverless.yml" ]; then
    echo -e "${GREEN}✅ serverless.yml encontrado${NC}"
else
    echo -e "${RED}❌ serverless.yml no encontrado en serverless-api/${NC}"
    ((error_count++))
fi

if [ -f "serverless-api/package.json" ]; then
    echo -e "${GREEN}✅ package.json encontrado${NC}"
else
    echo -e "${RED}❌ package.json no encontrado en serverless-api/${NC}"
    ((error_count++))
fi

# 8. Verificar dependencias npm
echo -e "\n📦 Verificando dependencias npm..."
if [ -d "serverless-api/node_modules" ]; then
    echo -e "${GREEN}✅ Dependencias npm instaladas${NC}"
else
    echo -e "${YELLOW}⚠️  Dependencias npm no instaladas${NC}"
    echo -e "${YELLOW}💡 Ejecuta: cd serverless-api && npm install${NC}"
fi

# 9. Test de conectividad con AWS
echo -e "\n🔌 Test de conectividad con AWS..."
if aws dynamodb list-tables --region us-east-1 &> /dev/null; then
    echo -e "${GREEN}✅ Conectividad con DynamoDB OK${NC}"
else
    echo -e "${YELLOW}⚠️  No se puede conectar con DynamoDB (puede ser normal si no hay tablas)${NC}"
fi

# Resumen final
echo -e "\n📊 RESUMEN"
echo "=========="
if [ $error_count -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡Todo configurado correctamente!${NC}"
    echo -e "${GREEN}✅ Puedes proceder con el despliegue: ./deploy.sh${NC}"
else
    echo -e "${RED}❌ Se encontraron $error_count problemas${NC}"
    echo -e "${YELLOW}🔧 Soluciona los problemas marcados arriba antes de continuar${NC}"
fi

echo -e "\n📋 PRÓXIMOS PASOS:"
echo "1. Si todo está OK: cd serverless-api && serverless deploy"
echo "2. Una vez desplegado: curl -X POST [API-URL]/api/migrate"
echo "3. Probar endpoints: curl [API-URL]/api/pasillos"

echo -e "\n💡 RECORDATORIOS PARA AWS ACADEMY:"
echo "- Las credenciales expiran cada pocas horas"
echo "- Recuerda renovar credenciales cuando caduquen"
echo "- El lab debe estar en estado 'green/ready' para funcionar"