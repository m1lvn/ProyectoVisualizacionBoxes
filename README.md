# 🏥 Proyecto Hospital - Migración a Arquitectura Serverless

## 📋 Resumen del Proyecto

Este proyecto ha migrado de una arquitectura tradicional **Django + MySQL** a una **arquitectura híbrida** usando:

- **Frontend**: Django (existente) 
- **Backend API**: Node.js + Serverless Framework + AWS Lambda
- **Base de Datos**: DynamoDB (migrado desde MySQL)
- **Infraestructura**: AWS (compatible con AWS Academy)

---

## 🎯 ¿Qué se ha implementado?

### ✅ **Completado:**

1. **API Serverless** con Node.js y Serverless Framework
2. **Estructura DynamoDB** optimizada para el dominio hospitalario
3. **Funciones Lambda** para operaciones CRUD
4. **Scripts de migración** de datos MySQL → DynamoDB
5. **Integración básica** con Django existente
6. **Scripts de despliegue** automatizados para EC2

### 📁 **Estructura del Proyecto:**

```
ProyectoVisualizacionBoxes/
├── ProyectoHospital/                 # Django Frontend (existente)
│   ├── visualizacionBoxes/
│   │   ├── models.py                 # Modelos originales (mantener)
│   │   ├── views.py                  # Vistas originales
│   │   ├── api_client.py            # 🆕 Cliente para API Serverless
│   │   └── views_api_integration.py # 🆕 Vistas ejemplo con API
│   └── requirements.txt
├── serverless-api/                   # 🆕 Nueva API Serverless
│   ├── serverless.yml              # Configuración de infraestructura
│   ├── package.json                # Dependencias Node.js
│   ├── src/handlers/               # Funciones Lambda
│   │   ├── boxes.js               # Endpoints de boxes
│   │   ├── agendas.js            # Endpoints de agendas
│   │   ├── pasillos.js           # Endpoints de pasillos
│   │   └── migrate.js            # Migración de datos
│   └── .env.example              # Variables de entorno
├── deploy.sh                        # 🆕 Script de despliegue
├── configure-aws-academy.sh         # 🆕 Config credenciales AWS
├── verify-setup.sh                  # 🆕 Verificación de setup
├── .gitignore                       # 🆕 Exclusiones de Git
└── README.md                        # 🆕 Esta documentación
```

---

## 🚀 Setup Inicial (Para Nuevos Desarrolladores)

### **Prerrequisitos:**
- AWS Academy Lab account
- EC2 instance con Ubuntu
- Node.js 18+ instalado
- Git configurado

### **1. Clonar el repositorio:**
```bash
git clone https://github.com/tu-usuario/ProyectoVisualizacionBoxes.git
cd ProyectoVisualizacionBoxes
```

### **2. Configurar credenciales AWS Academy:**
```bash
# Dar permisos a scripts
chmod +x *.sh

# Configurar AWS (necesitas credenciales de AWS Academy)
./configure-aws-academy.sh
```

**Para obtener credenciales AWS Academy:**
1. Ve a **AWS Academy Learner Lab**
2. Asegúrate que esté en estado **"green/ready"**
3. Click en **"AWS Details"**
4. Click en **"Show"** en AWS CLI credentials
5. Copia las 4 líneas que aparecen:
   ```
   [default]
   aws_access_key_id=ASIA...
   aws_secret_access_key=...
   aws_session_token=...
   ```

### **3. Verificar setup:**
```bash
./verify-setup.sh
```

### **4. Instalar dependencias y desplegar:**
```bash
# Instalar dependencias Node.js
cd serverless-api
npm install
cd ..

# Desplegar infraestructura a AWS
./deploy.sh
```

### **5. Migrar datos (solo la primera vez):**
```bash
# Obtener URL de la API
cd serverless-api
npx serverless info

# Migrar datos de MySQL a DynamoDB
curl -X POST https://TU_API_URL.execute-api.us-east-1.amazonaws.com/dev/api/migrate
```

---

## 🛠️ Desarrollo Diario

### **Flujo de trabajo:**
```bash
# 1. Actualizar código
git pull origin main

# 2. Si hay cambios en serverless-api/
cd serverless-api
npm install  # Solo si hay cambios en package.json
cd ..

# 3. Desplegar cambios
./deploy.sh

# 4. Probar endpoints
curl https://TU_API_URL/dev/api/pasillos
curl https://TU_API_URL/dev/api/boxes
```

### **Desarrollo local:**
```bash
# Desarrollo offline (opcional)
cd serverless-api
npx serverless offline start
# API disponible en http://localhost:3001
```

---

## 📊 Arquitectura de Datos

### **DynamoDB Table: `HospitalData`**

| PK | SK | GSI1PK | GSI1SK | Tipo | Datos |
|----|----|---------|---------|----- |-------|
| `PASILLO#1` | `METADATA` | `PASILLO#1` | `METADATA` | pasillo | nombre, id |
| `BOX#101` | `METADATA` | `PASILLO#1` | `BOX#101` | box | capacidad, pasillo |
| `AGENDA#uuid` | `2025-09-27#08:00` | `BOX#101` | `2025-09-27#08:00` | agenda | horarios, profesional |
| `PROFESIONAL#1` | `METADATA` | `ESPECIALIDAD#1` | `PROFESIONAL#1` | profesional | nombre, especialidad |

### **Patrones de Acceso Optimizados:**
- ✅ Obtener todos los pasillos
- ✅ Obtener boxes de un pasillo específico
- ✅ Obtener agendas de un box y fecha
- ✅ Obtener agendas de un profesional
- ✅ Buscar agendas por fecha y tipo

