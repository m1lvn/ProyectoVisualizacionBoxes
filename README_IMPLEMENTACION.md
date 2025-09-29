# 🏥 Sistema Hospitalario - Plan de Implementación Completo

## 📋 Resumen del Proyecto

Sistema de visualización de boxes hospitalarios migrado completamente a arquitectura serverless con los siguientes requerimientos adicionales:

- ✅ **Sistema Core**: Migrado a Serverless + DynamoDB (COMPLETADO)
- 🔐 **Login Cognito**: Autenticación con Amazon Cognito
- 👤 **Autorización**: Sistema de roles y permisos con JWT
- 🎨 **Personalización**: Multi-tenant con configuración por cliente
- 📊 **Validación JWT**: En todos los módulos serverless
- 📋 **Documentación**: Diagrama de arquitectura completo

---

## 🎯 Estado Actual vs Requerimientos

### ✅ **YA IMPLEMENTADO**

#### 1. **Arquitectura Serverless Core**

- **API Gateway**: Endpoints RESTful configurados
- **AWS Lambda**: Handlers para boxes, pasillos, agendas
- **DynamoDB**: Single-table design con 180+ boxes, 48 pasillos
- **Despliegue**: Sistema operativo 24/7 en AWS Academy

```
URL API: https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api/
Endpoints Activos:
- GET /boxes
- GET /pasillos  
- GET /agendas
- POST /agendas
```

#### 2. **Base de Datos DynamoDB**

```
Tabla: HospitalData
Estructura:
├── AGENDA#id → Agendas médicas
├── BOX#id → Información de boxes
└── PASILLO#id → Información de pasillos

GSI1: Consultas por fecha/hora
```

#### 3. **Frontend Django**

- Consume API serverless exclusivamente
- Visualización por pasillo con matrix horaria
- Sistema de filtros y paginación
- Modales de detalle por bloque horario

### ❌ **PENDIENTE DE IMPLEMENTAR**

#### 1. **🔐 Login Amazon Cognito**

- User Pool configuration
- App Client setup
- Registro/Login/Logout
- JWT token management

#### 2. **👤 Sistema de Autorización**

- Roles y permisos en DynamoDB
- Middleware JWT validation
- Permission-based access control

#### 3. **🎨 Módulo Personalización**

- Multi-tenant architecture
- Client-specific configuration
- Custom themes and branding

#### 4. **🔒 Validación JWT Global**

- JWT middleware en todos los endpoints
- Token verification
- Permission enforcement

#### 5. **📋 Documentación**

- Diagrama de arquitectura completo
- API documentation
- Deployment guide

---

## 🚀 Plan de Implementación

### **FASE 1: Fundación de Seguridad (3-4 días)**

#### 1.1 **Setup Amazon Cognito**

**Objetivo**: Configurar autenticación centralizada

**Tareas**:

- [ ] Crear Cognito User Pool
- [ ] Configurar App Client (Web)
- [ ] Definir atributos personalizados
- [ ] Crear grupos de usuarios iniciales
- [ ] Configurar políticas de contraseñas

**Entregables**:

```
AWS Resources:
├── User Pool: hospital-users
├── App Client: hospital-web-client
└── User Groups: [Admin, Personal, PersonalAdministrativo]
```

**Estructura de Permisos**:
- **Admin**: Acceso completo a todo el sistema (todos los pasillos, reportes, configuración)
- **Personal**: Acceso limitado al pasillo asignado únicamente (atributo pasillo_asignado)
- **PersonalAdministrativo**: Acceso a todos los pasillos + permisos de booking y reportes

#### 1.2 **JWT Middleware Serverless**

**Objetivo**: Validar tokens en API Gateway

**Tareas**:

- [ ] Crear función Lambda authorizer
- [ ] Implementar JWT verification
- [ ] Manejar refresh tokens
- [ ] Error handling y logging

**Entregables**:

```javascript
// src/middleware/jwtAuth.js
module.exports.authorize = async (event) => {
  // JWT validation logic
  // Return IAM policy
};
```

### **FASE 2: Sistema de Autorización (2-3 días)**

#### 2.1 **Esquema de Permisos DynamoDB**

**Objetivo**: Estructura de datos para roles y permisos

**Esquema Propuesto**:

```
DynamoDB Table: HospitalData

Permissions:
PK: USER#email@example.com
SK: PERMISSION#resource:action
Attributes: { granted: true, clientId: "hospital1" }

Roles:
PK: ROLE#admin  
SK: PERMISSION#boxes:read
Attributes: { granted: true, inherited: true }

User Roles:
PK: USER#email@example.com
SK: ROLE#admin
Attributes: { clientId: "hospital1", assignedAt: "2025-09-28" }
```

#### 2.2 **Middleware de Autorización**

**Tareas**:

