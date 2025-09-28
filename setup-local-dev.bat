@echo off
REM setup-local-dev.bat - Configuración rápida para desarrollo local en Windows

echo 🚀 Configurando desarrollo local del Hospital...

REM Verificar que estamos en el directorio correcto
if not exist "README.md" (
    echo ❌ Error: Ejecuta este script desde la raíz del proyecto ProyectoVisualizacionBoxes
    pause
    exit /b 1
)

if not exist "ProyectoHospital" (
    echo ❌ Error: No se encuentra el directorio ProyectoHospital
    pause
    exit /b 1
)

echo ⚙️ Configurando Django...
cd ProyectoHospital

REM Backup de settings si no existe
if not exist "ProyectoHospital\settings_production.py" (
    copy "ProyectoHospital\settings.py" "ProyectoHospital\settings_production.py" > nul
    echo ✅ Backup de settings creado
)

REM Configurar settings para desarrollo local
echo from .settings import * > ProyectoHospital\settings_local.py
echo. >> ProyectoHospital\settings_local.py
echo # Configuración para desarrollo local >> ProyectoHospital\settings_local.py
echo DEBUG = True >> ProyectoHospital\settings_local.py
echo ALLOWED_HOSTS = ['localhost', '127.0.0.1', '0.0.0.0', '*'] >> ProyectoHospital\settings_local.py
echo. >> ProyectoHospital\settings_local.py
echo # API de producción ^(cambiar si usas API local^) >> ProyectoHospital\settings_local.py
echo SERVERLESS_API_URL = 'https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api' >> ProyectoHospital\settings_local.py
echo. >> ProyectoHospital\settings_local.py
echo # Base de datos local para autenticación >> ProyectoHospital\settings_local.py
echo DATABASES = { >> ProyectoHospital\settings_local.py
echo     'default': { >> ProyectoHospital\settings_local.py
echo         'ENGINE': 'django.db.backends.sqlite3', >> ProyectoHospital\settings_local.py
echo         'NAME': BASE_DIR / 'db.sqlite3', >> ProyectoHospital\settings_local.py
echo     } >> ProyectoHospital\settings_local.py
echo } >> ProyectoHospital\settings_local.py
echo. >> ProyectoHospital\settings_local.py
echo print^("🔧 Django configurado para desarrollo local"^) >> ProyectoHospital\settings_local.py

REM Usar configuración local por defecto
copy "ProyectoHospital\settings_local.py" "ProyectoHospital\settings.py" > nul

echo 📦 Verificando dependencias Python...
if not exist ".venv" (
    echo 🐍 Creando entorno virtual...
    python -m venv .venv
    echo ✅ Entorno virtual creado
)

echo ⚠️  Activa el entorno virtual con:
echo    .venv\Scripts\activate

REM Verificar si requirements.txt existe
if not exist "requirements.txt" (
    echo 📋 Creando requirements.txt básico...
    echo Django==4.2.21 > requirements.txt
    echo requests==2.31.0 >> requirements.txt
    echo django-allauth==0.54.0 >> requirements.txt
    echo Pillow==10.0.0 >> requirements.txt
    echo ✅ requirements.txt creado
)

echo 📋 Para instalar dependencias ejecuta:
echo    pip install -r requirements.txt

echo 🗄️ Configurando base de datos local...
if not exist "db.sqlite3" (
    echo 📋 Para configurar la base de datos ejecuta:
    echo    python manage.py migrate
    echo    python manage.py createsuperuser
) else (
    echo ✅ Base de datos ya existe
)

echo ⚡ Creando script de desarrollo rápido...
echo @echo off > dev-server.bat
echo echo 🚀 Iniciando servidor de desarrollo... >> dev-server.bat
echo echo 📍 URL: http://localhost:8000 >> dev-server.bat
echo echo 🔄 Hot reload activo - los cambios se verán automáticamente >> dev-server.bat
echo echo ⏹️  Presiona Ctrl+C para detener >> dev-server.bat
echo echo. >> dev-server.bat
echo cd ProyectoHospital >> dev-server.bat
echo python manage.py runserver 0.0.0.0:8000 >> dev-server.bat

REM Crear script para toggle entre APIs
echo import sys > toggle-api.py
echo import os >> toggle-api.py
echo. >> toggle-api.py
echo def toggle_api_mode^(mode^): >> toggle-api.py
echo     settings_file = 'ProyectoHospital/ProyectoHospital/settings.py' >> toggle-api.py
echo     if not os.path.exists^(settings_file^): >> toggle-api.py
echo         print^("❌ Error: No se encuentra el archivo settings.py"^) >> toggle-api.py
echo         return >> toggle-api.py
echo     with open^(settings_file, 'r'^) as f: >> toggle-api.py
echo         content = f.read^(^) >> toggle-api.py
echo     if mode == 'production': >> toggle-api.py
echo         content = content.replace^("SERVERLESS_API_URL = 'http://localhost:3000'", "SERVERLESS_API_URL = 'https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api'"^) >> toggle-api.py
echo         print^("✅ API configurada para PRODUCCIÓN"^) >> toggle-api.py
echo     elif mode == 'local': >> toggle-api.py
echo         content = content.replace^("SERVERLESS_API_URL = 'https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api'", "SERVERLESS_API_URL = 'http://localhost:3000'"^) >> toggle-api.py
echo         print^("✅ API configurada para DESARROLLO LOCAL"^) >> toggle-api.py
echo     with open^(settings_file, 'w'^) as f: >> toggle-api.py
echo         f.write^(content^) >> toggle-api.py
echo. >> toggle-api.py
echo if __name__ == '__main__': >> toggle-api.py
echo     mode = sys.argv[1] if len^(sys.argv^) ^> 1 else 'production' >> toggle-api.py
echo     toggle_api_mode^(mode^) >> toggle-api.py

cd ..

REM Crear .env template para desarrollo
if not exist ".env.development" (
    echo # Configuración para desarrollo local > .env.development
    echo DEBUG=True >> .env.development
    echo DJANGO_SECRET_KEY=your-secret-key-for-development >> .env.development
    echo API_MODE=production  # production ^| local ^| mock >> .env.development
    echo SERVERLESS_API_URL=https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api >> .env.development
    echo USE_MOCK_API=False >> .env.development
    echo ✅ Template .env.development creado
)

echo.
echo 🎉 ¡Configuración completada!
echo.
echo 📋 Próximos pasos:
echo    1. Activa el entorno virtual:
echo       .venv\Scripts\activate
echo.
echo    2. Instala dependencias:
echo       pip install -r requirements.txt
echo.
echo    3. Configura la base de datos:
echo       cd ProyectoHospital
echo       python manage.py migrate
echo       python manage.py createsuperuser
echo.
echo    4. Inicia el servidor:
echo       dev-server.bat
echo       O manualmente: cd ProyectoHospital ^&^& python manage.py runserver
echo.
echo 🌐 El proyecto estará disponible en: http://localhost:8000
echo.
echo 🔧 Scripts creados:
echo    - dev-server.bat         # Inicia servidor de desarrollo
echo    - toggle-api.py          # Cambia entre API production/local
echo    - settings_local.py      # Configuración para desarrollo
echo.
echo ✨ ¡Ya puedes desarrollar sin hacer push en cada cambio!
echo.
pause