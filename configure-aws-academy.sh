# Script para configurar credenciales AWS Academy en EC2
# EJECUTAR EN TU INSTANCIA EC2

#!/bin/bash

echo "🔐 Configurando credenciales AWS Academy..."

# Crear directorio AWS si no existe
mkdir -p ~/.aws

echo "📝 Configurando credenciales..."
echo "Necesitas copiar las credenciales desde AWS Academy Learner Lab"
echo ""
echo "1. Ve a AWS Academy Learner Lab"
echo "2. Click en 'AWS Details'"
echo "3. Click en 'Show' en la sección AWS CLI"
echo "4. Copia las tres líneas que aparecen"
echo ""

read -p "¿Ya tienes las credenciales copiadas? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Ve por las credenciales y ejecuta este script nuevamente"
    exit 1
fi

echo ""
echo "Pega las credenciales aquí (Ctrl+Shift+V):"
echo "Formato esperado:"
echo "aws_access_key_id=ASIA..."
echo "aws_secret_access_key=abc123..."
echo "aws_session_token=IQoJb3JpZ2lu..."
echo ""

echo -n "aws_access_key_id="
read AWS_ACCESS_KEY_ID

echo -n "aws_secret_access_key="
read -s AWS_SECRET_ACCESS_KEY
echo

echo -n "aws_session_token="
read -s AWS_SESSION_TOKEN
echo

# Configurar archivo credentials
cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id=$AWS_ACCESS_KEY_ID
aws_secret_access_key=$AWS_SECRET_ACCESS_KEY
aws_session_token=$AWS_SESSION_TOKEN
EOF

# Configurar región
cat > ~/.aws/config << EOF
[default]
region=us-east-1
output=json
EOF

echo "✅ Credenciales configuradas"

# Verificar configuración
echo "🔍 Verificando configuración..."
aws sts get-caller-identity

if [ $? -eq 0 ]; then
    echo "✅ Credenciales funcionando correctamente"
else
    echo "❌ Error en las credenciales. Verifica e intenta nuevamente"
fi