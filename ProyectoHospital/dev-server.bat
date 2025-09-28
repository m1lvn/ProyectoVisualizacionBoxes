@echo off 
echo 🚀 Iniciando servidor de desarrollo... 
echo 📍 URL: http://localhost:8000 
echo 🔄 Hot reload activo - los cambios se verán automáticamente 
echo ⏹️  Presiona Ctrl+C para detener 
echo. 
cd ProyectoHospital 
python manage.py runserver 0.0.0.0:8000 
