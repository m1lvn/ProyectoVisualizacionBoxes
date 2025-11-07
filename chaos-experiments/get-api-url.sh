#!/bin/bash
# Script helper para obtener la URL de API Gateway correcta

echo "🔍 Buscando tu API Gateway URL..."
echo ""

# Método 1: Desde settings.py de Django
if [ -f "../ProyectoHospital/ProyectoHospital/settings.py" ]; then
    echo "📄 Método 1: Desde settings.py de Django"
    AUTH_URL=$(grep "SERVERLESS_AUTH_URL" ../ProyectoHospital/ProyectoHospital/settings.py | cut -d "'" -f2)
    
    if [ -n "$AUTH_URL" ]; then
        echo "   ✅ Encontrado en settings.py:"
        echo "   $AUTH_URL"
        echo ""
        echo "   Usa esta URL en tu .env:"
        echo "   SERVERLESS_AUTH_URL=$AUTH_URL"
        exit 0
    fi
fi

# Método 2: Desde AWS CLI
echo "📡 Método 2: Consultando AWS API Gateway..."
if command -v aws &> /dev/null; then
    # Obtener todas las APIs
    echo ""
    echo "   APIs disponibles:"
    aws apigateway get-rest-apis --query 'items[*].[name,id]' --output table 2>/dev/null
    
    # Intentar encontrar automáticamente
    API_ID=$(aws apigateway get-rest-apis --query 'items[?contains(name, `serverless`) || contains(name, `hospital`)].id' --output text 2>/dev/null | head -n1)
    
    if [ -n "$API_ID" ]; then
        AWS_REGION=$(aws configure get region || echo "us-east-1")
        AUTH_URL="https://${API_ID}.execute-api.${AWS_REGION}.amazonaws.com"
        
        echo ""
        echo "   ✅ URL detectada automáticamente:"
        echo "   $AUTH_URL"
        echo ""
        echo "   Usa esta URL en tu .env:"
        echo "   SERVERLESS_AUTH_URL=$AUTH_URL"
        exit 0
    fi
fi

# Método 3: Manual
echo ""
echo "❌ No se pudo detectar automáticamente."
echo ""
echo "📋 Opciones manuales:"
echo ""
echo "   1. Busca en settings.py:"
echo "      cat ../ProyectoHospital/ProyectoHospital/settings.py | grep SERVERLESS_AUTH_URL"
echo ""
echo "   2. O desde AWS Console:"
echo "      https://console.aws.amazon.com/apigateway"
echo "      → Selecciona tu API"
echo "      → Stages → dev"
echo "      → Copia 'Invoke URL'"
echo ""
echo "   3. O desde AWS CLI:"
echo "      aws apigateway get-rest-apis"
echo ""
