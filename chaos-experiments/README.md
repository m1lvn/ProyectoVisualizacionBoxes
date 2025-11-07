# Chaos Engineering - Sistema Hospital Boxes# 🔥 Chaos Engineering - Guía de Ejecución



Suite completa de experimentos de chaos engineering para validar la resiliencia del sistema.## � Diseñado para Linux/EC2



## 🚀 Inicio RápidoTodos los scripts están optimizados para ejecutarse en **Linux** (Ubuntu/Amazon Linux).

Para Windows PowerShell, los scripts `.ps1` están disponibles pero los `.sh` son la opción principal.

### 1. Configurar (solo una vez)

## �🚀 Inicio Rápido (Completamente Automatizado)

```bash

./setup.shEste directorio contiene todos los experimentos de Chaos Engineering para validar la resiliencia del Sistema de Visualización de Boxes Hospitalarios.

```

### ✅ Setup en 3 Pasos

Este comando:

- ✅ Obtiene JWT token de Cognito User Pool```bash

- ✅ Detecta automáticamente el API Gateway endpoint# 1. Instalar dependencias (una sola vez)

- ✅ Crea/actualiza archivo `.env` con la configuraciónchmod +x install-dependencies.sh

- ✅ Valida que el token funcione./install-dependencies.sh



**Duración del token:** 60 minutos# 2. Configurar credenciales (una sola vez)

# Opción A: Variables de entorno (RECOMENDADO - Totalmente automático)

### 2. Ejecutar experimentoscp .env.example .env

nano .env  # Edita y agrega tus credenciales de Cognito

```bashexport $(cat .env | grep -v '^#' | xargs)

./run-all-experiments.sh

```# Opción B: O usa el setup interactivo

./setup-jwt-secrets-manager.sh  # Selecciona opción A con tus credenciales

Este comando ejecuta automáticamente todos los experimentos:

1. **DoS Attack** - 1000 requests con 50 concurrentes# 3. Ejecutar TODOS los experimentos automáticamente

2. **Lambda Latency** - 500 requests para medir degradaciónchmod +x run-all-chaos-experiments.sh

3. **SNS Resilience** - Test de mensajería asíncrona./run-all-chaos-experiments.sh

4. **DynamoDB Throttling** - 800 requests para forzar límites```

5. **Lambda Error Injection** - 300 requests con 30% errores inválidos

**¡Eso es todo!** El sistema se encarga de:

## 📊 Resultados- ✅ Obtener JWT automáticamente usando tus credenciales de Cognito

- ✅ Guardar JWT en AWS Secrets Manager (reutilizable)

Los resultados se guardan en:- ✅ Auto-detectar AWS Account ID y región

```- ✅ Auto-detectar API Gateway URLs

results/suite-YYYYMMDD-HHMMSS/- ✅ Ejecutar todos los experimentos secuencialmente

├── SUITE-REPORT.md          # Reporte consolidado- ✅ Generar reportes automáticos

├── 01-dos-attack.log        # Log experimento 1- ✅ Recopilar métricas de CloudWatch

├── 02-lambda-latency.log    # Log experimento 2

├── 03-sns-failure.log       # Log experimento 3---

├── 04-dynamodb-throttling-sim.log  # Log experimento 4

└── 05-lambda-errors-sim.log # Log experimento 5## 📋 Resumen de Herramientas

```

| Herramienta | Experimentos | Costo | Estado |

## 🔧 Estructura del Proyecto|-------------|--------------|-------|--------|

| **Bash Scripts** | 5 | $0 | ✅ Automatizado |

```| **Suite Completa** | 5 | $0 | ✅ Automatizado |

chaos-experiments/

├── setup.sh                    # ⭐ Configuración (obtiene JWT + API)**Total: 5 experimentos - Costo: $0 - Tiempo: ~40 minutos**

├── run-all-experiments.sh      # ⭐ Ejecuta todos los experimentos

├── get-cognito-jwt.py          # Script Python interno (usado por setup.sh)> ⚠️ **Nota sobre AWS FIS**: Los experimentos fueron implementados con Bash scripts 

├── .env                        # Variables de entorno (generado)> debido a limitaciones de permisos en AWS Academy Learner Lab. Los scripts simulan 

├── .env.example                # Plantilla de variables> el comportamiento de AWS FIS sin requerir permisos especiales.

├── bash-scripts/               # Scripts individuales de experimentos

│   ├── 01-dos-attack.sh---

│   ├── 02-lambda-latency.sh

│   ├── 03-sns-failure.sh## 📂 Estructura del Proyecto

│   ├── 04-dynamodb-throttling-sim.sh

│   └── 05-lambda-errors-sim.sh```

