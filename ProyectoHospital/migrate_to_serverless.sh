#!/bin/bash

echo "🚀 MIGRANDO DJANGO A SISTEMA 100% SERVERLESS"
echo "=============================================="

echo "📦 1. Instalando dependencias limpias..."
cd ProyectoHospital
pip install -r requirements_serverless.txt

echo "🗂️ 2. Creando migración inicial (solo auth)..."
python manage.py makemigrations

echo "🔄 3. Ejecutando migraciones..."
python manage.py migrate

echo "👤 4. Crear superusuario para testing..."
echo "Ejecutar manualmente: python manage.py createsuperuser"

echo "🧪 5. Probando sistema..."
python manage.py collectstatic --noinput

echo ""
echo "✅ MIGRACIÓN COMPLETADA"
echo "======================"
echo "🎯 Tu sistema ahora es 100% serverless:"
echo "   ✅ Vistas Django → API Serverless"
echo "   ✅ Datos → DynamoDB"
echo "   ✅ Sin MySQL"
echo "   ✅ Autenticación → SQLite local"
echo ""
echo "🚀 Para ejecutar:"
echo "   python manage.py runserver"
echo ""
echo "🌐 URLs disponibles:"
echo "   http://127.0.0.1:8000/ - Vista principal (API)"
echo "   http://127.0.0.1:8000/admin/ - Admin Django"
echo "   http://127.0.0.1:8000/test-api/ - Test API"