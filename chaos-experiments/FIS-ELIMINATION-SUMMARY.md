# 🔄 AWS FIS Elimination - Summary

**Fecha:** $(date)  
**Motivo:** AWS Academy Learner Lab no tiene permisos `fis:CreateExperimentTemplate`  
**Solución:** Reemplazo con simulaciones Bash puras

---

## ✅ Cambios Completados

### 1. Scripts Bash Creados

#### `bash-scripts/04-dynamodb-throttling-sim.sh` (320 líneas)
**Reemplaza:** `aws-fis/dynamodb-throttling.json`

**Funcionamiento:**
- Ejecuta 50 requests concurrentes cada 0.1s durante 5 minutos
- Fuerza throttling en DynamoDB mediante carga masiva
- Monitorea errores 429 (throttling)
- Valida circuit breaker y retry logic

**Métricas:**
- Total requests enviados
- Success rate (200 OK)
- Throttle rate (429 errors)
- Timeout errors
- Comparación baseline vs chaos vs recovery

**Outputs:**
```
results/experiment-04-dynamodb/
├── requests.csv          # Timestamp, Status, Latencia
├── status.log            # Logs detallados por fase
└── report.md             # Reporte final con métricas
```

#### `bash-scripts/05-lambda-errors-sim.sh` (395 líneas)
**Reemplaza:** `aws-fis/lambda-error-injection.json`

**Funcionamiento:**
- Inyecta 30% de requests inválidos durante 5 minutos
- 5 tipos de errores simulados:
  1. JSON malformado (`{invalid json}`)
  2. POST sin datos requeridos (`{}`)
  3. IDs inexistentes (`/boxes/99999999`)
  4. Métodos HTTP incorrectos (DELETE en GET endpoint)
  5. Datos inválidos (`{"fecha": "invalid-date"}`)
- Valida error handling y graceful degradation

**Métricas:**
- Success rate (200 OK)
- Client errors (400, 404)
- Server errors (500, 502)
- Service unavailable (503)
- Circuit breaker activations

**Outputs:**
```
results/experiment-05-lambda/
├── requests.csv          # Timestamp, Status, ErrorType
├── status.log            # Logs por fase
└── report.md             # Análisis de errores
```

---

### 2. Documentación Actualizada

#### `README.md`
**Antes:** 
- "Bash Scripts: 3 | AWS FIS: 2"
- 110 líneas de instrucciones FIS (IAM roles, templates, ejecución)

**Después:**
- "Bash Scripts: 5 | Total: 5 experimentos"
- Sección AWS FIS reemplazada con:
  - Instrucciones de uso de simulaciones Bash
  - Nota sobre limitaciones de AWS Academy
  - Templates FIS guardados en `aws-fis/` como referencia

#### `Experiments.md`
**Antes:**
- AWS FIS como herramienta principal para experimentos 4-5
- Instrucciones detalladas de creación de templates
- Comandos `aws fis start-experiment`

**Después:**
- Bash Scripts como herramienta única para todos los experimentos
- Sección "Bash Simulations" con instrucciones de uso
- AWS FIS Templates movidos a sección "Referencia"
- Nota sobre permisos requeridos

#### `run-all-chaos-experiments.sh`
**Antes:**
- 200 líneas de lógica FIS (verificación, templates, ejecución)
- Variable `SKIP_FIS` para saltar experimentos FIS
- Experimentos 4-5 definidos como "AWS FIS"

**Después:**
- Lógica FIS eliminada completamente (reducción de ~200 líneas)
- Verificación simple: ¿existen los scripts bash?
- Experimentos 4-5 definidos como "Bash simulations"
- Array de experimentos simplificado (eliminado campo `requires_fis`)

---

### 3. Archivos Deprecados (Mantenidos como Referencia)

Estos archivos NO se eliminaron pero ya no se usan:

- `aws-fis/dynamodb-throttling.json` - Template FIS DynamoDB
- `aws-fis/lambda-error-injection.json` - Template FIS Lambda
- `verify-fis-setup.sh` - Script de verificación FIS
- `run-fis-experiment.sh` - Ejecutor de experimentos FIS
- `diagnose-fis.sh` - Herramienta de diagnóstico FIS

**Razón:** Documentación para uso futuro en cuentas AWS con permisos completos.

---

## 📊 Comparación: FIS vs Bash Simulations