└── results/                    # Resultados de ejecucioneschaos-experiments/

```├── 📄 README.md                        # Esta guía

├── 📄 Experiments.md                   # Plan detallado de experimentos

## 🔐 Autenticación├── 📁 bash-scripts/                    # Scripts Bash (3 experimentos)

│   ├── 01-dos-attack.{sh,ps1}          ✅ DoS Attack Simulation

El sistema usa **Cognito User Pool JWT** con las siguientes credenciales:│   ├── 02-lambda-latency.sh            ✅ Lambda Latency Injection

│   ├── 03-sns-failure.sh               ✅ SNS Topic Failure

- **Usuario:** `admin@hospital.com`│   ├── 04-dynamodb-throttling-sim.sh   ✅ DynamoDB Throttling (Bash simulation)

- **Contraseña:** `Admin123!`│   └── 05-lambda-errors-sim.sh         ✅ Lambda Error Injection (Bash simulation)

- **User Pool:** `us-east-1_uD6JDiKHn`├── 📁 aws-fis/                         # Templates FIS (referencia/futuro uso)

│   ├── dynamodb-throttling.json        📖 Template de referencia

El token se obtiene automáticamente al ejecutar `./setup.sh`.│   └── lambda-error-injection.json     📖 Template de referencia

├── 📁 gremlin/                         # Configuración Gremlin (no implementado)

## ⚠️ Requisitos│   ├── setup-guide.md                  📖 Guía de setup

│   └── experiments-config.yaml         ⚙️ Configuración

- AWS CLI configurado (`aws configure`)└── 📁 results/                         # Resultados de experimentos

- Python 3 con boto3 (`pip3 install boto3`)    ├── REPORT_TEMPLATE.md              📝 Plantilla de reportes

- Bash (Git Bash en Windows)    └── experiment-XX-*/                📊 Resultados individuales

- Stack CloudFormation `hospital-boxes-api-dev` desplegado```



## 🔄 Renovar Token---



Si el token expira (después de 60 minutos), simplemente ejecuta:## ⚙️ Prerequisitos



```bash### Software Required:

./setup.sh```bash

```# Verificar instalaciones

bash --version          # Bash 4.0+

## 📝 Ejecutar Experimento Individualcurl --version          # curl 7.0+

aws --version           # AWS CLI 2.0+

Si solo quieres ejecutar un experimento específico:node --version          # Node.js 18+ (opcional, para Serverless)

```

```bash

# Cargar configuración### AWS Configuration:

export $(cat .env | grep -v '^#' | grep -v '^$' | xargs)```bash

# Configurar AWS CLI

# Ejecutar experimentoaws configure

bash bash-scripts/01-dos-attack.sh

```# Verificar acceso

aws sts get-caller-identity

## 🎯 Interpretación de Resultados```



El reporte incluye análisis automático:### Variables de Entorno:

```bash

- ✅ **Todos exitosos**: Sistema resiliente bajo todas las condiciones# Crear archivo .env en el directorio raíz

- ⚠️ **Mayoría exitosos**: Sistema funcional con áreas de mejoracat > .env << EOF

- ❌ **Múltiples fallas**: Requiere atención inmediata# API Configuration

API_ENDPOINT=https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/dev/api

Revisa `SUITE-REPORT.md` para recomendaciones específicas.JWT_TOKEN=your-jwt-token-here



## 🐛 Troubleshooting# AWS Configuration

AWS_REGION=us-east-1

### Token inválidoAWS_ACCOUNT_ID=your-account-id

```bash

./setup.sh  # Obtener nuevo token# Gremlin Configuration (opcional, solo para experimentos #6 y #7)

```GREMLIN_TEAM_ID=your-team-id

GREMLIN_API_KEY=your-api-key

### API no respondeGREMLIN_API_SECRET=your-api-secret

Verifica que el stack esté desplegado:EOF

```bash

aws cloudformation describe-stacks --stack-name hospital-boxes-api-dev# Cargar variables

```source .env

```

### Dependencias faltantes

```bash---

pip3 install boto3

```## 🎯 Ejecutar Experimentos


### 🔹 BASH SCRIPTS (Experimentos #1-3)

#### Experimento #1: DoS Attack
```bash
cd bash-scripts

# Dar permisos de ejecución
chmod +x 01-dos-attack.sh

# Ejecutar
./01-dos-attack.sh

# Resultados en:
# ../results/experiment-01-dos/
```

#### Experimento #2: Lambda Latency
```bash
chmod +x 02-lambda-latency.sh
./02-lambda-latency.sh

# Resultados en:
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
