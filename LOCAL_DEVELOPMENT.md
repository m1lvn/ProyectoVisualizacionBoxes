# 🚀 Desarrollo Local - Sin Push Constantes

Este documento explica cómo ejecutar todo el proyecto **localmente** para desarrollo rápido sin necesidad de hacer push/deploy en cada cambio.

## 🎯 Opciones de Desarrollo Local

### **Opción 1: Usar API de Producción (Recomendado para cambios de frontend)**
- Django local → API AWS en producción
- Ideal para: cambios en templates, CSS, JavaScript, vistas Django
- Sin costo adicional de AWS

### **Opción 2: Serverless Offline (Desarrollo completo local)**
- Todo local: Django + API + DynamoDB Local
- Ideal para: cambios en lógica de API, nuevos endpoints
- Requiere configuración adicional

### **Opción 3: Mock API (Desarrollo frontend puro)**
- API simulada con datos estáticos
- Ideal para: diseño, UX, CSS puro
- Sin dependencias externas

---

## 🌟 **OPCIÓN 1: Django Local + API Producción**

### **Configuración (5 minutos):**

1. **Configurar Django para desarrollo:**
```python
# ProyectoHospital/settings.py
DEBUG = True
ALLOWED_HOSTS = ['localhost', '127.0.0.1', '0.0.0.0']

# Usar API de producción
SERVERLESS_API_URL = 'https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api'

# Base de datos local para auth
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}
```

2. **Ejecutar Django:**
```bash
cd ProyectoHospital
python manage.py runserver 8000
```

3. **¡Listo!** Accede a http://localhost:8000

### **Ventajas:**
- ✅ Setup súper rápido
- ✅ API real con datos reales
- ✅ Cambios instantáneos en frontend
- ✅ Sin costos AWS adicionales

### **Perfecto para:**
- 🎨 Cambios en templates HTML
- 🎨 Modificaciones CSS
- 🎨 Actualizaciones JavaScript
- 🎨 Nuevas vistas Django
- 🎨 Cambios en lógica de frontend

---

## 🔧 **OPCIÓN 2: Desarrollo Completamente Local**

### **Configuración (15 minutos):**

1. **Instalar DynamoDB Local:**
```bash
# Instalar Java (prerrequisito)
https://java.com/

# Instalar DynamoDB Local
mkdir dynamodb-local
cd dynamodb-local
curl -O https://s3-us-west-2.amazonaws.com/dynamodb-local/dynamodb_local_latest.tar.gz
tar -xzf dynamodb_local_latest.tar.gz
```

2. **Instalar Serverless Offline:**
```bash
cd serverless-api
npm install serverless-offline --save-dev
npm install serverless-dynamodb-local --save-dev
```

3. **Configurar serverless.yml:**
```yaml
# serverless-api/serverless.yml
plugins:
  - serverless-offline
  - serverless-dynamodb-local

custom:
  dynamodb:
    start:
      port: 8001
      inMemory: true
      migrate: true
    stages:
      - dev

  serverless-offline:
    httpPort: 3000
```

4. **Configurar variables locales:**
```bash
# serverless-api/.env.local
AWS_REGION=localhost
DYNAMODB_ENDPOINT=http://localhost:8001
DYNAMODB_TABLE=HospitalData-local
DEBUG=true
```

5. **Scripts de desarrollo:**
```json
# serverless-api/package.json
{
  "scripts": {
    "dev": "serverless offline start",
    "dynamodb": "serverless dynamodb start",
    "migrate-local": "node scripts/migrate-to-local.js"
  }
}
```

6. **Ejecutar todo localmente:**
```bash
# Terminal 1: DynamoDB Local
cd serverless-api
npm run dynamodb

# Terminal 2: API Local
cd serverless-api
npm run dev

# Terminal 3: Django
cd ProyectoHospital
# Cambiar settings.py:
# SERVERLESS_API_URL = 'http://localhost:3000'
python manage.py runserver 8000
```

### **Ventajas:**
- ✅ Control total del entorno
- ✅ Sin dependencias de internet
- ✅ Datos de prueba personalizados
- ✅ Debug completo de API

### **Perfecto para:**
- 🔧 Desarrollo de nuevos endpoints
- 🔧 Modificaciones en lógica de API
- 🔧 Testing de integración completa
- 🔧 Desarrollo sin internet

---

## 💡 **OPCIÓN 3: Mock API (Frontend Puro)**

### **Configuración (2 minutos):**

1. **Crear mock API:**
```python
# ProyectoHospital/visualizacionBoxes/mock_api.py
def get_mock_data(endpoint, params=None):
    if endpoint == 'boxes':
        return [
            {'idBox': 1, 'pasillo': 'Pasillo A', 'idPasillo': 1, 'capacidad': 1},
            {'idBox': 2, 'pasillo': 'Pasillo A', 'idPasillo': 1, 'capacidad': 1},
            # ... más datos mock
        ]
    elif endpoint == 'pasillos':
        return [
            {'idPasillo': 1, 'pasillo': 'Pasillo A', 'descripcion': 'Primer pasillo'},
            # ... más pasillos
        ]
    elif endpoint == 'agendas':
        return [
            {'idBox': 1, 'fecha': '2025-09-28', 'horaInicio': '09:00', 'profesional': 'Dr. Mock'}
        ]
    return []
```

