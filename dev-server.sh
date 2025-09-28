#!/bin/bash
# dev-server.sh - Script rápido para iniciar desarrollo

echo "🚀 Iniciando servidor de desarrollo Hospital..."
echo "📍 URL: http://localhost:8000"
echo "🔄 Hot reload activo - los cambios se verán automáticamente"
echo "⏹️  Presiona Ctrl+C para detener"
echo ""

# Verificar que estamos en el lugar correcto
if [ ! -d "ProyectoHospital" ]; then
    echo "❌ Error: Ejecuta desde la raíz del proyecto"
    exit 1
fi

# Cambiar al directorio de Django
cd ProyectoHospital

# Verificar si el entorno virtual está activo
if [ -z "$VIRTUAL_ENV" ]; then
    echo "⚠️  Recomendación: Activa el entorno virtual primero"
    echo "   source .venv/bin/activate  # Linux/Mac"
    echo "   .venv\\Scripts\\activate    # Windows"
    echo ""
fi

# Verificar configuración
if [ ! -f "db.sqlite3" ]; then
    echo "⚙️ Primera vez - configurando base de datos..."
    python manage.py migrate
    echo ""
    echo "👤 Crear superusuario (opcional):"
    python manage.py createsuperuser
fi

# Iniciar servidor
echo "🌐 Iniciando Django en http://localhost:8000"
python manage.py runserver 0.0.0.0:8000