---

## 🌐 API Endpoints

### **Base URL:** `https://TU_API_ID.execute-api.us-east-1.amazonaws.com/dev`

| Método | Endpoint | Descripción | Parámetros |
|--------|----------|-------------|------------|
| GET | `/api/pasillos` | Obtener todos los pasillos | - |
| GET | `/api/boxes` | Obtener boxes | `?pasillo=nombre&disponible=true` |
| GET | `/api/agendas` | Obtener agendas | `?fecha=2025-09-27&boxId=101` |
| POST | `/api/agendas` | Crear agenda | JSON body |
| POST | `/api/migrate` | Migrar datos MySQL→DynamoDB | - |

### **Ejemplos de uso:**
```bash
# Obtener pasillos
curl https://TU_API_URL/dev/api/pasillos

# Obtener boxes disponibles de un pasillo
curl "https://TU_API_URL/dev/api/boxes?pasillo=Pasillo Norte&disponible=true"

# Obtener agendas de una fecha
curl "https://TU_API_URL/dev/api/agendas?fecha=2025-09-27"

# Crear nueva agenda
curl -X POST https://TU_API_URL/dev/api/agendas \
  -H "Content-Type: application/json" \
  -d '{
    "boxId": 101,
    "fecha": "2025-09-27",
    "horaInicio": "14:00",
    "horaFin": "16:00",
    "tipoAgenda": "Consulta",
    "profesionalId": 1
  }'
```

---

## 🔧 Integración con Django

### **Configurar settings.py:**
```python
# Al final de ProyectoHospital/settings.py
SERVERLESS_API_BASE_URL = 'https://TU_API_URL.execute-api.us-east-1.amazonaws.com/dev'
```

### **Usar el cliente API:**
```python
# En tus views.py
from .api_client import api_client

def mi_vista(request):
    # En lugar de usar modelos Django directamente
    pasillos_response = api_client.get_pasillos()
    boxes_response = api_client.get_boxes()
    
    if pasillos_response.get('success'):
        pasillos = pasillos_response['data']
    else:
        pasillos = []
    
    context = {'pasillos': pasillos}
    return render(request, 'template.html', context)
```

---

## 🚨 Problemas Comunes y Soluciones

### **Error: "Permission denied" al ejecutar scripts**
```bash
chmod +x *.sh
```

### **Error: "serverless command not found"**
- Los scripts usan `npx serverless` automáticamente
- O instala globalmente: `sudo npm install -g serverless`

### **Error: "AWS credentials not configured"**
```bash
# Renovar credenciales de AWS Academy
./configure-aws-academy.sh

# Verificar que funcionan
aws sts get-caller-identity
```

### **Error: "Cannot resolve serverless.yml variables"**
- Credenciales AWS expiradas (duran 4-6 horas)
- Lab de AWS Academy no está corriendo
- Renovar credenciales desde AWS Academy

### **API devuelve errores 403/404**
- Verificar URL de la API: `npx serverless info`
- Verificar que la migración de datos se ejecutó correctamente

---

## 📈 Próximos Pasos Recomendados

### **🎯 Integración Completa con Django:**
1. **Reemplazar vistas MySQL por API calls:**
   - Actualizar `visualizacion_general()`
   - Actualizar `visualizacion_pasillo()`
   - Adaptar filtros y paginación

2. **Migrar formularios de creación:**
   - Adaptar formularios para usar API POST
   - Manejar validaciones del lado del cliente
   - Implementar manejo de errores

3. **Optimizar rendimiento:**
   - Implementar caché en Django para llamadas API
   - Agregar loading states en el frontend
   - Implementar retry logic para API calls

### **🎯 Mejoras de la API:**
1. **Autenticación y autorización:**
   - Implementar JWT tokens
   - Integrar con sistema de usuarios Django
   - Roles y permisos por tipo de usuario

2. **Validaciones avanzadas:**
   - Validación de solapamiento de agendas
   - Verificación de capacidad de boxes
   - Reglas de negocio específicas

3. **Monitoreo y logs:**
   - CloudWatch dashboards
   - Alertas por errores
   - Métricas de uso

---

## 💡 Tips para el Equipo

### **Desarrollo:**
- **Usar ramas**: Crear ramas para features grandes
- **Testing**: Probar endpoints con curl antes de integrar
- **Logs**: Revisar CloudWatch Logs si hay errores

### **AWS Academy:**
- **Credenciales temporales**: Expiran cada 4-6 horas
- **Lab debe estar activo**: Estado "green/ready"
- **Costos mínimos**: Solo pagas por uso real (<$5/mes típico)

### **Git:**
- **No subir**: `node_modules/`, `.env`, credenciales
- **Sí subir**: `package.json`, `serverless.yml`, código fuente

---

## 🆘 Contacto y Soporte

Si tienes problemas:

1. **Verificar setup**: `./verify-setup.sh`
2. **Revisar logs**: CloudWatch Logs en AWS Console
3. **Probar API**: `curl` endpoints directamente
4. **Verificar credenciales**: `aws sts get-caller-identity`

---

## 📚 Recursos Adicionales

- [Serverless Framework Docs](https://serverless.com/framework/docs/)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/dynamodb/latest/developerguide/best-practices.html)
- [AWS Academy Learner Lab Guide](https://awsacademy.instructure.com/)
- [Django Requests Documentation](https://docs.python-requests.org/)

---

**🎉 ¡Arquitectura serverless exitosamente implementada!**

*Última actualización: Septiembre 2025*