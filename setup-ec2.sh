#!/bin/bash
# Script para configurar AWS y Serverless en EC2
# Ejecutar este script en tu instancia EC2 después del git pull

echo "🚀 Configurando entorno AWS en EC2..."

# Instalar Node.js si no está instalado
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Instalar Serverless Framework globalmente
sudo npm install -g serverless

# Verificar instalación
echo "✅ Versiones instaladas:"
node --version
npm --version
serverless --version

echo "🔑 Configurando credenciales AWS..."
echo "IMPORTANTE: Debes ejecutar 'aws configure' manualmente después de este script"
echo "O configurar variables de entorno:"
echo "export AWS_ACCESS_KEY_ID=tu-access-key"
echo "export AWS_SECRET_ACCESS_KEY=tu-secret-key" 
echo "export AWS_DEFAULT_REGION=us-east-1"

# Instalar dependencias del proyecto
if [ -d "serverless-api" ]; then
    cd serverless-api
    echo "📦 Instalando dependencias del proyecto..."
    npm install
    echo "✅ Setup completado. Ahora puedes ejecutar 'serverless deploy'"
else
    echo "❌ Error: Directorio serverless-api no encontrado"
    echo "Asegúrate de estar en el directorio raíz del proyecto"
fi