2. **Helper function for development:**
```python
# ProyectoHospital/visualizacionBoxes/views.py
def get_api_data(endpoint, params=None):
    if settings.USE_MOCK_API:  # Variable en settings
        from .mock_api import get_mock_data
        return get_mock_data(endpoint, params)
    
    # Código original de API real
    # ...
```

3. **Toggle en settings:**
```python
# ProyectoHospital/settings.py
USE_MOCK_API = True  # Para desarrollo frontend
# USE_MOCK_API = False  # Para usar API real
```

### **Ventajas:**
- ✅ Setup instantáneo
- ✅ Datos controlados
- ✅ Sin dependencias externas
- ✅ Perfecto para diseño

---

## ⚡ **Workflow de Desarrollo Recomendado**

### **Para Cambios de Frontend (95% de los casos):**
```bash
# 1. Usar Opción 1: API de producción
cd ProyectoHospital
python manage.py runserver 8000

# 2. Hacer cambios en templates, CSS, JS
# 3. Refresh browser (cambios instantáneos)
# 4. Solo push cuando esté listo
```

### **Para Cambios de API (5% de los casos):**
```bash
# 1. Desarrollar localmente (Opción 2)
npm run dev  # API local

# 2. Hacer cambios en handlers
# 3. Probar endpoints directamente
curl http://localhost:3000/boxes

# 4. Cuando esté listo, deploy
serverless deploy
```

---

## 🛠️ **Scripts de Utilidad**

### **Script de Setup Rápido:**
```bash
#!/bin/bash
# setup-local-dev.sh

echo "🚀 Configurando desarrollo local..."

# Django
cd ProyectoHospital
cp settings.py settings.py.backup
sed -i 's/DEBUG = False/DEBUG = True/' settings.py
echo "✅ Django configurado para desarrollo"

# Instalar dependencias si es necesario
pip install -r requirements.txt

# Migraciones
python manage.py migrate

echo "🎉 ¡Listo para desarrollo local!"
echo "Ejecuta: python manage.py runserver 8000"
```

### **Script de Toggle API:**
```python
#!/usr/bin/env python
# toggle-api.py
import sys

def toggle_api_mode(mode):
    settings_file = 'ProyectoHospital/settings.py'
    
    with open(settings_file, 'r') as f:
        content = f.read()
    
    if mode == 'production':
        content = content.replace(
            "SERVERLESS_API_URL = 'http://localhost:3000'",
            "SERVERLESS_API_URL = 'https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api'"
        )
    elif mode == 'local':
        content = content.replace(
            "SERVERLESS_API_URL = 'https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api'",
            "SERVERLESS_API_URL = 'http://localhost:3000'"
        )
    
    with open(settings_file, 'w') as f:
        f.write(content)
    
    print(f"✅ API configurada para modo: {mode}")

if __name__ == '__main__':
    mode = sys.argv[1] if len(sys.argv) > 1 else 'production'
    toggle_api_mode(mode)
```

---

## 🔄 **Hot Reload Configurado**

Django ya tiene hot reload por defecto, pero puedes optimizarlo:

### **Configuración para Hot Reload Óptimo:**
```python
# ProyectoHospital/settings.py
if DEBUG:
    # Reload automático mejorado
    USE_TZ = True
    
    # Static files para desarrollo
    STATICFILES_STORAGE = 'django.contrib.staticfiles.storage.StaticFilesStorage'
    
    # Templates reload
    TEMPLATES[0]['OPTIONS']['debug'] = True
```

### **Live Reload con Browser-Sync (Opcional):**
```bash
# Instalar browser-sync
npm install -g browser-sync

# Usar proxy para Django
browser-sync start --proxy "localhost:8000" --files "ProyectoHospital/**/*"
```

---

## 🚀 **Flujo de Trabajo Optimizado**

### **Día típico de desarrollo:**

1. **Mañana (Setup):**
```bash
cd ProyectoHospital
python manage.py runserver 8000
# Abrir http://localhost:8000
```

2. **Durante el día:**
- Editar templates → Refresh browser
- Modificar CSS → Refresh browser  
- Cambiar views.py → Auto-reload
- Agregar JavaScript → Refresh browser

3. **Al final del día:**
```bash
git add .
git commit -m "Mejoras en UI/UX"
git push origin main
```

4. **Solo si cambios en API:**
```bash
cd serverless-api
serverless deploy  # Solo cuando sea necesario
```

---

## ✅ **Resumen: Desarrollo Sin Push**

**Recomendación: Usar OPCIÓN 1 (Django local + API producción)**

- ⚡ Setup en 30 segundos
- 🔄 Cambios instantáneos en frontend
- 💰 Sin costos adicionales
- 🌐 Datos reales
- 🚀 Productividad máxima

**Comandos básicos:**
```bash
cd ProyectoHospital
python manage.py runserver 8000
# Hacer cambios → Refresh browser
# Solo push cuando esté todo listo
```

¡Con esto puedes desarrollar localmente sin hacer push en cada cambio! 🎉