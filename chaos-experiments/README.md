# Chaos Engineering - Sistema Hospital Boxes# Chaos Engineering - Sistema Hospital Boxes# 🔥 Chaos Engineering - Guía de Ejecución



Suite completa de experimentos de chaos engineering para validar la resiliencia del sistema serverless desplegado en AWS.



## 📋 ÍndiceSuite completa de experimentos de chaos engineering para validar la resiliencia del sistema.## � Diseñado para Linux/EC2



- [Inicio Rápido](#-inicio-rápido)

- [Arquitectura del Sistema](#️-arquitectura-del-sistema)

- [Experimentos Implementados](#-experimentos-implementados)## 🚀 Inicio RápidoTodos los scripts están optimizados para ejecutarse en **Linux** (Ubuntu/Amazon Linux).

- [Resultados y Análisis](#-resultados-y-análisis)

- [Requisitos Previos](#️-requisitos-previos)Para Windows PowerShell, los scripts `.ps1` están disponibles pero los `.sh` son la opción principal.

- [Configuración del Sistema](#-configuración-del-sistema)

- [Troubleshooting](#-troubleshooting)### 1. Configurar (solo una vez)

- [¿Implementar Gremlin?](#-implementar-gremlin)

- [Roadmap](#-roadmap)## �🚀 Inicio Rápido (Completamente Automatizado)



---```bash



## 🚀 Inicio Rápido./setup.shEste directorio contiene todos los experimentos de Chaos Engineering para validar la resiliencia del Sistema de Visualización de Boxes Hospitalarios.



### 1️⃣ Configurar (solo primera vez o cuando expire token)```



```bash### ✅ Setup en 3 Pasos

./setup.sh

```Este comando:



**Qué hace:**- ✅ Obtiene JWT token de Cognito User Pool```bash

- ✅ Consulta CloudFormation stack `hospital-boxes-api-dev`

- ✅ Obtiene JWT token de Cognito User Pool (usuario: `admin@hospital.com`)- ✅ Detecta automáticamente el API Gateway endpoint# 1. Instalar dependencias (una sola vez)

- ✅ Detecta automáticamente API Gateway HTTP API endpoint

- ✅ Crea/actualiza archivo `.env` con configuración completa- ✅ Crea/actualiza archivo `.env` con la configuraciónchmod +x install-dependencies.sh

- ✅ Valida token con request real al API

- ✅ Valida que el token funcione./install-dependencies.sh

**Token válido por:** 60 minutos



**Salida esperada:**

```**Duración del token:** 60 minutos# 2. Configurar credenciales (una sola vez)

════════════════════════════════════════════════════════════════

   🔧 SETUP DE CHAOS ENGINEERING# Opción A: Variables de entorno (RECOMENDADO - Totalmente automático)

════════════════════════════════════════════════════════════════

### 2. Ejecutar experimentoscp .env.example .env

[INFO] Verificando Python 3...

[INFO] Obteniendo configuración de AWS...nano .env  # Edita y agrega tus credenciales de Cognito

[SUCCESS] ✅ Token válido - API respondió correctamente

```bashexport $(cat .env | grep -v '^#' | xargs)

════════════════════════════════════════════════════════════════

   ✅ CONFIGURACIÓN COMPLETADA./run-all-experiments.sh

════════════════════════════════════════════════════════════════

```# Opción B: O usa el setup interactivo

🔑 JWT Token: eyJraWQiOiJxxx...

🌐 API Endpoint: https://44wvhl6j05.execute-api.us-east-1.amazonaws.com./setup-jwt-secrets-manager.sh  # Selecciona opción A con tus credenciales

⏱️  Token válido por: 60 minutos

```Este comando ejecuta automáticamente todos los experimentos:



### 2️⃣ Ejecutar suite completa1. **DoS Attack** - 1000 requests con 50 concurrentes# 3. Ejecutar TODOS los experimentos automáticamente



```bash2. **Lambda Latency** - 500 requests para medir degradaciónchmod +x run-all-chaos-experiments.sh

./run-all-experiments.sh

```3. **SNS Resilience** - Test de mensajería asíncrona./run-all-chaos-experiments.sh



**Qué hace:**4. **DynamoDB Throttling** - 800 requests para forzar límites```

- ✅ Carga configuración desde `.env`

- ✅ Valida que el token siga válido5. **Lambda Error Injection** - 300 requests con 30% errores inválidos

- ✅ Ejecuta 5 experimentos secuencialmente

- ✅ Espera 30s entre cada experimento**¡Eso es todo!** El sistema se encarga de:

- ✅ Genera reporte consolidado `SUITE-REPORT.md`

## 📊 Resultados- ✅ Obtener JWT automáticamente usando tus credenciales de Cognito

**Duración total:** ~40-45 minutos

- ✅ Guardar JWT en AWS Secrets Manager (reutilizable)

---

Los resultados se guardan en:- ✅ Auto-detectar AWS Account ID y región

## 🏗️ Arquitectura del Sistema

```- ✅ Auto-detectar API Gateway URLs

### Stack AWS (CloudFormation: `hospital-boxes-api-dev`)

results/suite-YYYYMMDD-HHMMSS/- ✅ Ejecutar todos los experimentos secuencialmente

```

┌─────────────────────────────────────────────────────────────┐├── SUITE-REPORT.md          # Reporte consolidado- ✅ Generar reportes automáticos

│                    CLIENTE (Chaos Scripts)                  │

└────────────────────┬────────────────────────────────────────┘├── 01-dos-attack.log        # Log experimento 1- ✅ Recopilar métricas de CloudWatch

                     │ HTTP + JWT (Cognito)

                     ▼├── 02-lambda-latency.log    # Log experimento 2

┌─────────────────────────────────────────────────────────────┐

│              API Gateway HTTP API v2                        │├── 03-sns-failure.log       # Log experimento 3---

│  ID: 44wvhl6j05                                            │

│  Endpoints: /api/boxes, /api/agendas, /api/pasillos       │├── 04-dynamodb-throttling-sim.log  # Log experimento 4

└────────────────────┬────────────────────────────────────────┘

                     │└── 05-lambda-errors-sim.log # Log experimento 5## 📋 Resumen de Herramientas

        ┌────────────┼────────────┐

        ▼            ▼            ▼```

┌──────────┐  ┌──────────┐  ┌──────────┐

│ Lambda   │  │ Lambda   │  │ Lambda   │| Herramienta | Experimentos | Costo | Estado |

│ boxes.js │  │ agendas  │  │ pasillos │

└────┬─────┘  └────┬─────┘  └────┬─────┘## 🔧 Estructura del Proyecto|-------------|--------------|-------|--------|

     │             │             │

     └─────────────┼─────────────┘| **Bash Scripts** | 5 | $0 | ✅ Automatizado |

                   ▼

        ┌──────────────────────┐```| **Suite Completa** | 5 | $0 | ✅ Automatizado |

        │   DynamoDB Table     │

        │   HospitalData       │chaos-experiments/

        │   PAY_PER_REQUEST    │

        └──────────────────────┘├── setup.sh                    # ⭐ Configuración (obtiene JWT + API)**Total: 5 experimentos - Costo: $0 - Tiempo: ~40 minutos**

```

├── run-all-experiments.sh      # ⭐ Ejecuta todos los experimentos

### Autenticación

├── get-cognito-jwt.py          # Script Python interno (usado por setup.sh)> ⚠️ **Nota sobre AWS FIS**: Los experimentos fueron implementados con Bash scripts 

```

Cognito User Pool├── .env                        # Variables de entorno (generado)> debido a limitaciones de permisos en AWS Academy Learner Lab. Los scripts simulan 

├── ID: us-east-1_uD6JDiKHn

├── Client: HospitalBoxesUserPoolClient├── .env.example                # Plantilla de variables> el comportamiento de AWS FIS sin requerir permisos especiales.

├── Usuarios: admin@hospital.com / Admin123!

└── Token validity: 60 minutos├── bash-scripts/               # Scripts individuales de experimentos

```

│   ├── 01-dos-attack.sh---

---

│   ├── 02-lambda-latency.sh

## 🧪 Experimentos Implementados

│   ├── 03-sns-failure.sh## 📂 Estructura del Proyecto

### 1. DoS Attack (`01-dos-attack.sh`)

- **Requests:** 1000 con 50 concurrentes│   ├── 04-dynamodb-throttling-sim.sh

- **Valida:** Rate limiting, throttling Lambda

- **Esperado:** >80% éxito│   └── 05-lambda-errors-sim.sh```



### 2. Lambda Latency (`02-lambda-latency.sh`)└── results/                    # Resultados de ejecucioneschaos-experiments/

- **Requests:** 500 con 30 concurrentes

- **Valida:** Cold starts, degradación latencia```├── 📄 README.md                        # Esta guía

- **Esperado:** 0.15s → 1.2-2.5s

├── 📄 Experiments.md                   # Plan detallado de experimentos

### 3. SNS Resilience (`03-sns-failure.sh`)

- **Duración:** ~208s## 🔐 Autenticación├── 📁 bash-scripts/                    # Scripts Bash (3 experimentos)

- **Valida:** Circuit breaker, DLQ

- **Esperado:** API funciona aunque SNS falle│   ├── 01-dos-attack.{sh,ps1}          ✅ DoS Attack Simulation



### 4. DynamoDB Throttling (`04-dynamodb-throttling-sim.sh`)El sistema usa **Cognito User Pool JWT** con las siguientes credenciales:│   ├── 02-lambda-latency.sh            ✅ Lambda Latency Injection

- **Requests:** 800 con 50 concurrentes

- **Valida:** Throttling 429, retry backoff│   ├── 03-sns-failure.sh               ✅ SNS Topic Failure

- **Esperado:** >10% throttling, >70% éxito

- **Usuario:** `admin@hospital.com`│   ├── 04-dynamodb-throttling-sim.sh   ✅ DynamoDB Throttling (Bash simulation)

### 5. Lambda Error Injection (`05-lambda-errors-sim.sh`)

- **Requests:** 300 (30% inválidos)- **Contraseña:** `Admin123!`│   └── 05-lambda-errors-sim.sh         ✅ Lambda Error Injection (Bash simulation)

- **Valida:** Validación input, error handling

- **Esperado:** ~30% errores 400, 0% errores 500- **User Pool:** `us-east-1_uD6JDiKHn`├── 📁 aws-fis/                         # Templates FIS (referencia/futuro uso)



---│   ├── dynamodb-throttling.json        📖 Template de referencia



## 📊 Resultados y AnálisisEl token se obtiene automáticamente al ejecutar `./setup.sh`.│   └── lambda-error-injection.json     📖 Template de referencia



Resultados guardados en: `results/suite-YYYYMMDD-HHMMSS/`├── 📁 gremlin/                         # Configuración Gremlin (no implementado)



```## ⚠️ Requisitos│   ├── setup-guide.md                  📖 Guía de setup

├── SUITE-REPORT.md           # Reporte consolidado

├── 01-dos-attack.log│   └── experiments-config.yaml         ⚙️ Configuración

├── 02-lambda-latency.log

├── 03-sns-failure.log- AWS CLI configurado (`aws configure`)└── 📁 results/                         # Resultados de experimentos

├── 04-dynamodb-throttling-sim.log

└── 05-lambda-errors-sim.log- Python 3 con boto3 (`pip3 install boto3`)    ├── REPORT_TEMPLATE.md              📝 Plantilla de reportes

```

- Bash (Git Bash en Windows)    └── experiment-XX-*/                📊 Resultados individuales

---

- Stack CloudFormation `hospital-boxes-api-dev` desplegado```

## ⚙️ Requisitos Previos



1. **AWS CLI** configurado (`aws sts get-caller-identity`)

2. **Python 3** con boto3 (`pip3 install boto3`)## 🔄 Renovar Token---

3. **Bash** >= 4.0

4. **Stack desplegado** (`aws cloudformation describe-stacks --stack-name hospital-boxes-api-dev`)



---Si el token expira (después de 60 minutos), simplemente ejecuta:## ⚙️ Prerequisitos



## 🔧 Configuración del Sistema



### ¿Por qué 2 archivos .env en el proyecto?```bash### Software Required:



El proyecto tiene **2 archivos .env separados** con propósitos diferentes:./setup.sh```bash



| Archivo | Propósito | Variables | Editado por |```# Verificar instalaciones

|---------|-----------|-----------|-------------|

| `serverless-api/.env` | Backend development | DynamoDB, MySQL, config infraestructura | Manual |bash --version          # Bash 4.0+

| `chaos-experiments/.env` | Testing | JWT token (60 min), API endpoint | `setup.sh` auto |

## 📝 Ejecutar Experimento Individualcurl --version          # curl 7.0+

**No se pueden unificar** porque:

- Contextos diferentes (backend vs testing)aws --version           # AWS CLI 2.0+

- Ciclos de vida diferentes (persistente vs temporal 60 min)

- Uno es manual, otro auto-generadoSi solo quieres ejecutar un experimento específico:node --version          # Node.js 18+ (opcional, para Serverless)



---```



## 🐛 Troubleshooting```bash



### Token inválido# Cargar configuración### AWS Configuration:

```bash

./setup.sh  # Obtiene nuevo tokenexport $(cat .env | grep -v '^#' | grep -v '^$' | xargs)```bash

```

# Configurar AWS CLI

### API no responde

```bash# Ejecutar experimentoaws configure

aws cloudformation describe-stacks --stack-name hospital-boxes-api-dev

cd serverless-api && npx serverless deploybash bash-scripts/01-dos-attack.sh

```

```# Verificar acceso

### Python boto3 no encontrado

```bashaws sts get-caller-identity

pip3 install boto3

```## 🎯 Interpretación de Resultados```



---



## 🤔 ¿Implementar Gremlin?El reporte incluye análisis automático:### Variables de Entorno:



### Comparación```bash



| Aspecto | Scripts Bash | Gremlin | AWS FIS |- ✅ **Todos exitosos**: Sistema resiliente bajo todas las condiciones# Crear archivo .env en el directorio raíz

|---------|--------------|---------|---------|

| **Costo** | ✅ $0 | ❌ $199/mes | ⚠️ ~$0.10/exp |- ⚠️ **Mayoría exitosos**: Sistema funcional con áreas de mejoracat > .env << EOF

| **Complejidad** | ✅ Simple | ⚠️ Requiere agente | ⚠️ Requiere IAM |

| **Alcance** | ⚠️ Solo HTTP | ✅ Infraestructura | ✅ AWS nativo |- ❌ **Múltiples fallas**: Requiere atención inmediata# API Configuration

| **Serverless** | ✅ Compatible | ❌ No hay donde instalar agente | ✅ Compatible |

API_ENDPOINT=https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/dev/api

### Recomendación: ❌ NO implementar Gremlin

Revisa `SUITE-REPORT.md` para recomendaciones específicas.JWT_TOKEN=your-jwt-token-here

**Razones:**



1. **Arquitectura 100% serverless**

   - No hay EC2 donde instalar agente Gremlin## 🐛 Troubleshooting# AWS Configuration

   - Lambda no soporta agentes

   - DynamoDB/API Gateway son managed servicesAWS_REGION=us-east-1



2. **Scripts actuales suficientes**### Token inválidoAWS_ACCOUNT_ID=your-account-id

   - Cubren todos los vectores relevantes

   - Costo $0 vs $199/mes```bash

   - Control total del código

./setup.sh  # Obtener nuevo token# Gremlin Configuration (opcional, solo para experimentos #6 y #7)

3. **Alternativa mejor: AWS FIS**

   - Si necesitas chaos avanzado en el futuro```GREMLIN_TEAM_ID=your-team-id

   - Pay-per-use (~$0.10/experimento)

   - Integración nativa con serverlessGREMLIN_API_KEY=your-api-key



**Cuándo considerar FIS:**### API no respondeGREMLIN_API_SECRET=your-api-secret

- Simular caídas de AZ

- Throttling controlado de DynamoDBVerifica que el stack esté desplegado:EOF

- Inyección de errores en Lambda (sin modificar código)

```bash

---

aws cloudformation describe-stacks --stack-name hospital-boxes-api-dev# Cargar variables

## 📅 Roadmap

```source .env

### ✅ Completado

```

- [x] 5 experimentos funcionando

- [x] Autenticación Cognito JWT### Dependencias faltantes

- [x] Detección automática API endpoint

- [x] Token 60 minutos```bash---

- [x] Suite runner con reporte

- [x] Simplificación a 2 archivos (setup + run)pip3 install boto3



### 🔄 En Progreso```## 🎯 Ejecutar Experimentos



- [ ] Redesplegar API con token 60 min

- [ ] Ejecución suite completa### 🔹 BASH SCRIPTS (Experimentos #1-3)

- [ ] Documentación resultados reales

#### Experimento #1: DoS Attack

### 📋 Próximos Pasos```bash

cd bash-scripts

**Corto plazo:**

1. Redesplegar API (`cd serverless-api && npx serverless deploy`)# Dar permisos de ejecución

2. Ejecutar suite completachmod +x 01-dos-attack.sh

3. Optimizar según resultados

# Ejecutar

**Mediano plazo:**./01-dos-attack.sh

4. CloudWatch dashboards

5. CI/CD automation (GitHub Actions)# Resultados en:

6. Documentar hallazgos en informe final# ../results/experiment-01-dos/

```

**Largo plazo (opcional):**

7. Considerar AWS FIS si se necesita chaos de infraestructura#### Experimento #2: Lambda Latency

```bash

---chmod +x 02-lambda-latency.sh

./02-lambda-latency.sh

**Última actualización:** 2025-11-07  

**Versión:** 2.0 (refactorización simplificada)# Resultados en:

# ../results/experiment-02-latency/
```

#### Experimento #3: SNS Failure
```bash
chmod +x 03-sns-failure.sh
./03-sns-failure.sh

# ⚠️ Este experimento modifica configuración SNS
# Asegúrate de tener backup

# Resultados en:
# ../results/experiment-03-sns/
```

---

### 🔹 Experimentos #4-5: Simulaciones Bash

> **ℹ️ Nota:** Estos experimentos simulan el comportamiento de AWS FIS usando Bash scripts.
> Se implementaron así debido a limitaciones de permisos en AWS Academy Learner Lab.

#### Experimento #4: DynamoDB Throttling Simulation
```bash
cd bash-scripts
chmod +x 04-dynamodb-throttling-sim.sh
./04-dynamodb-throttling-sim.sh

# Método: Carga masiva concurrente para forzar throttling
# Duración: 5 minutos
# Requests: 50 concurrentes cada 0.1s
# Métricas: Throttle rate, success rate, recovery time
```

#### Experimento #5: Lambda Error Injection Simulation
```bash
chmod +x 05-lambda-errors-sim.sh
./05-lambda-errors-sim.sh

# Método: Requests inválidos para forzar errores Lambda
# Duración: 5 minutos
# Error injection rate: 30% de requests
# Tipos de errores: 400, 500, JSON malformado, IDs inexistentes
```

**📊 Ambos experimentos generan:**
- CSV de requests con timestamps
- Logs de status (success/error/throttle)
- Reporte en Markdown con métricas
- Comparación baseline vs chaos vs recovery

---

### 🗂️ Templates AWS FIS (Referencia)

Los templates AWS FIS están disponibles en `aws-fis/` como referencia:
- `dynamodb-throttling.json` - Template para throttling DynamoDB
- `lambda-error-injection.json` - Template para inyección de errores

**Uso futuro:** Si obtienes una cuenta AWS con permisos FIS completos, puedes:
1. Actualizar ARNs en los templates
2. Crear templates: `aws fis create-experiment-template --cli-input-json file://dynamodb-throttling.json`
3. Ejecutar: `aws fis start-experiment --experiment-template-id <ID>`

---

### 🔹 GREMLIN (No Implementado)

#### Setup Inicial:
```bash
cd gremlin

# Leer guía de setup
cat setup-guide.md

# Pasos:
# 1. Registrarse en https://app.gremlin.com/signup
# 2. Crear API Key
# 3. Configurar AWS IAM role
# 4. Conectar integración AWS
```

#### Experimento #6: CPU Stress
```bash
# Opción A: Desde Gremlin UI
# 1. Ir a https://app.gremlin.com/attacks/new
# 2. Target: hospital-boxes-api-dev-getBoxes
# 3. Attack: CPU 90% por 5 minutos
# 4. Run Attack

# Opción B: Desde CLI
gremlin attack-lambda cpu \
  --function-name hospital-boxes-api-dev-getBoxes \
  --percent 90 \
  --length 300 \
  --region us-east-1
```

#### Experimento #7: Memory Exhaustion
```bash
# Desde Gremlin UI o CLI
gremlin attack-lambda memory \
  --function-name hospital-boxes-api-dev-createAgenda \
  --percent 95 \
  --length 300 \
  --region us-east-1
```

---

## 📊 Monitorear Resultados

### CloudWatch Dashboards:
```bash
# Abrir CloudWatch en browser
open "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1"

# Ver métricas clave:
# - Lambda: Duration, Errors, Throttles, Concurrent Executions
# - DynamoDB: ThrottledRequests, ConsumedReadCapacity
# - API Gateway: Count, 4XXError, 5XXError, Latency
```

### Logs en Tiempo Real:
```bash
# Lambda logs
aws logs tail /aws/lambda/hospital-boxes-api-dev-getBoxes --follow

# API Gateway logs
aws logs tail /aws/apigateway/hospital-boxes-api --follow
```

### Métricas Personalizadas:
```bash
# Success rate
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum

# Error rate
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum
```

---

## 📝 Documentar Resultados

### Crear Reporte Individual:
```bash
cd results

# Copiar template
cp REPORT_TEMPLATE.md experiment-01-dos-report.md

# Editar con tus resultados
nano experiment-01-dos-report.md

# Agregar capturas de CloudWatch
mkdir -p experiment-01-dos/screenshots
# Copiar screenshots aquí
```

### Consolidar Reportes:
```bash
# Al final de todos los experimentos, crear reporte final
cat > FINAL_REPORT.md << EOF
# Reporte Final - Chaos Engineering

## Experimentos Ejecutados: 7/7

1. ✅ DoS Attack (Bash)
2. ✅ Lambda Latency (Bash)
3. ✅ SNS Failure (Bash)
4. ✅ DynamoDB Throttling (AWS FIS)
5. ✅ Lambda Errors (AWS FIS)
6. ✅ CPU Stress (Gremlin)
7. ✅ Memory Exhaustion (Gremlin)

## Resumen de Hallazgos:
[Completar después de todos los experimentos]

## Mejoras Implementadas:
[Listar mejoras implementadas]

## Conclusión Final:
[Conclusión general de resiliencia del sistema]
EOF
```

---

## 🎯 Orden Recomendado de Ejecución

### Semana 1: Bash Scripts (Rápido, sin costo)
```
Día 1: Experimento #1 (DoS Attack)         ← Empezar aquí
Día 2: Experimento #2 (Lambda Latency)
Día 3: Experimento #3 (SNS Failure)
```

### Semana 2: AWS FIS + Gremlin
```
Día 1: Setup de AWS FIS + Experimento #4
Día 2: Experimento #5 (Lambda Errors)
Día 3: Setup de Gremlin
Día 4: Experimento #6 (CPU Stress)
Día 5: Experimento #7 (Memory Exhaustion)
```

### Semana 3: Análisis y Mejoras
```
Día 1-2: Análisis de todos los resultados
Día 3-4: Implementar mejoras críticas
Día 5: Re-validar con experimentos selectos
```

---

## 🚨 Troubleshooting

### Error: "Permission denied"
```bash
# Dar permisos a scripts
chmod +x bash-scripts/*.sh
```

### Error: "AWS CLI not configured"
```bash
# Configurar AWS
aws configure
# Ingresar: Access Key, Secret Key, Region (us-east-1)
```

### Error: "JWT Token expired"
```bash
# Obtener nuevo token
curl -X POST $API_ENDPOINT/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"your-user","password":"your-pass"}'

# Actualizar variable
export JWT_TOKEN="nuevo-token"
```

### Scripts no encuentran API
```bash
# Verificar que la variable esté definida
echo $API_ENDPOINT

# Si está vacío, definir:
export API_ENDPOINT="https://YOUR_API.execute-api.us-east-1.amazonaws.com/dev/api"
```

---

## 📚 Recursos Adicionales

- **Guía Completa:** `../CHAOS_ENGINEERING_GUIA.md`
- **Resumen Ejecutivo:** `../CHAOS_ENGINEERING_RESUMEN.md`
- **Plan Detallado:** `Experiments.md`
- **AWS FIS Docs:** https://docs.aws.amazon.com/fis/
- **Gremlin Docs:** https://www.gremlin.com/docs/

---

## ✅ Checklist de Ejecución

### Preparación:
- [ ] AWS CLI configurado
- [ ] Variables de entorno definidas
- [ ] JWT token obtenido
- [ ] Scripts con permisos de ejecución

### Experimentos Bash:
- [ ] Experimento #1: DoS Attack ejecutado
- [ ] Experimento #2: Lambda Latency ejecutado
- [ ] Experimento #3: SNS Failure ejecutado

### Experimentos AWS FIS:
- [ ] Role IAM para FIS creado
- [ ] Templates actualizados con Account ID
- [ ] Experimento #4: DynamoDB Throttling ejecutado
- [ ] Experimento #5: Lambda Errors ejecutado

### Experimentos Gremlin:
- [ ] Cuenta Gremlin registrada
- [ ] API Key creado
- [ ] Integración AWS configurada
- [ ] Experimento #6: CPU Stress ejecutado
- [ ] Experimento #7: Memory Exhaustion ejecutado

### Documentación:
- [ ] 7 reportes individuales completados
- [ ] Screenshots de métricas guardados
- [ ] Reporte final consolidado creado
- [ ] Mejoras propuestas documentadas

---

**¡Listo para ejecutar! Empieza con el Experimento #1: DoS Attack** 🚀

```bash
cd bash-scripts
./01-dos-attack.sh
```
