# 🎮 Gremlin Free Tier - Guía de Setup

## 📋 Resumen

Gremlin Free Tier proporciona:
- ✅ 5 ataques/mes gratis
- ✅ 1 usuario
- ✅ Integración con AWS Lambda
- ✅ UI visual profesional
- ✅ Reportes automáticos

**Sin necesidad de tarjeta de crédito para empezar**

---

## 🚀 Setup Paso a Paso

### **Paso 1: Registro en Gremlin (5 minutos)**

1. Ir a: https://app.gremlin.com/signup
2. Seleccionar **"Free"** plan
3. Completar registro con email
4. Verificar email
5. Completar perfil básico

**Credenciales creadas automáticamente**

---

### **Paso 2: Crear API Key**

1. En Gremlin Dashboard, ir a: **Settings** → **Team Settings**
2. Click en **API Keys** tab
3. Click **"Create New"**
4. Nombre: `hospital-boxes-chaos`
5. **Guardar el Key y Secret** (solo se muestra una vez)

```bash
# Guardar en variables de entorno
export GREMLIN_TEAM_ID="your-team-id"
export GREMLIN_API_KEY="your-api-key"
export GREMLIN_API_SECRET="your-api-secret"
```

---

### **Paso 3: Configurar permisos AWS IAM**

Gremlin necesita permisos para invocar tus funciones Lambda.

#### **Opción A: Usando AWS Console**

1. Ir a: AWS Console → IAM → Roles
2. Create Role → **AWS Service** → **Lambda**
3. Attachar policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction",
        "lambda:GetFunction",
        "lambda:ListFunctions",
        "lambda:GetFunctionConfiguration"
      ],
      "Resource": "arn:aws:lambda:us-east-1:*:function:hospital-boxes-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

4. Nombre del role: `GremlinChaosRole`
5. Copiar ARN del role

#### **Opción B: Usando AWS CLI**

```bash
# Crear policy
aws iam create-policy \
  --policy-name GremlinChaosPolicy \
  --policy-document file://gremlin-iam-policy.json

# Crear role
aws iam create-role \
  --role-name GremlinChaosRole \
  --assume-role-policy-document file://gremlin-trust-policy.json

# Attachar policy al role
aws iam attach-role-policy \
  --role-name GremlinChaosRole \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/GremlinChaosPolicy
```

---

### **Paso 4: Conectar Gremlin con AWS**

1. En Gremlin Dashboard: **Settings** → **Integrations**
2. Click **"Add Integration"** → **AWS**
3. Seleccionar **"Cross-Account Role"**
4. Ingresar:
   - **External ID:** (proporcionado por Gremlin)
   - **Role ARN:** `arn:aws:iam::YOUR_ACCOUNT:role/GremlinChaosRole`
5. Click **"Verify"**
6. Si es exitoso, click **"Save"**

---

### **Paso 5: Verificar Conexión**

```bash
# Usando Gremlin CLI (opcional)
# Instalar CLI
curl https://gremlin-cli.s3.amazonaws.com/gremlin-install.sh | bash

# Inicializar
gremlin init

# Listar funciones Lambda disponibles
gremlin targets list --type lambda
```

---

## 🎯 Experimentos Planificados

### **Experimento #6: CPU Stress Test**

**Objetivo:** Validar performance bajo alta utilización de CPU

**Configuración en Gremlin UI:**

1. **Attacks** → **New Attack**
2. **Target:**
   - Type: Lambda Function
   - Function: `hospital-boxes-api-dev-getBoxes`
3. **Attack Type:** CPU
4. **Parameters:**
   - CPU Percentage: `90%`
   - Duration: `5 minutes`
5. **Run Attack**

**Usando CLI:**

```bash
gremlin attack-lambda cpu \
  --function-name hospital-boxes-api-dev-getBoxes \
  --percent 90 \
  --length 300 \
  --region us-east-1 \
  --team-id $GREMLIN_TEAM_ID
```

**Métricas a observar:**
- Execution time
- Throttling events
- Cold start impact
- Error rate

---

### **Experimento #7: Memory Exhaustion**

**Objetivo:** Probar límites de memoria Lambda

**Configuración en Gremlin UI:**

1. **Attacks** → **New Attack**
2. **Target:**
   - Type: Lambda Function
   - Function: `hospital-boxes-api-dev-createAgenda`
