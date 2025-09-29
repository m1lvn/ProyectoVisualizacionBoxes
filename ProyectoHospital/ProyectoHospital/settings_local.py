from .settings import * 
 
# Configuración para desarrollo local 
DEBUG = True 
ALLOWED_HOSTS = ['localhost', '127.0.0.1', '0.0.0.0', '*'] 
 
# API de producción (cambiar si usas API local) 
SERVERLESS_API_URL = 'https://s9egobx2tl.execute-api.us-east-1.amazonaws.com' 
 
# Base de datos local para autenticación 
DATABASES = { 
    'default': { 
        'ENGINE': 'django.db.backends.sqlite3', 
        'NAME': BASE_DIR / 'db.sqlite3', 
    } 
} 
 
print("🔧 Django configurado para desarrollo local") 
