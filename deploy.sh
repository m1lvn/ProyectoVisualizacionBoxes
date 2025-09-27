#!/bin/bash
# Script de despliegue para EC2
# Ejecutar desde el directorio raíz del proyecto después de hacer git pull

echo "🚀 Iniciando proceso de despliegue..."

# Verificar que estemos en el directorio correcto
if [ ! -f "serverless-api/serverless.yml" ]; then
    echo "❌ Error: No se encuentra serverless.yml"
    echo "Asegúrate de estar en el directorio raíz del proyecto"
    exit 1
fi

# Cambiar al directorio de la API
cd serverless-api

echo "📦 Instalando/actualizando dependencias..."
npm install

echo "🔍 Verificando configuración..."
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "⚠️  Variables de entorno AWS no configuradas"
    echo "Configura AWS_ACCESS_KEY_ID y AWS_SECRET_ACCESS_KEY"
    echo "O ejecuta: aws configure"
    read -p "¿Continuar de todas formas? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "🏗️  Desplegando infraestructura y funciones Lambda..."
npx serverless deploy --verbose

if [ $? -eq 0 ]; then
    echo "✅ Despliegue completado exitosamente"
    echo ""
    echo "📋 Próximos pasos:"
    echo "1. Ejecutar migración de datos: curl -X POST [API_ENDPOINT]/api/migrate"
    echo "2. Probar endpoints: curl [API_ENDPOINT]/api/pasillos"
    echo "3. Actualizar frontend Django con la nueva URL de API"
    echo ""
    echo "🔗 Para obtener la URL de la API ejecuta:"
    echo "   npx serverless info"
else
    echo "❌ Error durante el despliegue"
    echo "Revisa los logs arriba para más detalles"
    exit 1
fi