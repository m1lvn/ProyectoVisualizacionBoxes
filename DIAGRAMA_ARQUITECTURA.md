# 🏗️ Sistema de Visualización de Boxes Hospitalarios - Arquitectura Serverless Completa

## 📋 **RESUMEN ARQUITECTÓNICO**

**Cumplimiento de Requerimientos:**
- ✅ **DynamoDB**: Almacenamiento de preferencias y datos del hospital
- ✅ **Comunicación Desacoplada**: SNS para mensajería asíncrona
- ✅ **Microservicios REST**: API Gateway + Lambda functions
- ✅ **Amazon Cognito**: Sistema de autenticación completo
- ✅ **JWT Tokens**: Autorización en todos los endpoints

---

## 🎯 **ARQUITECTURA GENERAL**

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    🌐 FRONTEND LAYER                                        │
│                                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                             Django Web Application                                  │   │
│  │                            (Puerto 8000 - Dev/Prod)                                 │   │
│  │                                                                                     │   │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │   │
│  │  │  Visualización  │ │     Gestión     │ │  Administración │ │  Autenticación  │   │   │
│  │  │     Boxes       │ │    Agendas      │ │    Sistema      │ │   & Sesiones    │   │   │
│  │  │                 │ │                 │ │                 │ │                 │   │   │
│  │  │ • Matrix View   │ │ • Crear/Editar  │ │ • User Mgmt     │ │ • Login Cognito │   │   │
│  │  │ • Pasillo View  │ │ • Profesionales │ │ • Configuración │ │ • JWT Sessions  │   │   │
│  │  │ • Estados       │ │ • Horarios      │ │ • Reportes      │ │ • Role Control  │   │   │
│  │  │ • Tiempo Real   │ │ • Estados Box   │ │ • Multi-tenant  │ │ • Logout        │   │   │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘   │   │
│  │                                                                                     │   │
│  │  🔗 API Configuration:                                                             │   │
│  │  • AUTH_URL: https://utcn9m1wwg.execute-api.us-east-1.amazonaws.com               │   │
│  │  • API_URL:  https://utcn9m1wwg.execute-api.us-east-1.amazonaws.com/api           │   │
│  └─────────────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼ HTTPS + JWT Authorization Headers
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                🔐 AUTHENTICATION LAYER                                      │
│                                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                        🔑 Amazon Cognito User Pool                                  │   │
│  │                           us-east-1_f9rmticVD                                       │   │
│  │                         Client: 6i75cgnkchgir4oh0312ue98u0                         │   │
│  │                                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                            👥 User Groups & Roles                          │   │   │
│  │  │                                                                             │   │   │
│  │  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────────────┐   │   │   │
│  │  │  │      Admin      │ │     Personal    │ │   PersonalAdministrativo    │   │   │   │
│  │  │  │                 │ │                 │ │                             │   │   │   │
│  │  │  │ • Full Access   │ │ • Pasillo Only  │ │ • Multiple Pasillos         │   │   │   │
│  │  │  │ • All Config    │ │ • Limited Scope │ │ • Extended Reports          │   │   │   │
│  │  │  │ • User Mgmt     │ │ • Box View      │ │ • Config Read-Only          │   │   │   │
│  │  │  │ • Migrate Data  │ │ • Create Agenda │ │ • User Management           │   │   │   │
│  │  │  └─────────────────┘ └─────────────────┘ └─────────────────────────────┘   │   │   │
│  │  └─────────────────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                                     │   │
│  │  🏷️ Custom Attributes:                                                             │   │
│  │  • hospital_id: Multi-tenant hospital identifier                                   │   │
│  │  • pasillo_asignado: Assigned corridor for Personal users                          │   │
│  │                                                                                     │   │
│  │  🔐 JWT Configuration:                                                             │   │
│  │  • ID Tokens: User profile + groups + custom attributes                           │   │
│  │  • Access Tokens: API authorization                                                │   │
│  │  • Refresh Tokens: Session renewal (30 min expiry)                                │   │
│  └─────────────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼ JWT Validation & User Context Extraction
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                 🌉 API GATEWAY LAYER                                        │
│                                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                       🚪 HTTP API Gateway v2 (utcn9m1wwg)                          │   │
│  │                                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                      🔒 JWT Authorizer (Native Cognito)                     │   │   │
│  │  │                                                                             │   │   │
│  │  │  • Identity Source: $request.header.Authorization                          │   │   │
│  │  │  • Token Validation: Automatic Cognito verification                        │   │   │
│  │  │  • Claims Injection: User context into Lambda event                        │   │   │
│  │  │  • Error Responses: 401 for invalid/expired tokens                         │   │   │
│  │  └─────────────────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                                     │   │
│  │  🛣️ API Routes:                                                                     │   │
│  │                                                                                     │   │
│  │  📱 Authentication Routes:        🏥 Hospital Data Routes:                        │   │
│  │  ├─ POST /auth/login               ├─ GET /api/boxes          (JWT Required)       │   │
│  │  ├─ POST /auth/refresh             ├─ GET /api/pasillos       (JWT Required)       │   │
│  │  └─ GET /me                        ├─ GET /api/agendas        (JWT Required)       │   │
│  │                                    ├─ POST /api/agendas       (JWT Required)       │   │
│  │  ⚙️ Configuration Routes:           ├─ PUT /api/agendas/{id}   (JWT Required)       │   │
│  │  ├─ GET /api/config                ├─ DELETE /api/agendas/{id} (JWT Required)      │   │
│  │  ├─ GET /api/config/{clientId}     └─ POST /api/migrate        (Admin Only)       │   │
│  │  └─ PUT /api/config/{clientId}                                                     │   │
│  └─────────────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼ Authenticated Requests + User Context
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                               ⚡ BUSINESS LOGIC LAYER                                       │
│                                    AWS Lambda Functions                                    │
│                                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                            🔧 Core API Functions                                    │   │
│  │                                                                                     │   │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │   │
│  │  │      Auth       │ │      Boxes      │ │     Agendas     │ │    Pasillos     │   │   │
│  │  │    Handlers     │ │    Handlers     │ │    Handlers     │ │    Handlers     │   │   │
│  │  │                 │ │                 │ │                 │ │                 │   │   │
│  │  │ • login()       │ │ • getBoxes()    │ │ • getAgendas()  │ │ • getPasillos() │   │   │
│  │  │ • refresh()     │ │ • updateBox()   │ │ • createAgenda()│ │ • createPasillo()│   │   │
│  │  │ • me()          │ │ • getBoxState() │ │ • updateAgenda()│ │ • updatePasillo()│   │   │
│  │  │ 📢 Publica:     │ │ 📢 Publica:     │ │ • deleteAgenda()│ │                 │   │   │
│  │  │ UserLoginEvent  │ │ BoxStateEvents  │ │ 📢 Publica:     │ │                 │   │   │
│  │  └─────────────────┘ └─────────────────┘ │ AgendaEvents    │ │                 │   │   │
│  │                                          └─────────────────┘ └─────────────────┘   │   │
│  │                                                                                     │   │
│  │  ┌─────────────────┐ ┌─────────────────┐                                          │   │
│  │  │ Personalization │ │   Migration     │                                          │   │
│  │  │    Handlers     │ │    Handlers     │                                          │   │
│  │  │                 │ │                 │                                          │   │
│  │  │ • getConfig()   │ │ • migrateData() │                                          │   │
│  │  │ • updateConfig()│ │ • syncLocal()   │                                          │   │
│  │  │ • listClients() │ │ • validateData()│                                          │   │
│  │  └─────────────────┘ └─────────────────┘                                          │   │
│  └─────────────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼ Event Publishing to SNS Topics
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                            📢 EVENT-DRIVEN COMMUNICATION LAYER                              │
│                                    Amazon SNS Topics                                       │
│                                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                              🔥 SNS Topic Architecture                              │   │
│  │                                                                                     │   │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │   │
│  │  │  👤 USER_EVENTS │ │ 📅 AGENDA_EVENTS│ │ 🔔 NOTIFICATIONS│ │  📦 BOX_EVENTS  │   │   │
│  │  │     Topic       │ │     Topic       │ │     Topic       │ │     Topic       │   │   │
│  │  │                 │ │                 │ │                 │ │                 │   │   │
│  │  │ Publishers:     │ │ Publishers:     │ │ Publishers:     │ │ Publishers:     │   │   │
│  │  │ • auth.js       │ │ • agendas.js    │ │ • All handlers  │ │ • boxes.js      │   │   │
│  │  │                 │ │                 │ │                 │ │ • agendas.js    │   │   │
│  │  │ Events:         │ │ Events:         │ │ Events:         │ │ Events:         │   │   │
│  │  │ • USER_LOGIN    │ │ • AGENDA_CREATED│ │ • SYSTEM_ALERT  │ │ • BOX_OCCUPIED  │   │   │
│  │  │ • USER_LOGOUT   │ │ • AGENDA_UPDATED│ │ • USER_NOTIFY   │ │ • BOX_AVAILABLE │   │   │
│  │  │                 │ │ • AGENDA_DELETED│ │ • ERROR_ALERT   │ │ • STATE_CHANGED │   │   │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼ Asynchronous Event Processing
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                              🎯 EVENT PROCESSING LAYER                                      │
│                                SNS Subscriber Handlers                                     │
│                                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                           ⚡ Event Handler Functions                                 │   │
│  │                                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                    👤 User Events Handler                                  │   │   │
│  │  │                  (userEventsHandler Lambda)                                │   │   │
│  │  │                                                                             │   │   │
│  │  │ Subscribed to: USER_EVENTS Topic                                           │   │   │
│  │  │ Processing:                                                                 │   │   │
│  │  │ • Login activity logging to DynamoDB                                       │   │   │
│  │  │ • User session statistics tracking                                         │   │   │
│  │  │ • Security audit trail                                                     │   │   │
│  │  │ • Automatic TTL for activity records                                       │   │   │
│  │  └─────────────────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                  📅 Agenda Events Handler                                   │   │   │
│  │  │                (agendaEventsHandler Lambda)                                 │   │   │
│  │  │                                                                             │   │   │
│  │  │ Subscribed to: AGENDA_EVENTS Topic                                         │   │   │
│  │  │ Processing:                                                                 │   │   │
│  │  │ • Box state change notifications                                           │   │   │
│  │  │ • Professional schedule updates                                            │   │   │
│  │  │ • Conflict detection and resolution                                        │   │   │
│  │  │ • Cross-service event publishing                                           │   │   │
│  │  └─────────────────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                    🔔 Notification Handler                                  │   │   │
│  │  │                 (notificationHandler Lambda)                                │   │   │
│  │  │                                                                             │   │   │
│  │  │ Subscribed to: NOTIFICATIONS Topic                                         │   │   │
│  │  │ Processing:                                                                 │   │   │
│  │  │ • System alert distribution                                                │   │   │
│  │  │ • User notification management                                             │   │   │
│  │  │ • Email/SMS integration (future)                                           │   │   │
│  │  │ • Notification history storage                                             │   │   │
│  │  └─────────────────────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼ Persistent Data Storage
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                💾 DATA PERSISTENCE LAYER                                   │
│                                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                          🗄️ Amazon DynamoDB - Single Table                         │   │
│  │                              Table: HospitalData                                   │   │
│  │                                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                           📊 Table Design                                   │   │   │
│  │  │                                                                             │   │   │
│  │  │ Primary Key: PK (Partition Key) + SK (Sort Key)                            │   │   │
│  │  │ GSI1: GSI1PK + GSI1SK (Global Secondary Index)                             │   │   │
│  │  │                                                                             │   │   │
│  │  │ Data Patterns:                                                              │   │   │
│  │  │                                                                             │   │   │
│  │  │ 🏥 Hospitals:                                                              │   │   │
│  │  │ • PK: HOSPITAL#{hospitalId}    SK: METADATA                                │   │   │
│  │  │                                                                             │   │   │
│  │  │ 🚪 Pasillos:                                                               │   │   │
│  │  │ • PK: HOSPITAL#{hospitalId}    SK: PASILLO#{pasilloId}                     │   │   │
│  │  │ • GSI1PK: PASILLO#{pasilloId}  GSI1SK: METADATA                            │   │   │
│  │  │                                                                             │   │   │
│  │  │ 📦 Boxes:                                                                  │   │   │
│  │  │ • PK: PASILLO#{pasilloId}      SK: BOX#{boxId}                             │   │   │
│  │  │ • GSI1PK: BOX#{boxId}          GSI1SK: PASILLO#{pasilloId}                 │   │   │
│  │  │                                                                             │   │   │
│  │  │ 📅 Agendas:                                                                │   │   │
│  │  │ • PK: BOX#{boxId}              SK: AGENDA#{fecha}#{hora}                   │   │   │
│  │  │ • GSI1PK: AGENDA#{agendaId}    GSI1SK: BOX#{boxId}                         │   │   │
│  │  │                                                                             │   │   │
│  │  │ 👤 User Preferences:                                                       │   │   │
│  │  │ • PK: USER#{userId}            SK: CONFIG#{clientId}                       │   │   │
│  │  │ • GSI1PK: CONFIG#{clientId}    GSI1SK: USER#{userId}                       │   │   │
│  │  │                                                                             │   │   │
│  │  │ 📈 Activity Logs (TTL enabled):                                            │   │   │
│  │  │ • PK: ACTIVITY#{userId}        SK: LOG#{timestamp}                         │   │   │
│  │  │ • TTL: 30 days automatic cleanup                                           │   │   │
│  │  └─────────────────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                                     │   │
│  │  ⚡ Performance Features:                                                           │   │
│  │  • Pay-per-request billing mode                                                    │   │
│  │  • Auto-scaling for traffic spikes                                                 │   │
│  │  • Single-table design for optimal performance                                     │   │
│  │  • GSI for flexible query patterns                                                 │   │
│  │  • TTL for automatic cleanup of temporary data                                     │   │
│  └─────────────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

