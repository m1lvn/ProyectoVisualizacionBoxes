#!/bin/bash

echo "🔍 VERIFICACIÓN COMPLETA DE IMPORTS PROBLEMÁTICOS"
echo "================================================"

cd ~/ProyectoVisualizacionBoxes/ProyectoHospital

echo "📁 Buscando imports de modelos eliminados..."

# Buscar todas las referencias a los modelos eliminados
echo ""
echo "🔍 Archivos que importan Box, Agenda, Pasillo, etc:"
find . -name "*.py" -exec grep -l "from.*models.*import.*\(Box\|Agenda\|Pasillo\|Especialidad\|Profesional\|TipoUsuario\|Tipoagenda\)" {} \; 2>/dev/null

echo ""
echo "🔍 Referencias directas a modelos eliminados:"
find . -name "*.py" -exec grep -l "\(Box\|Agenda\|Pasillo\|Especialidad\|Profesional\|TipoUsuario\|Tipoagenda\)\.objects" {} \; 2>/dev/null

echo ""
echo "🔍 Verificando archivos clave..."

# Verificar archivos específicos
FILES_TO_CHECK=(
    "visualizacionBoxes/models.py"
    "visualizacionBoxes/admin.py" 
    "visualizacionBoxes/views.py"
    "visualizacionBoxes/adapters.py"
    "visualizacionBoxes/apps.py"
)

for file in "${FILES_TO_CHECK[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file existe"
        # Verificar imports problemáticos
        if grep -q "from.*models.*import.*\(Box\|Agenda\|TipoUsuario\)" "$file" 2>/dev/null; then
            echo "   ⚠️  Tiene imports problemáticos"
        else
            echo "   ✅ Imports limpios"
        fi
    else
        echo "❌ $file no existe"
    fi
done

echo ""
echo "🧹 LIMPIEZA AUTOMÁTICA"
echo "===================="

# Eliminar archivos de migración problemáticos
echo "📂 Limpiando migraciones..."
find visualizacionBoxes/migrations/ -name "0*.py" -delete 2>/dev/null
echo "# Auto-generated migrations" > visualizacionBoxes/migrations/__init__.py

# Verificar que __pycache__ no tenga archivos problemáticos
echo "🗂️ Limpiando cache Python..."
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null

echo ""
echo "✅ VERIFICACIÓN COMPLETADA"
echo "========================="
echo "🎯 Ejecutar para continuar:"
echo "   python manage.py makemigrations"
echo "   python manage.py migrate"