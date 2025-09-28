#!/bin/bash

# Script para instalar dependencias y ejecutar migración en EC2
echo "🚀 Configurando migración MySQL → DynamoDB"

# Instalar dependencias Python
echo "📦 Instalando dependencias..."
pip install mysql-connector-python boto3

# Verificar credenciales AWS
echo "🔑 Verificando credenciales AWS..."
aws sts get-caller-identity

if [ $? -eq 0 ]; then
    echo "✅ Credenciales AWS configuradas correctamente"
    echo ""
    echo "📋 INSTRUCCIONES:"
    echo "1. Editar migrate_local.py y ajustar:"
    echo "   - MYSQL_CONFIG (usuario, password, database)"
    echo ""  
    echo "2. Ejecutar migración:"
    echo "   python3 migrate_local.py"
    echo ""
    echo "3. Verificar resultados:"
    echo "   curl https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api/boxes"
else
    echo "❌ Credenciales AWS no configuradas"
    echo "💡 Ejecuta primero: ./configure-aws-academy.sh"
fi