---

## 🔄 **FLUJOS DE DATOS PRINCIPALES**

### 1. **🔐 Flujo de Autenticación**
```
Usuario → Django Login → Cognito Auth → JWT Tokens → Session Storage → API Calls
   ↓
SNS USER_LOGIN Event → UserEventsHandler → Activity Log (DynamoDB)
```

### 2. **📅 Flujo de Creación de Agenda**  
```
Usuario → Django Form → API Gateway (JWT) → createAgenda Lambda → DynamoDB
   ↓
SNS AGENDA_CREATED Event → AgendaEventsHandler → Box State Update → BOX_EVENTS
```

### 3. **📊 Flujo de Visualización**
```
Frontend Request → API Gateway (JWT) → getBoxes/getAgendas → DynamoDB Query
   ↓
Real-time state calculation → Response → Django Template Rendering
```

### 4. **🔔 Flujo de Notificaciones**
```
System Event → SNS NOTIFICATIONS Topic → NotificationHandler → User Alerts
```

---

## 🛠️ **TECNOLOGÍAS Y SERVICIOS UTILIZADOS**

### **Frontend:**
- **Django 4.x**: Framework web principal
- **HTML/CSS/JavaScript**: UI responsiva
- **Bootstrap**: Componentes de interfaz
- **JWT Session Management**: Manejo de sesiones seguro

