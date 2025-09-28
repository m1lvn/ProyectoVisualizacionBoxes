#!/bin/bash

echo "🔧 REPARANDO CONFIGURACIÓN DJANGO PARA SISTEMA SERVERLESS"
echo "========================================================="

echo "📁 1. Verificando archivos..."
cd ~/ProyectoVisualizacionBoxes/ProyectoHospital

# Verificar que no hay imports de modelos MySQL en otros archivos
echo "🔍 Buscando imports problemáticos..."

# Buscar en apps.py
if grep -q "from .models import" visualizacionBoxes/apps.py 2>/dev/null; then
    echo "⚠️  Encontrado import problemático en apps.py"
fi

# Buscar imports en __init__.py
find . -name "*.py" -exec grep -l "from .models import.*Box\|Pasillo\|Agenda" {} \; 2>/dev/null

echo ""
echo "🗂️ 2. Eliminando archivos de migración antiguos..."
rm -rf visualizacionBoxes/migrations/0*.py 2>/dev/null
echo "# Migrations directory" > visualizacionBoxes/migrations/__init__.py

echo ""
echo "📦 3. Instalando dependencias..."
pip install requests django

echo ""
echo "🗂️ 4. Creando migración inicial limpia..."
python manage.py makemigrations visualizacionBoxes --empty

echo ""
echo "🔄 5. Ejecutando migraciones..."
python manage.py migrate

echo ""
echo "✅ REPARACIÓN COMPLETADA"
echo "======================="
echo "🎯 Ahora puedes ejecutar:"
echo "   python manage.py createsuperuser"
echo "   python manage.py runserver 0.0.0.0:8000"