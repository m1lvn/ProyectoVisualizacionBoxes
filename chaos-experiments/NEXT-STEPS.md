# 🚀 Guía de Ejecución - Paso a Paso

## ✅ Tu Estado Actual

Basado en la salida de tu ejecución:
```
✅ AWS CLI configurado
✅ JWT Token disponible
✅ Recursos verificados (DynamoDB, Lambdas)
✅ Templates FIS actualizados
⚠️  Templates FIS NO creados en AWS aún
```

---

## 📋 Próximos Pasos

### **Opción 1: Automático (RECOMENDADO)** ⭐

```bash
# El script ahora crea los templates automáticamente
# Solo actualiza el script y vuelve a ejecutar:

git pull  # Obtener la última versión
./run-all-chaos-experiments.sh
```

**Resultado esperado:**
```
[✓] Verificando FIS Experiment Templates...
    ⚠️  No se encontraron templates FIS
    📝 Creando templates automáticamente...
       → Creando template: dynamodb-throttling...
       ✅ Template creado: EXT1234567890abc
       → Creando template: lambda-error-injection...
       ✅ Template creado: EXT0987654321xyz
    ✅ Templates FIS creados: 2

════════════════════════════════════════════════════════════════
   EXPERIMENTO 1/5: DoS Attack Simulation
════════════════════════════════════════════════════════════════
...
```

---

### **Opción 2: Manual (Si quieres hacerlo paso a paso)**

#### Paso 1: Crear Templates FIS

```bash
# Template 1: DynamoDB Throttling
aws fis create-experiment-template \
  --cli-input-json file://aws-fis/dynamodb-throttling.json \
  --region us-east-1

# Template 2: Lambda Error Injection  
aws fis create-experiment-template \
  --cli-input-json file://aws-fis/lambda-error-injection.json \
  --region us-east-1
```

**Output esperado:**
```json
{
    "experimentTemplate": {
        "id": "EXT1234567890abc",
        "description": "DynamoDB Throttling",
        "targets": {...},
        "actions": {...}
    }
}
```

#### Paso 2: Verificar Templates Creados

```bash
# Listar templates
aws fis list-experiment-templates --region us-east-1

# Debe mostrar 2 templates
```

#### Paso 3: Ejecutar Suite Completa

```bash
./run-all-chaos-experiments.sh
```

---

## 🎯 Qué Esperar

La ejecución completa tarda aproximadamente **40 minutos**:

```
⏱️  Timeline de Ejecución:

00:00 - 05:00  → Experimento 1: DoS Attack (5 min)
05:00 - 06:00  → Delay entre experimentos (1 min)
06:00 - 21:00  → Experimento 2: Lambda Latency (15 min)
21:00 - 22:00  → Delay entre experimentos (1 min)
22:00 - 32:00  → Experimento 3: SNS Failure (10 min)
32:00 - 33:00  → Delay entre experimentos (1 min)
33:00 - 38:00  → Experimento 4: DynamoDB Throttling (5 min, FIS)
38:00 - 39:00  → Delay entre experimentos (1 min)
39:00 - 44:00  → Experimento 5: Lambda Error Injection (5 min, FIS)
44:00 - 45:00  → Generación de reportes (1 min)

Total: ~45 minutos
```

---

## 📊 Monitoreo Durante la Ejecución

### En la Terminal

Verás salida en tiempo real:
```
════════════════════════════════════════════════════════════════
   EXPERIMENTO 1/5: DoS Attack Simulation
════════════════════════════════════════════════════════════════

Tipo: Bash Script
Duración: 5 minutos
Criticidad: Critical
Descripción: Simulación de ataque DoS...

⏳ Ejecutando experimento... (esto puede tardar varios minutos)
✅ Experimento completado exitosamente
```

### En AWS CloudWatch (Opcional)

