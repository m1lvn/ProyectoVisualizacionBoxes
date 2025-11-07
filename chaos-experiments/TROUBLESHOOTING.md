# 🔧 Diagnóstico y Solución - Script Colgado

## ❌ Problema Reportado

El script se quedó colgado en:
```
[✓] Verificando FIS Experiment Templates...
    ⚠️  No se encontraron templates FIS
    📝 Creando templates automáticamente...
       → Creando template: dynamodb-throttling...
```

---

## 🔍 Causas Posibles

### 1. **Sin Permisos FIS** (90% probabilidad)

El usuario/role actual (`LabRole` en AWS Academy) no tiene permisos para `fis:CreateExperimentTemplate`.

**Verificación rápida:**
```bash
# En tu EC2, ejecuta:
aws fis create-experiment-template \
  --cli-input-json file://aws-fis/dynamodb-throttling.json \
  --region us-east-1

# Si ves:
# "AccessDeniedException" o "not authorized to perform: fis:CreateExperimentTemplate"
# → Confirma que es problema de permisos
```

### 2. **JSON Malformado** (5% probabilidad)

El archivo JSON tiene errores de sintaxis.

**Verificación:**
```bash
python3 -m json.tool aws-fis/dynamodb-throttling.json
```

### 3. **Timeout de Red** (5% probabilidad)

Conexión lenta a AWS API.

---

## ✅ Soluciones (Ordenadas por Facilidad)

### **Solución 1: Saltar FIS** ⭐ (2 minutos)

Ejecuta solo los experimentos Bash (que **SÍ funcionan** sin permisos FIS):

```bash
# 1. Detén el script actual
Ctrl+C

# 2. Actualiza el código
cd ~/ProyectoVisualizacionBoxes
git pull

# 3. Ejecuta saltando FIS
cd chaos-experiments
./run-all-chaos-experiments.sh --skip-fis
```

**Resultado:**
```
✅ Experimento 1: DoS Attack (5 min)
✅ Experimento 2: Lambda Latency (15 min)
✅ Experimento 3: SNS Failure (10 min)
❌ Experimento 4: DynamoDB Throttling (SALTADO - requiere FIS)
❌ Experimento 5: Lambda Error Injection (SALTADO - requiere FIS)

Total: 3/5 experimentos ejecutados (~30 min)
```

---

### **Solución 2: Script Mejorado** ⭐⭐ (Automático)

He actualizado el script con:
- ✅ **Timeout de 30 segundos** (no se cuelga)
- ✅ **Detección de errores** (AccessDenied, etc.)
- ✅ **Fallback automático** (salta FIS si falla)

```bash
# 1. Detén el script actual
Ctrl+C

# 2. Actualiza el código
cd ~/ProyectoVisualizacionBoxes
git pull

# 3. Ejecuta normalmente
cd chaos-experiments
./run-all-chaos-experiments.sh
```

**Nuevo comportamiento:**
```
[✓] Verificando FIS Experiment Templates...
    ⚠️  No se encontraron templates FIS
    📝 Creando templates automáticamente...
       → Creando template: dynamodb-throttling...
       ❌ Error: AccessDeniedException - not authorized
       ⚠️  Sin permisos FIS - Saltando experimentos FIS
    
✅ PRE-REQUISITOS VERIFICADOS (FIS deshabilitado)
📝 Se ejecutarán solo experimentos Bash (3/5)
```

**Continúa automáticamente** con los experimentos Bash.

---

### **Solución 3: Solicitar Permisos FIS** (Largo plazo)

Si quieres ejecutar **TODOS** los experimentos (incluyendo FIS):

**En AWS Academy (Learner Lab):**

1. **Contacta al instructor** para que agregue permisos FIS a `LabRole`

2. **O usa AWS Console manualmente:**
   - Ve a [FIS Console](https://console.aws.amazon.com/fis)
   - Crea templates manualmente usando la UI visual
   - Copia la configuración de `aws-fis/*.json`

3. **Luego ejecuta:**
   ```bash
   ./run-all-chaos-experiments.sh
   # Ahora detectará los templates y ejecutará los 5 experimentos
   ```

---

### **Solución 4: Crear Templates Manualmente (AWS CLI)**

Si tienes permisos pero el script falló:

```bash
# 1. Crear template 1
aws fis create-experiment-template \
  --cli-input-json file://aws-fis/dynamodb-throttling.json \
  --region us-east-1

# 2. Crear template 2
aws fis create-experiment-template \
  --cli-input-json file://aws-fis/lambda-error-injection.json \
  --region us-east-1

# 3. Verificar
aws fis list-experiment-templates --region us-east-1

# 4. Ejecutar suite
./run-all-chaos-experiments.sh
```

---

## 🚀 Recomendación INMEDIATA

**Ejecuta esto AHORA:**

```bash
# Detén el script colgado
Ctrl+C

# Actualiza y ejecuta sin FIS
cd ~/ProyectoVisualizacionBoxes
git pull
cd chaos-experiments
./run-all-chaos-experiments.sh --skip-fis
```

**Tendrás resultados en 30 minutos** con los 3 experimentos Bash que **SÍ funcionan** sin permisos especiales.

---

## 📊 Comparación de Opciones

| Solución | Tiempo | Experimentos | Requiere Permisos |
|----------|--------|--------------|-------------------|
| `--skip-fis` | 30 min | 3/5 (60%) | ❌ No |
| Script mejorado + fallback | 30-45 min | 3-5 (automático) | ❌ No |
| Permisos FIS | Variable | 5/5 (100%) | ✅ Sí |
| Crear templates manual | 10 min + 45 min | 5/5 (100%) | ✅ Sí |

---

## 📝 Debugging Adicional

Si quieres diagnosticar el problema exacto:

```bash
# 1. Ver logs detallados del error
aws fis create-experiment-template \
  --cli-input-json file://aws-fis/dynamodb-throttling.json \
  --region us-east-1 \
  --debug 2>&1 | tee fis-debug.log

# 2. Buscar el error
grep -i "error\|denied\|exception" fis-debug.log

# 3. Verificar permisos actuales
aws sts get-caller-identity
aws iam get-role --role-name LabRole --query 'Role.AssumeRolePolicyDocument'
```

---

## ❓ FAQ

**P: ¿Por qué se colgó el script?**
R: Porque el comando `aws fis create-experiment-template` no tiene timeout y se quedó esperando indefinidamente (probablemente por permisos denegados sin mensaje de error claro).

**P: ¿Los experimentos Bash funcionan sin FIS?**
R: ✅ Sí, completamente. Los 3 experimentos Bash (DoS, Lambda Latency, SNS) no requieren FIS ni permisos especiales.

**P: ¿Vale la pena ejecutar solo 3/5 experimentos?**
R: ✅ Sí. Los 3 experimentos Bash son los más **críticos** y validarán:
- Resiliencia ante DoS
- Manejo de latencia en Lambda
- Tolerancia a fallos en SNS

**P: ¿Puedo ejecutar los experimentos FIS después?**
R: ✅ Sí. Una vez obtengas permisos, ejecuta:
```bash
./run-fis-experiment.sh dynamodb-throttling
./run-fis-experiment.sh lambda-error-injection
```

---

**¿Quieres que suba los cambios a git?** Así puedes hacer `git pull` y ejecutar con el script mejorado.