### **Backend Serverless:**
- **AWS Lambda**: Funciones de negocio (Node.js 18.x)
- **API Gateway v2**: REST API con autorización JWT
- **Amazon Cognito**: Autenticación y autorización
- **Amazon SNS**: Comunicación desacoplada
- **DynamoDB**: Base de datos NoSQL

### **DevOps & Deployment:**
- **Serverless Framework**: Infrastructure as Code
- **AWS CloudFormation**: Stack management automático
- **CloudWatch**: Logging y monitoreo
- **AWS Academy**: Entorno de desarrollo

### **Patterns & Arquitectura:**
- **Event-Driven Architecture**: SNS + Lambda triggers
- **Single Table Design**: DynamoDB optimizado  
- **JWT Authorization**: Seguridad de API nativa
- **Multi-tenant**: Soporte para múltiples hospitales
- **Microservices**: Separación de responsabilidades

---

## 🎯 **BENEFICIOS DE LA ARQUITECTURA ACTUAL**

### **Escalabilidad:**
- Auto-scaling automático en todos los componentes
- Pay-per-use, costos optimizados
- Sin gestión de servidores

### **Seguridad:**
- Autenticación robusta con Cognito
- JWT tokens con expiración automática  
- Autorización granular por roles
- Audit trail completo

### **Mantenibilidad:**
- Código modular y desacoplado
- Event-driven permite extensibilidad
- Single table design simplifica queries
- Logging centralizado en CloudWatch

