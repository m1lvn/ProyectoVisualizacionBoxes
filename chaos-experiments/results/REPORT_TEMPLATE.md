# 📊 Reporte de Experimento de Chaos Engineering

## Información General

- **Experimento ID:** [Ej: exp-01-dos-attack]
- **Nombre:** [Nombre descriptivo del experimento]
- **Fecha de Ejecución:** [YYYY-MM-DD HH:MM]
- **Duración:** [X minutos]
- **Herramienta:** [Bash / AWS FIS / Gremlin]
- **Responsable:** [Nombre del ejecutor]
- **Estado:** [Completado / Parcial / Fallido]

---

## 1. Hipótesis

**¿Qué esperábamos que sucediera?**

[Describe la hipótesis del experimento. Por ejemplo: "El sistema debería mantener disponibilidad >95% incluso con throttling de DynamoDB"]

---

## 2. Configuración del Experimento

### Servicios Afectados:
- **Servicio Principal:** [Ej: DynamoDB tabla HospitalData]
- **Servicios Dependientes:** [Ej: Lambda getBoxes, API Gateway]

### Tipo de Fallo Simulado:
- **Categoría:** [Latency / Error / Throttling / Resource Exhaustion]
- **Intensidad:** [Ej: 80% de requests, 5 segundos de delay]
- **Duración:** [X minutos]

### Parámetros Específicos:
```
[Incluir configuración específica del experimento]
Ejemplo para Bash:
- Requests: 1000
- Concurrencia: 50
- Endpoint: /api/boxes

Ejemplo para AWS FIS:
- Action: aws:dynamodb:inject-throughput-exceptions
- Percentage: 80%
- Duration: PT5M

Ejemplo para Gremlin:
- Attack Type: CPU
- Percent: 90%
- Function: hospital-boxes-api-dev-getBoxes
```

---

## 3. Resultados

### 3.1 Métricas Observadas

| Métrica | Baseline | Durante Chaos | Post-Chaos | Objetivo |
|---------|----------|---------------|------------|----------|
| **Success Rate** | X% | X% | X% | >95% |
| **Latencia p50** | Xms | Xms | Xms | <200ms |
| **Latencia p99** | Xms | Xms | Xms | <1000ms |
| **Error Rate** | X% | X% | X% | <5% |
| **Throughput** | X req/s | X req/s | X req/s | >Y req/s |
| **MTTR** | - | - | Xmin | <5min |

### 3.2 Status Codes Observados

```
Durante el experimento:
  Status 200: XXX requests (XX%)
  Status 429: XXX requests (XX%)
  Status 500: XXX requests (XX%)
  Status 502: XXX requests (XX%)
  Status 503: XXX requests (XX%)
  Status 504: XXX requests (XX%)
  Otros:      XXX requests (XX%)
```

### 3.3 Gráficos y Screenshots

[Insertar capturas de CloudWatch, Gremlin Dashboard, etc.]

```
📊 CloudWatch Metrics:
  - [Link o screenshot de Lambda Duration]
  - [Link o screenshot de DynamoDB Throttles]
  - [Link o screenshot de API Gateway 4xx/5xx]

📈 Gremlin Dashboard:
  - [Screenshot del timeline del ataque]
  - [Screenshot de las métricas en tiempo real]
```

---

## 4. Análisis

### 4.1 Comportamiento del Sistema

**✅ Aspectos Positivos:**
- [Listar qué funcionó bien]
- Ejemplo: "El sistema se mantuvo operacional durante todo el experimento"
- Ejemplo: "Retry logic funcionó correctamente en X% de los casos"

**❌ Problemas Identificados:**
- [Listar qué falló o no cumplió expectativas]
- Ejemplo: "Tasa de error alcanzó 34.7%, superando el objetivo de <5%"
- Ejemplo: "Latencia p99 superó los 5 segundos, causando timeouts"

**⚠️ Áreas de Mejora:**
- [Listar aspectos que requieren atención]
- Ejemplo: "Circuit breaker no se activó correctamente"
- Ejemplo: "Logs de error no fueron suficientemente descriptivos"

### 4.2 Validación de Hipótesis

**Hipótesis Original:** [Repetir la hipótesis]

**Resultado:** [✅ VALIDADA / ❌ RECHAZADA / ⚠️ PARCIALMENTE VALIDADA]

**Explicación:**
[Explicar por qué se validó o rechazó la hipótesis con datos concretos]

---

## 5. Problemas Encontrados

### Problema #1: [Título descriptivo]
- **Severidad:** [🔴 Crítica / 🟡 Media / 🟢 Baja]
- **Descripción:** [Descripción detallada del problema]
- **Evidencia:** [Logs, métricas, screenshots]
- **Impacto:** [Impacto en usuarios/sistema]
- **Root Cause:** [Causa raíz identificada]

