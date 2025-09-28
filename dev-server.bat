@echo off
REM dev-server.bat - Script rápido para iniciar desarrollo en Windows

echo 🚀 Iniciando servidor de desarrollo Hospital...
echo 📍 URL: http://localhost:8000
echo 🔄 Hot reload activo - los cambios se verán automáticamente
echo ⏹️  Presiona Ctrl+C para detener
echo.

REM Verificar que estamos en el lugar correcto
if not exist "ProyectoHospital" (
    echo ❌ Error: Ejecuta desde la raíz del proyecto
    pause
    exit /b 1
)

REM Cambiar al directorio de Django
cd ProyectoHospital

REM Verificar configuración
if not exist "db.sqlite3" (
    echo ⚙️ Primera vez - configurando base de datos...
    python manage.py migrate
    echo.
    echo 👤 Crear superusuario ^(opcional^):
    python manage.py createsuperuser
)

REM Iniciar servidor
echo 🌐 Iniciando Django en http://localhost:8000
python manage.py runserver 0.0.0.0:8000