### **Confiabilidad:**
- Servicios managed de AWS
- Recuperación automática ante fallos
- Respaldo automático de DynamoDB  
- Monitoreo y alertas integrados

---

## 📊 **MÉTRICAS Y MONITOREO**

### **CloudWatch Dashboards:**
- Latencia de API endpoints
- Errores de autenticación
- Volumen de eventos SNS
- Performance de DynamoDB

### **Logging Strategy:**
- Structured logs en todas las Lambda
- Correlation IDs para tracing
- Error tracking y alertas
- User activity audit trail

### **Alertas Configuradas:**
- High error rates en APIs
- Failed authentication attempts
- DynamoDB throttling
- SNS delivery failures

---

*Última actualización: Septiembre 29, 2025*  
*Versión: 2.0 - Arquitectura Serverless Completa con SNS*
│  │                                                                                 │   │
│  │  App Client: 6i75cgnkchgir4oh0312ue98u0                                       │   │
│  │  • USER_PASSWORD_AUTH enabled                                                   │   │
│  │  • ADMIN_NO_SRP_AUTH enabled                                                    │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼ JWT Tokens
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                API GATEWAY LAYER                                       │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                           HTTP API v2 Gateway                                  │   │
│  │                                                                                 │   │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                       JWT Authorizer (Native)                          │   │   │
│  │  │                                                                         │   │   │
│  │  │  • Identity Source: $request.header.Authorization                      │   │   │
│  │  │  • Token Validation: Automatic via Cognito                             │   │   │
│  │  │  • Claims Extraction: Groups, email, custom attributes                 │   │   │
│  │  │  • Error Handling: 401 for invalid/expired tokens                      │   │   │
│  │  └─────────────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                                 │   │
│  │  Endpoints Configuration:                                                       │   │
│  │                                                                                 │   │
│  │  Auth API (utcn9m1wwg):           Main API (r8qjc8hqrl):                      │   │
│  │  ├─ POST /auth/login               ├─ GET /api/boxes (JWT required)            │   │
│  │  ├─ POST /auth/refresh             ├─ GET /api/pasillos (JWT required)         │   │
│  │  └─ GET /me                        ├─ GET /api/agendas (JWT required)          │   │
│  │                                    ├─ POST /api/agendas (JWT required)         │   │
│  │                                    ├─ GET /api/config (JWT required)           │   │
│  │                                    ├─ GET /api/config/{clientId} (JWT req.)    │   │
│  │                                    ├─ PUT /api/config/{clientId} (Admin only)  │   │
│  │                                    └─ POST /api/migrate (JWT required)         │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼ Authorized Requests + User Context
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              BUSINESS LOGIC LAYER                                      │
│                                     AWS Lambda                                         │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                              Lambda Functions                                   │   │
│  │                                                                                 │   │
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  ┌─────────────────┐   │   │
│  │  │     Auth      │  │     Boxes     │  │    Agendas    │  │   Pasillos      │   │   │
│  │  │   Handlers    │  │   Handlers    │  │   Handlers    │  │   Handlers      │   │   │
│  │  │               │  │               │  │               │  │                 │   │   │
│  │  │ • login()     │  │ • getBoxes()  │  │ • getAgendas()│  │ • getPasillos() │   │   │
│  │  │ • refresh()   │  │ • Role-based  │  │ • createAgenda│  │ • Role-based    │   │   │
│  │  │ • getProfile()│  │   filtering   │  │ • Auto-create │  │   filtering     │   │   │
│  │  └───────────────┘  └───────────────┘  └───────────────┘  └─────────────────┘   │   │
│  │                                                                                 │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                 │   │
│  │  │ Personalization │  │   Migration     │  │   Auth Utils    │                 │   │
│  │  │    Handlers     │  │    Handler      │  │   (Middleware)  │                 │   │
│  │  │                 │  │                 │  │                 │                 │   │
│  │  │ • listClients() │  │ • migrateFromSQL│  │ • extractUser() │                 │   │
│  │  │ • getConfig()   │  │ • (Has issues)  │  │ • filterByRole()│                 │   │
│  │  │ • updateConfig()│  │                 │  │ • checkPerms()  │                 │   │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘                 │   │
│  │                                                                                 │   │
│  │  Authorization Flow:                                                            │   │
│  │  1. API Gateway validates JWT → 2. Extract user from event context →           │   │
│  │  3. Apply role-based filtering → 4. Execute business logic →                   │   │
│  │  5. Return filtered results based on permissions                               │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼ Database Operations
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                               DATA PERSISTENCE LAYER                                   │
│                                      DynamoDB                                          │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                              Table: HospitalData                               │   │
│  │                                                                                 │   │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                        Entity Design Patterns                          │   │   │
│  │  │                                                                         │   │   │
│  │  │  Core Entities:                    Personalization Entities:           │   │   │
│  │  │  ┌─────────────────────────────┐   ┌─────────────────────────────────┐   │   │   │
│  │  │  │ AGENDA#uuid                 │   │ CLIENT#hospital001              │   │   │   │
│  │  │  │ ├─ profesional               │   │ ├─ SK: CONFIG#branding          │   │   │   │
│  │  │  │ ├─ especialidad              │   │ ├─ colors: {primary, secondary} │   │   │   │
│  │  │  │ ├─ fecha, horaInicio         │   │ ├─ logo: url                    │   │   │   │
│  │  │  │ └─ boxId (auto-creates box)  │   │ └─ name: "Hospital Name"        │   │   │   │
│  │  │  └─────────────────────────────┘   └─────────────────────────────────┘   │   │   │
│  │  │                                                                         │   │   │
│  │  │  ┌─────────────────────────────┐   ┌─────────────────────────────────┐   │   │   │
│  │  │  │ BOX#id                      │   │ CLIENT#hospital001              │   │   │   │
│  │  │  │ ├─ nombre                    │   │ ├─ SK: CONFIG#texts             │   │   │   │
│  │  │  │ ├─ pasilloId                 │   │ ├─ welcomeMessage               │   │   │   │
│  │  │  │ └─ (auto-creates pasillo)    │   │ ├─ labels: {boxes, pasillos}    │   │   │   │
│  │  │  └─────────────────────────────┘   │ └─ messages: {loading, error}   │   │   │   │
│  │  │                                    └─────────────────────────────────┘   │   │   │
│  │  │  ┌─────────────────────────────┐                                         │   │   │
│  │  │  │ PASILLO#id                  │   Assignment Logic:                      │   │   │
│  │  │  │ ├─ nombre                    │   • Box 1-10  → Pasillo A               │   │   │
│  │  │  │ └─ descripcion               │   • Box 11-20 → Pasillo B               │   │   │
│  │  │  └─────────────────────────────┘   • Box 21-30 → Pasillo C               │   │   │
│  │  └─────────────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                                 │   │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                     Global Secondary Indexes                           │   │   │
│  │  │                                                                         │   │   │
│  │  │  GSI1: Date-based queries                                               │   │   │
│  │  │  • PK: DATE#2024-01-15 → SK: BOX#id#TIME → Quick date filtering        │   │   │
│  │  │                                                                         │   │   │
│  │  │  GSI2: Box-based queries                                                │   │   │
│  │  │  • PK: BOX#id → SK: DATE#TIME → Schedules by box                       │   │   │
│  │  │                                                                         │   │   │
│  │  │  GSI3: Client-based queries (for personalization)                      │   │   │
│  │  │  • PK: CLIENT#hospitalId → SK: CONFIG#type → Multi-tenant config       │   │   │
│  │  └─────────────────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
│  Performance & Security:                                                                │
│  • Read/Write Capacity: On-demand scaling                                              │
│  • Encryption: At rest and in transit                                                  │
│  • Access: IAM roles with least privilege                                              │
│  • Backup: Point-in-time recovery enabled                                              │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow Architecture

