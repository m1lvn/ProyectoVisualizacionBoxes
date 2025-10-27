# 🔥 Chaos Engineering - Pruebas de Resiliencia en Arquitectura Serverless

> **Documentación completa del criterio: "Se realizaron pruebas de resiliencia simulando fallos en servicios. Se utilizaron herramientas como Gremlin o Chaos Monkey. Se documentaron resultados y se propusieron mejoras en la arquitectura."**

[![AWS](https://img.shields.io/badge/AWS-Fault_Injection-orange.svg)](https://aws.amazon.com/fis/)
[![Chaos](https://img.shields.io/badge/Chaos-Engineering-red.svg)](https://principlesofchaos.org/)
[![Serverless](https://img.shields.io/badge/Serverless-Lambda-blue.svg)](https://aws.amazon.com/lambda/)
[![Resilience](https://img.shields.io/badge/Resilience-Testing-green.svg)](https://aws.amazon.com/resilience/)

---

## 📋 **ANÁLISIS DEL CRITERIO DE CHAOS ENGINEERING**

### **🎯 Criterio a Evaluar:**
> Se realizaron **pruebas de resiliencia** simulando fallos en servicios. Se utilizaron herramientas como **Gremlin o Chaos Monkey**. Se documentaron resultados y se propusieron **mejoras en la arquitectura**.

---

## 🏗️ **ANÁLISIS DE ARQUITECTURA ACTUAL**

### **📊 Componentes del Sistema:**

```
┌─────────────────────────────────────────────────────────────────┐
│                    ARQUITECTURA SERVERLESS                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  🌐 API Gateway ────► 13 Lambda Functions ────► DynamoDB      │
│                          │                                      │
│                          ├─► Amazon Cognito (Auth)            │
│                          │                                      │
│                          └─► 4 SNS Topics ────► 3 Event       │
│                                                   Handlers      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### **🔍 Servicios AWS Identificados:**

| Servicio | Cantidad | Función | Punto de Fallo Potencial |
|----------|----------|---------|--------------------------|
| **Lambda Functions** | 13 | Lógica de negocio | Cold starts, timeouts, errores |
| **DynamoDB** | 1 tabla | Almacenamiento | Throttling, latencia |
| **API Gateway** | 1 | HTTP routing | Rate limiting, latencia |
| **Cognito User Pool** | 1 | Autenticación | Indisponibilidad |
| **SNS Topics** | 4 | Mensajería asíncrona | Fallos de delivery |
| **CloudWatch Logs** | N streams | Logging | Pérdida de logs |

### **📈 Lambda Functions Inventario:**

```yaml
# Endpoints REST (9 funciones)
1. login              → Autenticación Cognito
2. refresh            → Renovación de tokens
3. me                 → Info de usuario
4. getBoxes           → Consulta de boxes
5. getBoxDetail       → Detalle de box
6. getAgendas         → Consulta de agendas
7. createAgenda       → Creación de agendas
8. getPasillos        → Consulta de pasillos
9. *Config handlers   → Configuración (3 funciones)

# Event Handlers (3 funciones)
10. userEventsHandler      → Procesa USER_EVENTS
11. agendaEventsHandler    → Procesa AGENDA_EVENTS
12. notificationHandler    → Procesa NOTIFICATIONS

# Utilities (1 función)
13. setupTestUsers         → Inicialización
```

---

## ❌ **ESTADO ACTUAL: LO QUE NO CUMPLE**

### **1. ❌ Pruebas de Resiliencia NO Implementadas**

#### **Fallos NO Simulados:**
- ❌ No hay pruebas de fallos de Lambda (timeouts, crashes)
- ❌ No hay pruebas de throttling de DynamoDB
- ❌ No hay pruebas de indisponibilidad de Cognito
- ❌ No hay pruebas de pérdida de mensajes SNS
- ❌ No hay pruebas de latencia de red
- ❌ No hay pruebas de consumo de CPU/memoria

#### **Evidencia de Falta de Resiliencia:**
```javascript
// boxes.js - Sin retry logic
const [resultBoxes, resultPasillos] = await Promise.all([
  dynamodb.scan(paramsBoxes).promise(),  // ❌ No retry si falla
  dynamodb.scan(paramsPasillos).promise()  // ❌ No retry si falla
]);

// agendas.js - Sin circuit breaker
const result = await dynamodb.scan(params).promise();  // ❌ Sin protección
```

### **2. ❌ Herramientas de Chaos NO Utilizadas**

- ❌ **Gremlin**: No implementado
- ❌ **Chaos Monkey**: No implementado
- ❌ **AWS Fault Injection Simulator (FIS)**: No implementado
- ❌ **Chaos Mesh**: No aplica (no usa Kubernetes)
- ❌ **LitmusChaos**: No aplica (no usa Kubernetes)
- ❌ **Scripts bash maliciosos**: No implementados

### **3. ❌ Manejo de Errores Básico**

```javascript
// Patrón actual (INADECUADO para producción)
try {
  const result = await dynamodb.scan(params).promise();
  return { statusCode: 200, body: JSON.stringify(result) };
} catch (error) {
  console.error('Error:', error);  // ❌ Solo logging
  return { statusCode: 500, body: JSON.stringify({ error: error.message }) };
}
// ❌ Sin retry
// ❌ Sin circuit breaker
// ❌ Sin fallback
// ❌ Sin métricas de fallo
```

### **4. ❌ Sin Métricas de Resiliencia**

- ❌ No hay alarmas de CloudWatch para fallos
- ❌ No hay métricas de tasa de error
- ❌ No hay SLO/SLA definidos
- ❌ No hay dashboards de resiliencia
- ❌ No hay registro de incidentes

---

## 🛠️ **HERRAMIENTAS RECOMENDADAS PARA TU PROYECTO**

### **📊 Análisis de Compatibilidad:**

| Herramienta | Compatibilidad | Complejidad | Costo | Recomendación |
|-------------|----------------|-------------|-------|---------------|
| **AWS FIS** | ✅✅✅ Perfecta | Baja | Bajo | ⭐⭐⭐⭐⭐ **ALTAMENTE RECOMENDADO** |
| **Bash Scripts** | ✅✅✅ Perfecta | Muy Baja | Gratis | ⭐⭐⭐⭐⭐ **ALTAMENTE RECOMENDADO** |
| **Gremlin** | ✅✅ Buena | Media | Medio | ⭐⭐⭐ Recomendado |
| **Chaos Monkey** | ❌ No compatible | - | - | ❌ No aplica (para EC2) |
| **Simian Army** | ❌ No compatible | - | - | ❌ No aplica (para EC2) |
| **Chaos Mesh** | ❌ No compatible | - | - | ❌ Requiere Kubernetes |
| **LitmusChaos** | ❌ No compatible | - | - | ❌ Requiere Kubernetes |

---

## ⭐ **RECOMENDACIÓN #1: AWS FAULT INJECTION SIMULATOR (FIS)**

### **¿Por qué AWS FIS es lo mejor para tu proyecto?**

✅ **Nativo de AWS**: Integración perfecta con Lambda, DynamoDB, API Gateway  
✅ **Serverless-first**: Diseñado para arquitecturas sin servidor  
✅ **Sin instalación**: Managed service, solo configuración  
✅ **Escenarios pre-definidos**: Experimentos listos para usar  
✅ **Seguro**: Protección automática, rollback instantáneo  
✅ **AWS Academy compatible**: Funciona con credenciales temporales  

### **🔥 Experimentos de Chaos con AWS FIS:**

#### **1. Inyección de Latencia en DynamoDB**
```yaml
# Experimento: Agregar 2000ms de latencia a DynamoDB
experiment:
  description: "Probar resiliencia ante latencia de DynamoDB"
  targets:
    dynamoDBTable:
      resourceType: "aws:dynamodb:table"
      resourceTags:
        Name: "HospitalData"
  actions:
    injectLatency:
      actionId: "aws:dynamodb:inject-throughput-exceptions"
      parameters:
        duration: "PT5M"  # 5 minutos
        percentage: "50"   # 50% de requests
```

#### **2. Fallo de Lambda Functions**
```yaml
# Experimento: Simular errores en Lambda
experiment:
  description: "Simular fallos aleatorios en Lambda"
  targets:
    lambdaFunctions:
      resourceType: "aws:lambda:function"
      resourceTags:
        Environment: "dev"
  actions:
    injectError:
      actionId: "aws:lambda:inject-error"
      parameters:
        errorRate: "25"    # 25% de invocaciones fallan
        errorType: "Timeout"
        duration: "PT10M"  # 10 minutos
```

#### **3. Throttling de API Gateway**
```yaml
# Experimento: Simular throttling de API Gateway
experiment:
  description: "Probar comportamiento bajo throttling"
  targets:
    apiGateway:
      resourceType: "aws:apigateway:restapi"
  actions:
    throttleRequests:
      actionId: "aws:apigateway:throttle-requests"
      parameters:
        throttleRate: "10"  # 10 requests/segundo
        burstLimit: "5"
        duration: "PT3M"
```

### **📋 Implementación AWS FIS - Paso a Paso:**

```bash
# 1. Crear template de experimento
aws fis create-experiment-template \
  --cli-input-json file://chaos-experiments/lambda-error-injection.json

# 2. Ejecutar experimento
aws fis start-experiment \
  --experiment-template-id TEMPLATE_ID \
  --tags Key=Test,Value=ChaosEngineering

# 3. Monitorear resultados
aws fis get-experiment --id EXPERIMENT_ID

# 4. Analizar métricas en CloudWatch
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --start-time 2025-10-26T00:00:00Z \
  --end-time 2025-10-26T23:59:59Z \
  --period 300 \
  --statistics Sum
```

---

## ⭐ **RECOMENDACIÓN #2: BASH SCRIPTS + "MALICIA"**

### **¿Por qué Bash Scripts?**

✅ **Gratis**: Sin costo adicional  
✅ **Flexibles**: Control total sobre qué y cómo fallar  
✅ **Educativo**: Aprendes exactamente cómo funcionan los fallos  
✅ **Rápido**: Implementación inmediata  
✅ **Portables**: Funcionan en cualquier entorno  

### **🔥 Scripts de Chaos Propuestos:**

#### **1. Chaos Script: Eliminar DynamoDB Table**
```bash
#!/bin/bash
# chaos-scripts/delete-dynamodb-table.sh

echo "🔥 CHAOS EXPERIMENT: Eliminar tabla DynamoDB"
echo "⚠️  ADVERTENCIA: Esto eliminará datos reales"
read -p "¿Continuar? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
    echo "💀 Eliminando tabla HospitalData..."
    aws dynamodb delete-table --table-name HospitalData
    
    echo "⏱️  Esperando 30 segundos..."
    sleep 30
    
    echo "✅ Recreando tabla..."
    aws cloudformation deploy \
        --template-file ../serverless-api/serverless.yml \
        --stack-name hospital-boxes-api-dev
    
    echo "📊 Verificando recuperación..."
    aws dynamodb describe-table --table-name HospitalData
fi
```

#### **2. Chaos Script: Bombardeo de Requests (DoS Simulado)**
```bash
#!/bin/bash
# chaos-scripts/dos-attack-simulation.sh

API_ENDPOINT="https://44wvhl6j05.execute-api.us-east-1.amazonaws.com/api"
TOKEN="your-jwt-token"

echo "🔥 CHAOS EXPERIMENT: Bombardeo de requests"
echo "🎯 Objetivo: Probar rate limiting y throttling"

# Enviar 1000 requests en paralelo
for i in {1..1000}; do
    curl -X GET "$API_ENDPOINT/boxes" \
         -H "Authorization: Bearer $TOKEN" \
         -w "\nStatus: %{http_code} | Time: %{time_total}s\n" \
         &
done

wait

echo "✅ Experimento completado"
echo "📊 Revisar CloudWatch para métricas de throttling"
```

#### **3. Chaos Script: Inyección de Latencia Artificial**
```bash
#!/bin/bash
# chaos-scripts/inject-latency.sh

echo "🔥 CHAOS EXPERIMENT: Inyección de latencia en Lambda"
echo "📝 Método: Modificar código Lambda para agregar sleep"

# Crear versión con latencia
cat > /tmp/latency-injection.js << 'EOF'
module.exports.handler = async (event) => {
  // 🔥 CHAOS: Agregar 3 segundos de latencia
  await new Promise(resolve => setTimeout(resolve, 3000));
  
  // Código original continúa...
  const AWS = require('aws-sdk');
  const dynamodb = new AWS.DynamoDB.DocumentClient();
  // ...
};
EOF

echo "📦 Desplegando versión con latencia..."
cd ../serverless-api
serverless deploy function -f getBoxes

echo "⏱️  Ejecutando pruebas de performance..."
time curl "https://44wvhl6j05.execute-api.us-east-1.amazonaws.com/api/boxes"

echo "🔄 Revirtiendo cambios..."
git checkout src/handlers/boxes.js
serverless deploy function -f getBoxes
```

#### **4. Chaos Script: Fallo Aleatorio de Lambda**
```bash
#!/bin/bash
# chaos-scripts/random-lambda-failure.sh

echo "🔥 CHAOS EXPERIMENT: Fallos aleatorios en Lambda"
echo "🎲 Modificando código para fallar 30% de las veces"

# Inyectar código de fallo aleatorio
cat > /tmp/failure-injection.js << 'EOF'
module.exports.handler = async (event) => {
  // 🔥 CHAOS: Fallar 30% de las veces
  if (Math.random() < 0.3) {
    throw new Error('🔥 CHAOS: Fallo aleatorio simulado');
  }
  
  // Código original...
};
EOF

echo "📦 Desplegando versión con fallos..."
# Aplicar el parche y desplegar
# ...

echo "📊 Ejecutando 100 requests para observar fallos..."
for i in {1..100}; do
    curl -X GET "API_ENDPOINT" -w " | Status: %{http_code}\n"
done
```

#### **5. Chaos Script: Agotamiento de Memoria Lambda**
```bash
#!/bin/bash
# chaos-scripts/memory-exhaustion.sh

echo "🔥 CHAOS EXPERIMENT: Agotamiento de memoria en Lambda"

cat > /tmp/memory-bomb.js << 'EOF'
module.exports.handler = async (event) => {
  // 🔥 CHAOS: Consumir toda la memoria
  const bigArray = [];
  try {
    while (true) {
      bigArray.push(new Array(1000000).fill('x'));
    }
  } catch (error) {
    console.error('💀 Memory exhausted:', error);
    throw error;
  }
};
EOF

echo "📦 Desplegando Lambda con memory bomb..."
# Desplegar y monitorear CloudWatch
```

#### **6. Chaos Script: Desconexión de SNS Topics**
```bash
#!/bin/bash
# chaos-scripts/disconnect-sns.sh

echo "🔥 CHAOS EXPERIMENT: Desconectar SNS topics"
echo "🎯 Objetivo: Probar resiliencia ante fallos de mensajería"

# Eliminar suscripciones SNS
aws sns list-subscriptions-by-topic \
    --topic-arn "arn:aws:sns:us-east-1:891377117593:dev-hospital-user-events" \
    --query "Subscriptions[*].SubscriptionArn" \
    --output text | while read arn; do
        echo "💀 Eliminando suscripción: $arn"
        aws sns unsubscribe --subscription-arn "$arn"
    done

echo "⏱️  Esperando 60 segundos para observar efectos..."
sleep 60

echo "✅ Recreando suscripciones..."
cd ../serverless-api
serverless deploy
```

---

## ⭐ **RECOMENDACIÓN #3: GREMLIN (Opcional)**

### **¿Cuándo usar Gremlin?**

- ✅ Si necesitas UI gráfica para experimentos
- ✅ Si quieres experimentos programados/automatizados
- ✅ Si necesitas reportes profesionales
- ❌ Costo: $99/mes (versión básica)

### **🔧 Instalación Gremlin:**

```bash
# 1. Crear cuenta en gremlin.com
# 2. Instalar Gremlin CLI
curl https://rpm.gremlin.com/gremlin.repo -o /etc/yum.repos.d/gremlin.repo
yum install -y gremlin gremlind

# 3. Autenticar
gremlin init

# 4. Ejecutar ataque de latencia
gremlin attack-lambda latency \
    --function-name getBoxes \
    --milliseconds 3000 \
    --region us-east-1
```

---

## ✅ **IMPLEMENTACIÓN COMPLETA: PLAN DE ACCIÓN**

### **Fase 1: Preparación (1-2 horas)**

#### **1.1 Crear Estructura de Chaos Engineering**

```bash
# Crear directorio para experimentos
mkdir -p chaos-experiments/{aws-fis,bash-scripts,results}

# Estructura final:
# chaos-experiments/
# ├── aws-fis/
# │   ├── lambda-error-injection.json
# │   ├── dynamodb-latency.json
# │   └── api-throttling.json
# ├── bash-scripts/
# │   ├── dos-attack.sh
# │   ├── inject-latency.sh
# │   ├── random-failures.sh
# │   └── memory-exhaustion.sh
# └── results/
#     └── experiment-logs/
```

#### **1.2 Implementar Retry Logic en Lambda**

```javascript
// src/utils/resilience.js - NUEVO ARCHIVO
const AWS = require('aws-sdk');

/**
 * Retry con backoff exponencial
 */
async function retryWithBackoff(fn, maxRetries = 3, baseDelay = 100) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      
      const delay = baseDelay * Math.pow(2, i);
      console.log(`⚠️ Retry ${i + 1}/${maxRetries} after ${delay}ms`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}

/**
 * Circuit Breaker simple
 */
class CircuitBreaker {
  constructor(threshold = 5, timeout = 60000) {
    this.failureCount = 0;
    this.threshold = threshold;
    this.timeout = timeout;
    this.state = 'CLOSED'; // CLOSED, OPEN, HALF_OPEN
    this.nextAttempt = Date.now();
  }

  async execute(fn) {
    if (this.state === 'OPEN') {
      if (Date.now() < this.nextAttempt) {
        throw new Error('Circuit breaker is OPEN');
      }
      this.state = 'HALF_OPEN';
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  onSuccess() {
    this.failureCount = 0;
    this.state = 'CLOSED';
  }

  onFailure() {
    this.failureCount++;
    if (this.failureCount >= this.threshold) {
      this.state = 'OPEN';
      this.nextAttempt = Date.now() + this.timeout;
      console.error('🚨 Circuit breaker opened');
    }
  }
}

module.exports = { retryWithBackoff, CircuitBreaker };
```

#### **1.3 Actualizar Lambda con Resiliencia**

```javascript
// src/handlers/boxes.js - ACTUALIZADO
const { retryWithBackoff, CircuitBreaker } = require('../utils/resilience');

const circuitBreaker = new CircuitBreaker();

module.exports.getBoxes = async (event) => {
  try {
    // ✅ CON RETRY Y CIRCUIT BREAKER
    const [resultBoxes, resultPasillos] = await Promise.all([
      retryWithBackoff(() => circuitBreaker.execute(() => 
        dynamodb.scan(paramsBoxes).promise()
      )),
      retryWithBackoff(() => circuitBreaker.execute(() =>
        dynamodb.scan(paramsPasillos).promise()
      ))
    ]);

    return {
      statusCode: 200,
      body: JSON.stringify({
        success: true,
        boxes: filteredBoxes,
        pasillos: pasillos
      })
    };
  } catch (error) {
    console.error('❌ Error after retries:', error);
    
    // ✅ FALLBACK: Retornar datos en caché o vacíos
    return {
      statusCode: 200, // 200 en lugar de 500 para mejor UX
      body: JSON.stringify({
        success: false,
        message: 'Servicio temporalmente degradado',
        boxes: [], // Datos vacíos como fallback
        cached: true
      })
    };
  }
};
```

### **Fase 2: Experimentos de Chaos (4-6 horas)**

#### **Experimento 1: Fallo de DynamoDB**

```bash
#!/bin/bash
# chaos-experiments/bash-scripts/01-dynamodb-failure.sh

echo "═══════════════════════════════════════════════════"
echo "🔥 CHAOS EXPERIMENT 1: Fallo de DynamoDB"
echo "═══════════════════════════════════════════════════"

# 1. Estado inicial
echo "📊 Estado inicial:"
aws dynamodb describe-table --table-name HospitalData \
    --query "Table.TableStatus" --output text

# 2. Ejecutar requests normales (baseline)
echo -e "\n📈 Baseline (10 requests):"
for i in {1..10}; do
    RESPONSE=$(curl -s -w "\n%{http_code}" \
        "https://44wvhl6j05.execute-api.us-east-1.amazonaws.com/api/boxes" \
        -H "Authorization: Bearer $TOKEN")
    STATUS=$(echo "$RESPONSE" | tail -1)
    TIME=$(echo "$RESPONSE" | grep -o '"time":[0-9.]*' | cut -d: -f2)
    echo "Request $i: Status=$STATUS | Time=${TIME}ms"
done

# 3. Inyectar fallo: Reducir capacidad de DynamoDB
echo -e "\n💀 Inyectando fallo: Reducir WCU/RCU..."
aws dynamodb update-table \
    --table-name HospitalData \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1

# 4. Esperar aplicación del cambio
echo "⏱️  Esperando 30 segundos..."
sleep 30

# 5. Bombardear con requests
echo -e "\n🔥 Bombardeando con 50 requests..."
for i in {1..50}; do
    curl -s -w "Request $i: %{http_code} | %{time_total}s\n" \
        "https://44wvhl6j05.execute-api.us-east-1.amazonaws.com/api/boxes" \
        -H "Authorization: Bearer $TOKEN" &
done
wait

# 6. Revertir cambios
echo -e "\n✅ Revirtiendo cambios..."
aws dynamodb update-table \
    --table-name HospitalData \
    --billing-mode PAY_PER_REQUEST

echo "═══════════════════════════════════════════════════"
echo "✅ Experimento completado"
echo "📊 Revisar logs en CloudWatch"
echo "═══════════════════════════════════════════════════"
```

#### **Experimento 2: Latencia de Lambda**

```bash
#!/bin/bash
# chaos-experiments/bash-scripts/02-lambda-latency.sh

echo "═══════════════════════════════════════════════════"
echo "🔥 CHAOS EXPERIMENT 2: Latencia en Lambda"
echo "═══════════════════════════════════════════════════"

# 1. Backup del código original
echo "💾 Haciendo backup..."
cp serverless-api/src/handlers/boxes.js \
   serverless-api/src/handlers/boxes.js.backup

# 2. Inyectar latencia
echo "💉 Inyectando latencia de 5 segundos..."
sed -i '1a await new Promise(r => setTimeout(r, 5000)); // CHAOS' \
    serverless-api/src/handlers/boxes.js

# 3. Desplegar
echo "📦 Desplegando Lambda con latencia..."
cd serverless-api
serverless deploy function -f getBoxes --verbose

# 4. Ejecutar pruebas
echo -e "\n📊 Ejecutando pruebas (20 requests)..."
for i in {1..20}; do
    START=$(date +%s%N)
    STATUS=$(curl -s -w "%{http_code}" \
        "https://API/boxes" \
        -H "Authorization: Bearer $TOKEN" \
        -o /dev/null)
    END=$(date +%s%N)
    DURATION=$(( (END - START) / 1000000 ))
    
    echo "Request $i: Status=$STATUS | Duration=${DURATION}ms"
done

# 5. Restaurar código original
echo -e "\n✅ Restaurando código original..."
mv serverless-api/src/handlers/boxes.js.backup \
   serverless-api/src/handlers/boxes.js
serverless deploy function -f getBoxes

echo "═══════════════════════════════════════════════════"
echo "✅ Experimento completado"
echo "═══════════════════════════════════════════════════"
```

#### **Experimento 3: Fallo de SNS (Mensajería)**

```bash
#!/bin/bash
# chaos-experiments/bash-scripts/03-sns-failure.sh

echo "═══════════════════════════════════════════════════"
echo "🔥 CHAOS EXPERIMENT 3: Fallo de SNS Topics"
echo "═══════════════════════════════════════════════════"

# 1. Listar suscripciones actuales
echo "📋 Suscripciones SNS actuales:"
aws sns list-topics --query "Topics[?contains(TopicArn, 'hospital')]"

# 2. Eliminar suscripciones (simular fallo)
echo -e "\n💀 Eliminando suscripciones SNS..."
TOPIC_ARN="arn:aws:sns:us-east-1:891377117593:dev-hospital-user-events"
aws sns list-subscriptions-by-topic --topic-arn "$TOPIC_ARN" \
    --query "Subscriptions[*].SubscriptionArn" \
    --output text | while read sub_arn; do
        echo "  Eliminando: $sub_arn"
        aws sns unsubscribe --subscription-arn "$sub_arn"
    done

# 3. Trigger eventos que deberían ir a SNS
echo -e "\n🎯 Triggering eventos..."
for i in {1..10}; do
    curl -X POST "https://API/api/agendas" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "fecha": "2025-11-01",
            "horaInicio": "09:00",
            "profesional": "Dr. Test"
        }'
    echo "Evento $i enviado"
done

# 4. Verificar que no se procesaron
echo -e "\n📊 Verificando handlers de eventos..."
aws logs tail /aws/lambda/hospital-boxes-api-dev-userEventsHandler \
    --since 5m

# 5. Restaurar suscripciones
echo -e "\n✅ Restaurando suscripciones SNS..."
cd serverless-api
serverless deploy

echo "═══════════════════════════════════════════════════"
echo "✅ Experimento completado"
echo "Resultado esperado: Eventos perdidos, sistema debe poder recuperarse"
echo "═══════════════════════════════════════════════════"
```

### **Fase 3: AWS Fault Injection Simulator (2-3 horas)**

#### **Experimento FIS 1: Throttling de DynamoDB**

```json
// chaos-experiments/aws-fis/dynamodb-throttling.json
{
  "description": "Simular throttling en DynamoDB HospitalData",
  "targets": {
    "Tables": {
      "resourceType": "aws:dynamodb:table",
      "resourceArns": [
        "arn:aws:dynamodb:us-east-1:891377117593:table/HospitalData"
      ],
      "selectionMode": "ALL"
    }
  },
  "actions": {
    "ThrottleTable": {
      "actionId": "aws:dynamodb:inject-throughput-exceptions",
      "description": "Inyectar excepciones de throttling",
      "parameters": {
        "duration": "PT5M",
        "percentage": "80",
        "operations": "GetItem,Query,Scan"
      },
      "targets": {
        "Tables": "Tables"
      }
    }
  },
  "stopConditions": [
    {
      "source": "aws:cloudwatch:alarm",
      "value": "arn:aws:cloudwatch:us-east-1:891377117593:alarm:HighErrorRate"
    }
  ],
  "roleArn": "arn:aws:iam::891377117593:role/LabRole"
}
```

```bash
# Ejecutar experimento FIS
aws fis create-experiment-template \
    --cli-input-json file://chaos-experiments/aws-fis/dynamodb-throttling.json \
    --region us-east-1

# Iniciar experimento
aws fis start-experiment \
    --experiment-template-id TEMPLATE_ID \
    --tags Key=ChaosTest,Value=DynamoDB-Throttling

# Monitorear durante el experimento
watch -n 5 'aws cloudwatch get-metric-statistics \
    --namespace AWS/DynamoDB \
    --metric-name ThrottledRequests \
    --dimensions Name=TableName,Value=HospitalData \
    --start-time $(date -u -d "5 minutes ago" +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 60 \
    --statistics Sum'
```

#### **Experimento FIS 2: Errores en Lambda**

```json
// chaos-experiments/aws-fis/lambda-errors.json
{
  "description": "Inyectar errores aleatorios en Lambda functions",
  "targets": {
    "LambdaFunctions": {
      "resourceType": "aws:lambda:function",
      "resourceTags": {
        "Stage": "dev",
        "Project": "hospital-boxes"
      },
      "selectionMode": "PERCENT(50)"
    }
  },
  "actions": {
    "InjectErrors": {
      "actionId": "aws:lambda:invoke-error",
      "description": "Forzar errores en 25% de invocaciones",
      "parameters": {
        "duration": "PT10M",
        "errorRate": "25",
        "errorType": "InternalServerError"
      },
      "targets": {
        "Functions": "LambdaFunctions"
      }
    }
  },
  "roleArn": "arn:aws:iam::891377117593:role/LabRole"
}
```

### **Fase 4: Análisis y Documentación (2-3 horas)**

#### **Plantilla de Reporte de Experimento**

```markdown
# Reporte de Experimento de Chaos Engineering

## Información General
- **Experimento ID**: CE-001
- **Fecha**: 2025-10-26
- **Duración**: 10 minutos
- **Responsable**: [Tu nombre]

## Hipótesis
"El sistema debería mantener disponibilidad >95% incluso con throttling de DynamoDB"

## Configuración
- **Servicio afectado**: DynamoDB (HospitalData)
- **Tipo de fallo**: Throttling (80% de requests)
- **Herramienta**: AWS FIS
- **Duración**: 5 minutos

## Resultados

### Métricas Observadas
| Métrica | Baseline | Durante Chaos | Post-Chaos |
|---------|----------|---------------|------------|
| Tasa de éxito | 99.9% | 65.3% | 98.5% |
| Latencia p50 | 120ms | 850ms | 145ms |
| Latencia p99 | 450ms | 5200ms | 520ms |
| Throttled requests | 0 | 243 | 2 |

### Observaciones
- ✅ Sistema se mantuvo operacional
- ❌ Tasa de error alcanzó 34.7% (objetivo: <5%)
- ❌ Latencia p99 superó 5 segundos (inaceptable)
- ✅ Recuperación automática post-experimento

## Problemas Identificados
1. **Sin retry logic**: Requests fallaron inmediatamente
2. **Sin circuit breaker**: Se siguió intentando contra DynamoDB degradado
3. **Sin fallback**: No hay datos en caché para emergencias
4. **Sin alarmas**: No se detectó degradación automáticamente

## Mejoras Propuestas
1. [ ] Implementar retry con backoff exponencial
2. [ ] Agregar circuit breaker pattern
3. [ ] Implementar cache con ElastiCache
4. [ ] Crear alarmas CloudWatch para throttling
5. [ ] Agregar health checks y auto-scaling

## Código de Mejora Propuesto
\`\`\`javascript
// Implementar en próxima iteración
const { retryWithBackoff } = require('./resilience');
\`\`\`

## Conclusión
**ESTADO**: ❌ EXPERIMENTO FALLÓ - Resiliencia insuficiente

El sistema actual NO es resiliente ante fallos de DynamoDB. Se requiere
implementación urgente de patrones de resiliencia.

**Próximos pasos**:
1. Implementar mejoras propuestas
2. Re-ejecutar experimento
3. Validar mejoras
```

---

## 📊 **RESULTADOS ESPERADOS DE EXPERIMENTOS**

### **Tabla de Experimentos Propuestos:**

| # | Experimento | Herramienta | Duración | Resultado Esperado |
|---|-------------|-------------|----------|-------------------|
| 1 | Throttling DynamoDB | AWS FIS | 5 min | ❌ Fallos sin retry |
| 2 | Latencia Lambda (+5s) | Bash | 10 min | ❌ Timeouts, UX degradada |
| 3 | Errores Lambda (25%) | AWS FIS | 10 min | ❌ Errores 500 al usuario |
| 4 | SNS topics desconectados | Bash | 5 min | ⚠️ Pérdida de eventos |
| 5 | DoS (1000 req/s) | Bash | 2 min | ⚠️ Throttling API Gateway |
| 6 | Memory exhaustion | Bash | 5 min | ❌ Lambda crash |
| 7 | Cold start stress | Bash | 15 min | ⚠️ Latencia inicial alta |
| 8 | Cognito indisponible | Manual | 3 min | ❌ Sin autenticación |

### **Métricas a Monitorear:**

```yaml
Disponibilidad:
  - Success rate (objetivo: >99%)
  - Error rate (objetivo: <1%)
  
Performance:
  - Latencia p50 (objetivo: <200ms)
  - Latencia p99 (objetivo: <1000ms)
  - Cold start time (objetivo: <3s)
  
Resiliencia:
  - MTTR (Mean Time To Recovery)
  - Error recovery rate
  - Degraded mode capability
```

---

## 🎯 **MEJORAS DE ARQUITECTURA PROPUESTAS**

### **1. Implementar Retry Logic**

```javascript
// ✅ MEJORA: Retry automático con backoff
const AWS_SDK_RETRY_CONFIG = {
  maxRetries: 3,
  retryDelayOptions: {
    base: 100,
    customBackoff: (retryCount) => Math.pow(2, retryCount) * 100
  }
};

const dynamodb = new AWS.DynamoDB.DocumentClient({
  ...AWS_SDK_RETRY_CONFIG
});
```

### **2. Implementar Circuit Breaker**

```javascript
// ✅ MEJORA: Circuit breaker para proteger DynamoDB
const breaker = new CircuitBreaker(dynamodb.scan.bind(dynamodb), {
  timeout: 3000,
  errorThresholdPercentage: 50,
  resetTimeout: 30000
});
```

### **3. Implementar Cache (ElastiCache/DAX)**

```yaml
# ✅ MEJORA: DynamoDB Accelerator (DAX) para cache
DaxCluster:
  Type: AWS::DAX::Cluster
  Properties:
    ClusterName: hospital-data-cache
    NodeType: dax.t2.small
    ReplicationFactor: 3  # Alta disponibilidad
```

### **4. Implementar Health Checks**

```javascript
// ✅ MEJORA: Health check endpoint
module.exports.health = async () => {
  const checks = {
    dynamodb: await checkDynamoDB(),
    cognito: await checkCognito(),
    sns: await checkSNS()
  };
  
  const healthy = Object.values(checks).every(c => c.status === 'OK');
  
  return {
    statusCode: healthy ? 200 : 503,
    body: JSON.stringify({
      status: healthy ? 'healthy' : 'degraded',
      checks,
      timestamp: new Date().toISOString()
    })
  };
};
```

### **5. Implementar Alarmas CloudWatch**

```yaml
# ✅ MEJORA: Alarmas automáticas
HighErrorRateAlarm:
  Type: AWS::CloudWatch::Alarm
  Properties:
    AlarmName: hospital-boxes-high-error-rate
    MetricName: Errors
    Namespace: AWS/Lambda
    Statistic: Sum
    Period: 300
    EvaluationPeriods: 1
    Threshold: 10
    ComparisonOperator: GreaterThanThreshold
    AlarmActions:
      - !Ref SNSAlertTopic
```

### **6. Implementar Graceful Degradation**

```javascript
// ✅ MEJORA: Modo degradado con datos mínimos
try {
  return await getFullDataFromDynamoDB();
} catch (error) {
  console.warn('⚠️ Entering degraded mode');
  return {
    statusCode: 200,
    body: JSON.stringify({
      success: true,
      degraded: true,
      message: 'Sistema en modo limitado',
      data: getCachedOrMinimalData()
    })
  };
}
```

---

## 📋 **CHECKLIST DE IMPLEMENTACIÓN**

### **Fase de Preparación:**
- [ ] Crear directorio `chaos-experiments/`
- [ ] Crear archivo `resilience.js` con retry y circuit breaker
- [ ] Actualizar handlers de Lambda con resiliencia
- [ ] Configurar CloudWatch alarmas
- [ ] Crear health check endpoint
- [ ] Documentar baseline de métricas

### **Fase de Experimentos:**
- [ ] Ejecutar Experimento 1: Throttling DynamoDB
- [ ] Ejecutar Experimento 2: Latencia Lambda
- [ ] Ejecutar Experimento 3: Errores Lambda  
- [ ] Ejecutar Experimento 4: Fallo SNS
- [ ] Ejecutar Experimento 5: DoS simulado
- [ ] Ejecutar Experimento 6: Memory exhaustion
- [ ] Ejecutar Experimento 7: Cold start stress
- [ ] Ejecutar Experimento 8: Cognito failure

### **Fase de Análisis:**
- [ ] Documentar resultados de cada experimento
- [ ] Calcular métricas (MTTR, error rate, latencia)
- [ ] Identificar vulnerabilidades críticas
- [ ] Priorizar mejoras

### **Fase de Mejoras:**
- [ ] Implementar retry logic
- [ ] Implementar circuit breaker
- [ ] Agregar cache layer (DAX o ElastiCache)
- [ ] Configurar alarmas CloudWatch
- [ ] Implementar health checks
- [ ] Agregar graceful degradation

### **Fase de Validación:**
- [ ] Re-ejecutar todos los experimentos
- [ ] Validar mejoras en resiliencia
- [ ] Documentar mejoras en arquitectura
- [ ] Crear reporte final

---

## 🎯 **CONCLUSIÓN FINAL**

### **✅ LO QUE SE IMPLEMENTARÁ:**

| Componente | Status | Herramienta | Esfuerzo |
|------------|--------|-------------|----------|
| **Pruebas de Resiliencia** | ✅ A implementar | AWS FIS + Bash | 8-12 horas |
| **Herramientas de Chaos** | ✅ Seleccionadas | AWS FIS (principal) | 2-3 horas setup |
| **Documentación** | ✅ Completa | Markdown reports | 3-4 horas |
| **Mejoras Arquitectura** | ✅ Propuestas | Código + IaC | 10-15 horas |

### **📊 CUMPLIMIENTO DEL CRITERIO:**

> **ANTES** (Estado actual): ❌ 0% cumplido
> - No hay pruebas de resiliencia
> - No hay herramientas de chaos
> - No hay documentación de fallos
> 
> **DESPUÉS** (Con implementación): ✅ 100% cumplido
> - ✅ 8 experimentos de resiliencia documentados
> - ✅ AWS FIS + Bash scripts implementados
> - ✅ Resultados documentados con métricas
> - ✅ 6 mejoras de arquitectura propuestas e implementadas

### **🚀 PRÓXIMOS PASOS INMEDIATOS:**

1. **HOY (2-3 horas)**:
   - Crear estructura `chaos-experiments/`
   - Implementar `resilience.js`
   - Ejecutar primer experimento (bash DoS)

2. **ESTA SEMANA (8-12 horas)**:
   - Ejecutar todos los experimentos bash
   - Configurar AWS FIS templates
   - Documentar resultados

3. **PRÓXIMA SEMANA (10-15 horas)**:
   - Implementar mejoras de resiliencia
   - Re-ejecutar experimentos
   - Crear reporte final completo

---

**🎯 CRITERIO DE CHAOS ENGINEERING: LISTO PARA IMPLEMENTACIÓN COMPLETA ✅**

*Documento creado: Octubre 2025*  
*Versión: 1.0 - Análisis y Plan de Implementación Completo*  
*Autor: Equipo de Desarrollo - Proyecto Hospital Boxes*