- [ ] Función de verificación de permisos
- [ ] Cache de permisos por usuario
- [ ] Decoradores para endpoints
- [ ] Logging de accesos

### **FASE 3: Personalización Multi-tenant (2-3 días)**

#### 3.1 **Configuración por Cliente**

**Objetivo**: Personalización por organización

**Esquema DynamoDB**:

```
Client Configuration:
PK: CLIENT#hospital1
SK: CONFIG#branding
Attributes: {
  logo: "s3://bucket/logos/hospital1.png",
  colors: { primary: "#0066cc", secondary: "#28a745" },
  name: "Hospital San Juan"
}

PK: CLIENT#hospital1  
SK: CONFIG#texts
Attributes: {
  welcomeMessage: "Bienvenido al Sistema Hospital San Juan",
  labels: { boxes: "Consultorios", pasillos: "Sectores" }
}
```

#### 3.2 **API de Personalización**

**Tareas**:

- [ ] Endpoint GET /config/{clientId}
- [ ] Endpoint PUT /config/{clientId}
- [ ] Validación de configuración
- [ ] Cache de configuración

### **FASE 4: Integración Frontend (2-3 días)**

#### 4.1 **Cognito Integration**

**Tareas**:

- [ ] AWS Amplify Auth setup
- [ ] Login/Logout components
- [ ] Token storage y refresh
- [ ] Protected routes

#### 4.2 **Dynamic UI**

**Tareas**:

- [ ] Cargar configuración por cliente
- [ ] Aplicar estilos dinámicos
- [ ] Mostrar contenido según permisos
- [ ] Manejo de errores de autorización

### **FASE 5: Testing y Documentación (1-2 días)**

#### 5.1 **Testing Integral**

- [ ] Tests unitarios middleware
- [ ] Tests de integración API
- [ ] Tests end-to-end frontend
- [ ] Performance testing

#### 5.2 **Documentación**

- [ ] Diagrama de arquitectura
- [ ] API documentation
- [ ] Guía de despliegue
- [ ] Manual de usuario

---

## 📊 Arquitectura Objetivo