1. Abre [CloudWatch Console](https://console.aws.amazon.com/cloudwatch)
2. Ve a **Metrics** → **Custom Namespaces** → `ChaosEngineering/HospitalBoxes`
3. Verás métricas en tiempo real:
   - Lambda.Requests
   - Lambda.Errors
   - DynamoDB.Throttles
   - CircuitBreaker.StateChange

### En AWS FIS (Para experimentos FIS)

1. Abre [FIS Console](https://console.aws.amazon.com/fis)
2. Ve a **Experiments**
3. Verás el estado: `initiating` → `running` → `completed`

---

## 📄 Resultados

Al finalizar, encontrarás:

```
chaos-experiments/
└── results/
    └── suite-20251107-004400/
        ├── 01-dos-attack.log
        ├── 02-lambda-latency.log
        ├── 03-sns-failure.log
        ├── 04-dynamodb-throttling.log
        ├── 05-lambda-error-injection.log
        ├── SUITE-REPORT.json
        └── SUITE-REPORT.md
```

### Reporte Consolidado

```bash
# Ver reporte en terminal
cat results/suite-20251107-004400/SUITE-REPORT.md

# Ver JSON para procesamiento
cat results/suite-20251107-004400/SUITE-REPORT.json
```

**Ejemplo de reporte:**
```markdown
# 🔥 Chaos Engineering - Suite Completa
## Resumen Ejecutivo

📊 Estadísticas:
- Total experimentos: 5
- Exitosos: 5 ✅
- Fallidos: 0 ❌
- Tasa de éxito: 100%
- Duración total: 45 minutos

## Experimentos Ejecutados

### 1. DoS Attack Simulation ✅
- Duración: 5:23 min
- Estado: Success
- Hallazgos: Sistema resistió 500 requests simultáneos...
```

---

## ⚠️ Solución de Problemas

### Error: "No permission to create experiment template"

**Causa:** Usuario/Role sin permisos FIS.

**Solución:**
```bash
# Verificar identidad actual
aws sts get-caller-identity

# Si estás usando LabRole, debe tener permisos FIS
# Contacta al administrador para agregar políticas FIS
```

### Error: "Template already exists"

**Causa:** Templates ya creados anteriormente.

**Solución:**
```bash
# Listar templates existentes
aws fis list-experiment-templates

# El script detectará automáticamente que ya existen
# y continuará con la ejecución
```

### Error: "JWT Token expired"

**Causa:** El JWT expira después de ~1 hora.

**Solución:**
```bash
# Re-obtener JWT
./setup-jwt-secrets-manager.sh

# Luego continuar con los experimentos
./run-all-chaos-experiments.sh
```

---

## 🎉 Siguientes Pasos Después de la Ejecución

1. **Analizar Reportes**
   ```bash
   cat results/suite-*/SUITE-REPORT.md
   ```

2. **Revisar Métricas en CloudWatch**
   - Ve a CloudWatch Console
   - Namespace: `ChaosEngineering/HospitalBoxes`

3. **Documentar Hallazgos**
   - ¿El sistema se degradó gracefully?
   - ¿Los circuit breakers funcionaron?
   - ¿Se registraron logs correctamente?

4. **Implementar Mejoras** (si es necesario)
   - Ajustar timeouts
   - Configurar auto-scaling
   - Mejorar circuit breaker thresholds

5. **Re-ejecutar Experimentos**
   ```bash
   # Después de implementar mejoras
   ./run-all-chaos-experiments.sh
   
   # Comparar resultados con ejecución anterior
   ```

---

## 📞 Ayuda

Si encuentras problemas:

1. **Verificar logs detallados:**
   ```bash
   tail -f results/suite-*/01-dos-attack.log
   ```

2. **Modo dry-run (prueba sin ejecutar):**
   ```bash
   ./run-all-chaos-experiments.sh --dry-run
   ```

3. **Saltar experimentos FIS (solo Bash):**
   ```bash
   ./run-all-chaos-experiments.sh --skip-fis
   ```

---

**¿Listo para ejecutar?** 🚀

```bash
./run-all-chaos-experiments.sh
```