### Problema #2: [Título descriptivo]
- **Severidad:** [🔴 Crítica / 🟡 Media / 🟢 Baja]
- **Descripción:** [Descripción detallada del problema]
- **Evidencia:** [Logs, métricas, screenshots]
- **Impacto:** [Impacto en usuarios/sistema]
- **Root Cause:** [Causa raíz identificada]

[Agregar más problemas según sea necesario]

---

## 6. Mejoras Propuestas

### Mejora #1: [Título]
- **Prioridad:** [🔴 Alta / 🟡 Media / 🟢 Baja]
- **Descripción:** [Qué se propone implementar]
- **Beneficio Esperado:** [Qué mejorará]
- **Esfuerzo Estimado:** [Horas o días]
- **Código Propuesto:**
```javascript
// Ejemplo de código de la mejora
async function mejoraEjemplo() {
  // Implementación
}
```

### Mejora #2: [Título]
- **Prioridad:** [🔴 Alta / 🟡 Media / 🟢 Baja]
- **Descripción:** [Qué se propone implementar]
- **Beneficio Esperado:** [Qué mejorará]
- **Esfuerzo Estimado:** [Horas o días]

### Mejora #3: [Título]
- **Prioridad:** [🔴 Alta / 🟡 Media / 🟢 Baja]
- **Descripción:** [Qué se propone implementar]
- **Beneficio Esperado:** [Qué mejorará]
- **Esfuerzo Estimado:** [Horas o días]

---

## 7. Logs Relevantes

### Lambda Logs
```
[Incluir los logs más relevantes de Lambda durante el experimento]
2025-10-27T10:30:15Z START RequestId: abc-123
2025-10-27T10:30:15Z ERROR: ProvisionedThroughputExceededException
2025-10-27T10:30:16Z Retry attempt 1/3
...
```

### API Gateway Logs
```
[Incluir logs de API Gateway]
```

### DynamoDB Metrics
```
[Incluir métricas relevantes de DynamoDB]
ThrottledRequests: 243
ConsumedReadCapacity: 1500
ConsumedWriteCapacity: 200
```

---

## 8. Lecciones Aprendidas

### 💡 Aprendizajes Técnicos:
1. [Aprendizaje técnico 1]
2. [Aprendizaje técnico 2]
3. [Aprendizaje técnico 3]

### 💡 Aprendizajes de Proceso:
1. [Aprendizaje de proceso 1]
2. [Aprendizaje de proceso 2]

### 💡 Aprendizajes para Futuros Experimentos:
1. [Qué hacer diferente la próxima vez]
2. [Mejoras al proceso de experimentación]

---

## 9. Próximos Pasos

### Acciones Inmediatas (Esta semana):
- [ ] [Acción 1 - Asignado a: X]
- [ ] [Acción 2 - Asignado a: Y]
- [ ] [Acción 3 - Asignado a: Z]

### Acciones a Mediano Plazo (Este mes):
- [ ] [Acción 1]
- [ ] [Acción 2]

### Validación:
- [ ] Re-ejecutar experimento después de implementar mejoras
- [ ] Validar que las métricas mejoraron
- [ ] Documentar resultados de validación

---

## 10. Conclusión

**Estado Final del Sistema:** [Operacional / Degradado / Recuperado]

**Cumplimiento de Objetivo:** [✅ Logrado / ❌ No logrado / ⚠️ Parcial]

**Resumen Ejecutivo:**
[Párrafo conciso resumiendo:
- Qué se probó
- Qué se encontró
- Qué se va a hacer al respecto
- Nivel de resiliencia actual del sistema]

**Recomendación:**
[✅ SISTEMA RESILIENTE / ⚠️ REQUIERE MEJORAS / 🚨 ACCIÓN INMEDIATA REQUERIDA]

---

## 11. Anexos

### Anexo A: Archivos de Datos
- Baseline CSV: `[ruta/al/archivo.csv]`
- Experiment CSV: `[ruta/al/archivo.csv]`
- CloudWatch JSON: `[ruta/al/archivo.json]`

### Anexo B: Scripts Utilizados
- Script: `[nombre-del-script.sh]`
- Configuración: `[archivo-de-config.json]`

### Anexo C: Referencias
- [Link a documentación relevante]
- [Link a issues de GitHub]
- [Link a dashboards de CloudWatch]

---

**Documento generado:** [YYYY-MM-DD]  
**Versión:** 1.0  
**Revisado por:** [Nombre]  
**Aprobado por:** [Nombre]
