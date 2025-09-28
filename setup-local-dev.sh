#!/bin/bash
# setup-local-dev.sh - Configuración rápida para desarrollo local

echo "🚀 Configurando desarrollo local del Hospital..."

# Verificar que estamos en el directorio correcto
if [ ! -f "README.md" ] || [ ! -d "ProyectoHospital" ]; then
    echo "❌ Error: Ejecuta este script desde la raíz del proyecto ProyectoVisualizacionBoxes"
    exit 1
fi

# 1. Configurar Django para desarrollo
echo "⚙️ Configurando Django..."
cd ProyectoHospital

# Backup de settings si no existe
if [ ! -f "ProyectoHospital/settings_production.py" ]; then
    cp ProyectoHospital/settings.py ProyectoHospital/settings_production.py
    echo "✅ Backup de settings creado"
fi

# Configurar settings para desarrollo local
cat > ProyectoHospital/settings_local.py << 'EOF'
from .settings import *

# Configuración para desarrollo local
DEBUG = True
ALLOWED_HOSTS = ['localhost', '127.0.0.1', '0.0.0.0', '*']

# API de producción (cambiar si usas API local)
SERVERLESS_API_URL = 'https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api'

# Base de datos local para autenticación
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# Static files para desarrollo
STATIC_URL = '/static/'
STATICFILES_DIRS = [
    BASE_DIR / 'visualizacionBoxes' / 'static',
]

# Templates debug
TEMPLATES[0]['OPTIONS']['debug'] = True

# Logging para desarrollo
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
}

print("🔧 Django configurado para desarrollo local")
EOF

# Usar configuración local por defecto
cp ProyectoHospital/settings_local.py ProyectoHospital/settings.py

# 2. Instalar dependencias Python si es necesario
echo "📦 Verificando dependencias Python..."
if [ ! -d ".venv" ]; then
    echo "🐍 Creando entorno virtual..."
    python -m venv .venv
    echo "✅ Entorno virtual creado"
fi

# Activar entorno virtual (instrucción para el usuario)
echo "⚠️  Activa el entorno virtual con:"
echo "   Linux/Mac: source .venv/bin/activate"
echo "   Windows: .venv\\Scripts\\activate"

# Verificar si requirements.txt existe
if [ -f "requirements.txt" ]; then
    echo "📋 Para instalar dependencias ejecuta:"
    echo "   pip install -r requirements.txt"
else
    echo "📋 Instalando dependencias básicas..."
    # Crear requirements.txt básico si no existe
    cat > requirements.txt << 'EOF'
Django==4.2.21
requests==2.31.0
django-allauth==0.54.0
Pillow==10.0.0
EOF
    echo "✅ requirements.txt creado"
fi

# 3. Configurar base de datos
echo "🗄️ Configurando base de datos local..."
if [ ! -f "db.sqlite3" ]; then
    echo "📋 Para configurar la base de datos ejecuta:"
    echo "   python manage.py migrate"
    echo "   python manage.py createsuperuser"
else
    echo "✅ Base de datos ya existe"
fi

# 4. Crear script de desarrollo rápido
echo "⚡ Creando script de desarrollo rápido..."
cat > dev-server.sh << 'EOF'
#!/bin/bash
echo "🚀 Iniciando servidor de desarrollo..."
echo "📍 URL: http://localhost:8000"
echo "🔄 Hot reload activo - los cambios se verán automáticamente"
echo "⏹️  Presiona Ctrl+C para detener"
echo ""
cd ProyectoHospital
python manage.py runserver 0.0.0.0:8000
EOF

chmod +x dev-server.sh

# 5. Crear script para toggle entre APIs
cat > toggle-api.py << 'EOF'
#!/usr/bin/env python3
import sys
import os

def toggle_api_mode(mode):
    settings_file = 'ProyectoHospital/ProyectoHospital/settings.py'
    
    if not os.path.exists(settings_file):
        print("❌ Error: No se encuentra el archivo settings.py")
        return
    
    with open(settings_file, 'r') as f:
        content = f.read()
    
    if mode == 'production':
        content = content.replace(
            "SERVERLESS_API_URL = 'http://localhost:3000'",
            "SERVERLESS_API_URL = 'https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api'"
        )
        print("✅ API configurada para PRODUCCIÓN")
    elif mode == 'local':
        content = content.replace(
            "SERVERLESS_API_URL = 'https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api'",
            "SERVERLESS_API_URL = 'http://localhost:3000'"
        )
        print("✅ API configurada para DESARROLLO LOCAL")
    else:
        print("❌ Modo inválido. Usa: 'production' o 'local'")
        return
    
    with open(settings_file, 'w') as f:
        f.write(content)

if __name__ == '__main__':
    mode = sys.argv[1] if len(sys.argv) > 1 else 'production'
    toggle_api_mode(mode)
EOF

chmod +x toggle-api.py

cd ..

# 6. Crear .env template para desarrollo
if [ ! -f ".env.development" ]; then
    cat > .env.development << 'EOF'
# Configuración para desarrollo local
DEBUG=True
DJANGO_SECRET_KEY=your-secret-key-for-development
API_MODE=production  # production | local | mock
SERVERLESS_API_URL=https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api
USE_MOCK_API=False
EOF
    echo "✅ Template .env.development creado"
fi

# 7. Actualizar .gitignore
echo "📝 Actualizando .gitignore..."
cat >> .gitignore << 'EOF'

# Desarrollo local
settings_local.py
.env.development
db.sqlite3
*.sqlite3
.venv/
__pycache__/
*.pyc
.DS_Store
Thumbs.db

# Logs
*.log
logs/
EOF

echo ""
echo "🎉 ¡Configuración completada!"
echo ""
echo "📋 Próximos pasos:"
echo "   1. Activa el entorno virtual:"
echo "      Linux/Mac: source .venv/bin/activate"
echo "      Windows: .venv\\Scripts\\activate"
echo ""
echo "   2. Instala dependencias:"
echo "      pip install -r requirements.txt"
echo ""
echo "   3. Configura la base de datos:"
echo "      cd ProyectoHospital"
echo "      python manage.py migrate"
echo "      python manage.py createsuperuser"
echo ""
echo "   4. Inicia el servidor:"
echo "      ./dev-server.sh"
echo "      O manualmente: cd ProyectoHospital && python manage.py runserver"
echo ""
echo "🌐 El proyecto estará disponible en: http://localhost:8000"
echo ""
echo "🔧 Scripts creados:"
echo "   - ./dev-server.sh        # Inicia servidor de desarrollo"
echo "   - ./toggle-api.py        # Cambia entre API production/local"
echo "   - settings_local.py      # Configuración para desarrollo"
echo ""
echo "✨ ¡Ya puedes desarrollar sin hacer push en cada cambio!"