```
┌─────────────────────────────────────────────────────────────────┐
│                        FRONTEND LAYER                          │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐ │
│  │   Django Web    │    │   React/Vue     │    │   Mobile App    │ │
│  │   (Existing)    │    │   (Future)      │    │   (Future)      │ │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
         │ JWT Tokens              │ JWT Tokens              │
         ▼                         ▼                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AUTHENTICATION LAYER                        │
│                   ┌─────────────────┐                          │
│                   │ Amazon Cognito  │                          │
│                   │   User Pools    │                          │
│                   │                 │                          │
│                   │ - User Groups   │                          │
│                   │ - JWT Tokens    │                          │
│                   │ - MFA (Optional)│                          │
│                   └─────────────────┘                          │
└─────────────────────────────────────────────────────────────────┘
                             │ JWT Validation
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API GATEWAY LAYER                         │
│                   ┌─────────────────┐                          │
│                   │  API Gateway    │                          │
│                   │                 │                          │
│                   │ - Rate Limiting │                          │
│                   │ - CORS          │                          │
│                   │ - JWT Authorizer│                          │
│                   └─────────────────┘                          │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     BUSINESS LOGIC LAYER                       │
│                          AWS LAMBDA                            │
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│ │JWT Authorizer│ │   Boxes     │ │  Agendas    │ │Customization│ │
│ │             │ │   Handler   │ │   Handler   │ │   Handler   │ │
│ │ - Verify JWT│ │             │ │             │ │             │ │
│ │ - Check Perms│ │ - CRUD Ops  │ │ - CRUD Ops  │ │ - Get Config│ │
│ │ - Return IAM│ │ - Validation│ │ - Validation│ │ - Set Config│ │
│ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
│                                                                 │
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│ │  Pasillos   │ │Permissions  │ │   Users     │ │   Reports   │ │
│ │   Handler   │ │   Handler   │ │   Handler   │ │   Handler   │ │
│ │             │ │             │ │             │ │             │ │
│ │ - CRUD Ops  │ │ - Check Perms│ │ - User CRUD│ │ - Generate  │ │
│ │ - Validation│ │ - Role Mgmt  │ │ - Profile   │ │ - Export    │ │
│ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DATA PERSISTENCE LAYER                    │
│                          DynamoDB                              │
│                                                                 │
│                    Table: HospitalData                         │
│                                                                 │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │                    Partition Patterns                      │ │
│ │                                                             │ │
│ │ AGENDA#id     → Medical Appointments                       │ │
│ │ BOX#id        → Box Information                            │ │
│ │ PASILLO#id    → Corridor Information                       │ │
│ │ USER#email    → User Data & Permissions                    │ │
│ │ ROLE#name     → Role Definitions                           │ │
│ │ CLIENT#id     → Client Customization                       │ │
│ │                                                             │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │                    Global Secondary Indexes                │ │
│ │                                                             │ │
│ │ GSI1: Date-based queries (appointments by date)           │ │
│ │ GSI2: Box-based queries (appointments by box)             │ │  
│ │ GSI3: User-based queries (permissions by user)            │ │
│ │                                                             │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tecnologías y Herramientas

### **Backend**

- **AWS Lambda**: Node.js 18.x runtime
- **API Gateway**: RESTful endpoints
- **DynamoDB**: NoSQL database
- **Cognito**: Authentication service
- **IAM**: Authorization policies

### **Frontend**

- **Django**: Current web framework
- **Bootstrap**: UI components
- **JavaScript**: Client-side logic
- **AWS Amplify**: Future Cognito integration

### **DevOps**

- **Serverless Framework**: Deployment automation
- **AWS Academy**: Development environment
- **CloudWatch**: Monitoring and logging
- **S3**: Static assets storage

### **Security**

- **JWT**: Token-based authentication
- **HTTPS**: Encrypted communications
- **CORS**: Cross-origin policies
- **Rate Limiting**: API protection

---

## ⏱️ Timeline y Estimaciones

| Fase                               | Duración             | Recursos        | Entregables                |
| ---------------------------------- | --------------------- | --------------- | -------------------------- |
| **Fase 1: Seguridad**        | 3-4 días             | 1 Dev           | Cognito + JWT Middleware   |
| **Fase 2: Autorización**    | 2-3 días             | 1 Dev           | Permisos + Roles           |
| **Fase 3: Personalización** | 2-3 días             | 1 Dev           | Multi-tenant + UI          |
| **Fase 4: Integración**     | 2-3 días             | 1 Dev           | Frontend + API             |
| **Fase 5: Testing**          | 1-2 días             | 1 Dev           | Docs + Tests               |
| **TOTAL**                    | **10-15 días** | **1 Dev** | **Sistema Completo** |

---

## 📝 Checklist de Implementación

### **Preparación**

- [ ] Revisar acceso a AWS Academy
- [ ] Validar permisos de Cognito
- [ ] Backup del estado actual
- [ ] Configurar entorno de desarrollo

### **Fase 1: Cognito Setup**

- [ ] Crear User Pool
- [ ] Configurar App Client
- [ ] Definir grupos de usuarios
- [ ] Implementar JWT authorizer
- [ ] Testing básico de autenticación

### **Fase 2: Authorization**

- [ ] Diseñar esquema de permisos
- [ ] Implementar middleware autorización
- [ ] Crear roles por defecto
- [ ] Testing de permisos

### **Fase 3: Customization**

- [ ] Esquema multi-tenant
- [ ] API de configuración
- [ ] UI dinámica
- [ ] Testing personalización

### **Fase 4: Integration**

- [ ] Frontend con Cognito
- [ ] Manejo de permisos en UI
- [ ] Error handling
- [ ] Testing end-to-end

### **Fase 5: Documentation**

- [ ] Diagrama arquitectura
- [ ] API documentation
- [ ] Manual deployment
- [ ] Manual usuario final

---

## 🔧 Comandos de Desarrollo

### **Despliegue Serverless**

```bash
# Instalar dependencias
npm install

# Deploy a AWS
serverless deploy --stage dev

# Ver logs
serverless logs -f functionName --tail

# Remove stack
serverless remove --stage dev
```

### **Frontend Django**

```bash
# Activar entorno virtual
.venv\Scripts\activate

# Instalar dependencias  
pip install -r requirements.txt

# Ejecutar servidor local
python manage.py runserver

# Migraciones (si es necesario)
python manage.py migrate
```

### **Testing**

```bash
# Tests unitarios
npm test

# Tests de integración
npm run test:integration

# Tests frontend
python manage.py test
```

---

## 🚨 Consideraciones de Seguridad

### **JWT Tokens**

- Expiración corta (15-30 min)
- Refresh token rotation
- Secure storage en cliente
- Logout token blacklisting

### **API Security**

- Rate limiting por usuario
- Input validation estricta
- SQL injection protection
- CORS configurado correctamente

### **Data Protection**

- Cifrado en tránsito (HTTPS)
- Cifrado en reposo (DynamoDB)
- Logs sin información sensible
- Backup y recovery procedures

---

## 📞 Contacto y Soporte

**Desarrollador Principal**: Sistema Hospitalario Team
**Email**: support@hospital-system.com
**Documentación**: [Wiki del Proyecto]
**Issues**: [GitHub Issues]

---

## 📄 Licencia y Términos

Este proyecto es de uso interno para el hospital. Todos los derechos reservados.

**Última actualización**: 28 de Septiembre, 2025
**Versión**: 2.0.0
**Estado**: En Desarrollo - Fase de Implementación