### 1. **Authentication Flow**
```
User Login → Cognito User Pool → JWT Token → API Gateway Validation → Lambda Execution
```

### 2. **Authorization Flow**
```
JWT Claims → User Groups Extraction → Role-based Filtering → Permission Checks → Data Access
```

### 3. **Personalization Flow**
```
Client Request → JWT Validation → Client ID from Token → DynamoDB Query → Config Response
```

### 4. **Auto-provisioning Flow**
```
Create Agenda → Check Box Exists → Create Box if Missing → Check Pasillo → Create Pasillo if Missing
```

## 📊 Component Integration Matrix

| Component | Authentication | Authorization | Personalization | Auto-provisioning |
|-----------|:--------------:|:-------------:|:---------------:|:-----------------:|
| **Cognito** | ✅ Primary | ✅ Groups/Claims | ✅ hospital_id | ❌ |
| **API Gateway** | ✅ JWT Validation | ✅ Token Passing | ✅ Endpoint Protection | ✅ Request Routing |
| **Lambda Auth** | ✅ Login/Refresh | ❌ | ❌ | ❌ |
| **Lambda Business** | ✅ Token Extract | ✅ Role Filtering | ✅ Config CRUD | ✅ Entity Creation |
| **DynamoDB** | ❌ | ❌ | ✅ Config Storage | ✅ Entity Storage |

