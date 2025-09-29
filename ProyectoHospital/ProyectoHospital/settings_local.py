from .settings import * 
 
# Configuración para desarrollo local 
DEBUG = True 
ALLOWED_HOSTS = ['localhost', '127.0.0.1', '0.0.0.0', '*'] 
 
# API de producción (cambiar si usas API local) 
# Local Development Serverless API Configuration
SERVERLESS_API_URL = 'https://r8qjc8hqrl.execute-api.us-east-1.amazonaws.com/dev/api'
SERVERLESS_AUTH_URL = 'https://utcn9m1wwg.execute-api.us-east-1.amazonaws.com' 
 
# Base de datos local para autenticación 
DATABASES = { 
    'default': { 
        'ENGINE': 'django.db.backends.sqlite3', 
        'NAME': BASE_DIR / 'db.sqlite3', 
    } 
} 
 
print("🔧 Django configurado para desarrollo local") 