| Aspecto | AWS FIS | Bash Simulations |
|---------|---------|------------------|
| **Permisos requeridos** | `fis:*` (no disponible en Academy) | Solo `lambda:InvokeFunction` ✅ |
| **Costo** | $0.10/hora (Free tier 5 horas/mes) | $0 (requests Lambda existentes) |
| **Complejidad setup** | Templates JSON + IAM roles | `chmod +x script.sh` |
| **Flexibilidad** | Limitado a acciones FIS | Control total en Bash |
| **Métricas** | CloudWatch integrado | CSV + logs + markdown reports |
| **Aprendizaje** | Específico AWS FIS | Scripting universal |

---

## 🎯 Estado Final

### Todos los experimentos ahora son Bash:

1. ✅ **DoS Attack** - `01-dos-attack.ps1` (1000 requests, throttling)
2. ✅ **Lambda Latency** - `02-lambda-latency.sh` (5s delay injection)
3. ✅ **SNS Failure** - `03-sns-failure.sh` (topic disable)
4. ✅ **DynamoDB Throttling** - `04-dynamodb-throttling-sim.sh` (50 concurrent)
5. ✅ **Lambda Errors** - `05-lambda-errors-sim.sh` (30% error injection)

### Costos:
- **Antes:** $0-0.50 (depende de uso FIS)
- **Ahora:** $0 (solo Lambda requests existentes)

### Duración total:
- **Antes:** ~40 min
- **Ahora:** ~40 min (sin cambios)

---

## 🚀 Próximos Pasos

### 1. Test de Ejecución Individual

```bash
cd chaos-experiments/bash-scripts

# Test experimento 4
chmod +x 04-dynamodb-throttling-sim.sh
./04-dynamodb-throttling-sim.sh

# Test experimento 5
chmod +x 05-lambda-errors-sim.sh
./05-lambda-errors-sim.sh
```

### 2. Test de Suite Completa

```bash
cd chaos-experiments
chmod +x run-all-chaos-experiments.sh
./run-all-chaos-experiments.sh
```

### 3. Revisar Resultados

```bash
# Ver reportes generados
ls -lh results/experiment-04-dynamodb/
ls -lh results/experiment-05-lambda/

# Ver reporte final
cat results/suite-summary.json
```

---

## 💡 Ventajas del Enfoque Bash

1. **Portabilidad:** Funciona en cualquier entorno Unix (EC2, local, Docker)
2. **Sin dependencias AWS:** No requiere permisos especiales
3. **Educativo:** Código visible y modificable
4. **Debugging:** Logs detallados en cada paso
5. **Costo cero:** No servicios pagos adicionales
6. **Flexibilidad:** Fácil agregar nuevos tipos de errores

---

## 📚 Lecciones Aprendidas

### Problema Original:
```
AccessDeniedException: User is not authorized to perform: 
fis:CreateExperimentTemplate on resource
```

### Diagnóstico:
- AWS Academy Learner Lab restringe servicios como FIS, ECS, EKS
- Timeout en `aws fis create-experiment-template` (comando cuelga indefinidamente)
- No hay workaround disponible sin cuenta AWS completa

### Solución Implementada:
1. Diagnosticar con `diagnose-fis.sh` (timeout 5s)
2. Confirmar `AccessDeniedException` 
3. Pivotar a simulaciones Bash que replican comportamiento FIS
4. Mantener templates FIS como referencia educativa

---

## 🔍 Validación Técnica

### Simulación DynamoDB Throttling

**Teoría:**
- DynamoDB tiene límites RCU/WCU
- Throttling devuelve `ProvisionedThroughputExceededException`
- Circuit breaker debe activarse tras N fallos

**Implementación Bash:**
- 50 requests paralelos simulan carga alta
- Detectar 429 en respuestas API Gateway
- Validar que Lambda activa circuit breaker
- Medir recovery time

### Simulación Lambda Error Injection

**Teoría:**
- Errores Lambda: 400 (client), 500 (server), 503 (throttling)
- Retry logic debe manejar errores transitorios
- Graceful degradation para errores permanentes

**Implementación Bash:**
- Inyectar errores controlados (30% rate)
- Clasificar respuestas por código HTTP
- Validar error handling patterns
- Medir degradation impact

---

## ✅ Checklist de Completitud

- [x] Scripts bash creados (04, 05)
- [x] README.md actualizado (tabla, instrucciones)
- [x] Experiments.md actualizado (herramientas, plan)
- [x] run-all-chaos-experiments.sh limpio (sin FIS)
- [x] Documentación de referencia (templates FIS preservados)
- [x] Este resumen (FIS-ELIMINATION-SUMMARY.md)
- [ ] Test de ejecución individual ← **SIGUIENTE**
- [ ] Test de suite completa ← **DESPUÉS**
- [ ] Generación de reportes ← **FINAL**

---

**Estado:** 🟢 **Implementación completa - Listo para testing**