3. **Attack Type:** Memory
4. **Parameters:**
   - Memory Percentage: `95%`
   - Duration: `5 minutes`
5. **Run Attack**

**Usando CLI:**

```bash
gremlin attack-lambda memory \
  --function-name hospital-boxes-api-dev-createAgenda \
  --percent 95 \
  --length 300 \
  --region us-east-1 \
  --team-id $GREMLIN_TEAM_ID
```

**Métricas a observar:**
- Memory usage
- OOM (Out of Memory) errors
- Crash recovery time
- Impact on concurrent invocations

---

## 📊 Tipos de Ataques Disponibles

| Tipo | Descripción | Uso en este proyecto |
|------|-------------|---------------------|
| **CPU** | Consumir CPU | ✅ Experimento #6 |
| **Memory** | Agotar memoria | ✅ Experimento #7 |
| **Latency** | Agregar delay | ⚠️ Alternativa a Bash |
| **DNS** | Corromper DNS | 🔄 Futuro |
| **Packet Loss** | Perder paquetes | 🔄 Futuro |

---

## 📈 Dashboard y Reportes

### **Visualizar Resultados**

1. **Gremlin UI** → **Attacks** → Seleccionar ataque
2. Ver:
   - Timeline del ataque
   - Métricas en tiempo real
   - Logs de ejecución
   - Screenshots automáticos

### **Exportar Reportes**

1. Click en ataque completado
2. **Export** → **PDF Report**
3. Incluye:
   - Configuración del experimento
   - Gráficos de métricas
   - Timeline de eventos
   - Conclusiones automáticas

---

## 🔧 Troubleshooting

### **Error: "Unable to invoke Lambda function"**

**Solución:**
1. Verificar permisos IAM
2. Confirmar que la integración AWS está activa
3. Validar que el role tiene permisos correctos

```bash
# Verificar role
aws iam get-role --role-name GremlinChaosRole

# Verificar policies attachadas
aws iam list-attached-role-policies --role-name GremlinChaosRole
```

### **Error: "Quota exceeded"**

**Causa:** Has usado los 5 ataques del mes

**Solución:**
1. Esperar al próximo mes
2. O usar Bash scripts para experimentos adicionales

### **Lambda no responde durante ataque**

**Esperado:** Esto es parte del experimento

**Acciones:**
1. Monitorear CloudWatch Logs
2. Verificar que el ataque tiene duración limitada
3. Confirmar que Lambda se recupera después

---

## 💰 Límites del Free Tier

```
Límites mensuales:
  - Ataques: 5
  - Usuarios: 1
  - Targets: Ilimitados
  - Duración por ataque: 60 minutos max
  - Support: Community (email)

Renovación: 1ro de cada mes
```

---

## 🎯 Plan de Uso Recomendado

### **Mes 1 (Setup y Baseline):**

```
Ataque 1: CPU stress en getBoxes (5 min)
  └─ Establecer baseline de performance

Ataque 2: Memory exhaustion en createAgenda (5 min)
  └─ Identificar límites de memoria

Ataque 3: CPU stress en getAgendas (3 min)
  └─ Probar múltiples endpoints
```

### **Mes 2 (Validación de mejoras):**

```
Ataque 4: CPU stress repetido (5 min)
  └─ Validar mejoras implementadas

Ataque 5: Memory + CPU combinado (5 min)
  └─ Test de estrés final
```

**Total: 5 ataques = 100% del free tier utilizado**

---

## 📚 Recursos Adicionales

- **Documentación:** https://www.gremlin.com/docs/
- **Lambda Chaos:** https://www.gremlin.com/chaos-engineering/aws-lambda/
- **Best Practices:** https://www.gremlin.com/community/tutorials/
- **Support:** support@gremlin.com

---

## ✅ Checklist de Setup

- [ ] Cuenta Gremlin creada
- [ ] API Key generado y guardado
- [ ] Role IAM creado con permisos
- [ ] Integración AWS configurada
- [ ] Integración verificada
- [ ] Targets (Lambdas) visibles
- [ ] Primer ataque de prueba ejecutado

**Una vez completado, estás listo para ejecutar los experimentos #6 y #7**

---

**Última actualización:** Octubre 2025  
**Versión:** 1.0  
**Estado:** 🟢 Listo para usar