## 🚀 Migration Benefits

### **Before (Monolithic)**
- Single MySQL database
- Django-only authentication
- No role-based access control
- Manual configuration management
- Limited scalability

### **After (Serverless)**
- ✅ **Scalability**: Auto-scaling Lambda + DynamoDB
- ✅ **Security**: JWT + Cognito + Role-based access
- ✅ **Multi-tenant**: Client-specific personalization
- ✅ **Performance**: NoSQL queries + optimized indexes
- ✅ **Cost**: Pay-per-use model
- ✅ **Availability**: Multi-AZ deployment
- ✅ **Maintenance**: Managed services (99.99% uptime)

## 🔧 Technical Specifications

### **Authentication**
- **Provider**: Amazon Cognito User Pools
- **Token Type**: JWT (JSON Web Tokens)
- **Token Expiry**: 1 hour (configurable)
- **Refresh**: Automatic via refresh tokens
- **MFA**: Available (not currently enabled)

### **Authorization**
- **Method**: Role-based Access Control (RBAC)
- **Roles**: Admin, Personal, PersonalAdministrativo
- **Scope**: Hospital + Pasillo level filtering
- **Implementation**: JWT claims + Lambda middleware

### **Personalization**
- **Storage**: DynamoDB with CLIENT# partition key
- **Scope**: Colors, logos, texts, messages per client
- **Access Control**: Admin-only for updates, read for all
- **Cache**: API Gateway caching (optional)

### **Performance Metrics**
- **API Response Time**: < 300ms average
- **Authentication**: < 500ms login
- **Concurrent Users**: 1000+ supported
- **Database**: Single-digit millisecond queries
- **Availability**: 99.99% SLA target

---

**🏗️ Arquitectura migrada completamente a Serverless con Cognito + DynamoDB**
**📅 Última actualización**: Septiembre 2025 - Post implementación completa