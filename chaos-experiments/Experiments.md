# 🔥 Plan de Experimentos de Chaos Engineering

> **Proyecto:** Sistema de Visualización de Boxes Hospitalarios  
> **Objetivo:** Validar resiliencia mediante simulación de fallos  
> **Herramientas:** AWS FIS + Bash Scripts + Gremlin Free Tier  

---

## 📋 **RESUMEN EJECUTIVO**

### **Herramientas Seleccionadas:**

| Herramienta | Tipo | Costo | # Experimentos | Estado |
|-------------|------|-------|----------------|---------|
| **Bash Scripts** | Custom scripts | $0 | 3 | 🟢 Listo |
| **AWS FIS** | Managed service | ~$0 (Free tier) | 2 | 🟡 Por configurar |
| **Gremlin Free** | SaaS Platform | $0 (5 ataques/mes) | 2 | 🟡 Por registrar |

**TOTAL: 7 experimentos planificados con costo $0-5**

---

## 📁 **ESTRUCTURA DEL PROYECTO**

```
chaos-experiments/
├── 📄 Experiments.md                    # Este documento - Plan maestro
├── aws-fis/
│   ├── dynamodb-throttling.json        # ✅ Template FIS experimento #4
│   └── lambda-error-injection.json     # 🟡 Template FIS experimento #5
├── bash-scripts/
│   ├── 01-dos-attack.sh                # ✅ Experimento #1
│   ├── 02-lambda-latency.sh            # ✅ Experimento #2
│   └── 03-sns-failure.sh               # 🟡 Experimento #3
├── gremlin/
│   ├── setup-guide.md                  # Guía de configuración
│   └── experiments-config.yaml         # Configuración de experimentos
└── results/
    ├── experiment-01-dos-report.md     # Resultados experimento #1
    ├── experiment-02-latency-report.md # Resultados experimento #2
    └── ...                             # Más reportes
```

---

## 🎯 **EXPERIMENTOS PLANIFICADOS**

### 1. DoS Attack Simulation (`01-dos-attack.sh`)

**Objetivo**: Probar rate limiting y throttling de API Gateway

**Configuración**:
- 1000 requests totales
- 50 requests concurrentes
- Endpoint: `/api/boxes`

**Métricas**:
- Tasa de éxito/fallo
- Latencia promedio
- Rate de throttling (429)

**Duración**: ~2-3 minutos

### 2. Lambda Latency Injection (`02-lambda-latency.sh`)

**Objetivo**: Simular latencia alta en Lambda functions

**Configuración**:
- Latencia inyectada: 5000ms
- Función: `getBoxes`
- Comparación: Baseline vs Chaos vs Recovery

**Métricas**:
- Latencia p50, p95, p99
- Tiempo de recuperación
- Impacto en UX

**Duración**: ~5-7 minutos

## 📊 AWS FIS (Fault Injection Simulator)

### Configurar Template

```bash
# Crear template desde JSON
aws fis create-experiment-template \
  --cli-input-json file://aws-fis/dynamodb-throttling.json \
  --region us-east-1

# Obtener template ID del output
```

### Ejecutar Experimento

```bash
# Iniciar experimento
aws fis start-experiment \
  --experiment-template-id TEMPLATE_ID \
  --tags Key=Test,Value=ChaosEngineering

# Monitorear progreso
aws fis get-experiment --id EXPERIMENT_ID
```

### Detener Experimento

```bash
# Detener manualmente si es necesario
aws fis stop-experiment --id EXPERIMENT_ID
```

## 📈 Monitoreo de Resultados

### CloudWatch Metrics

```bash
# Métricas de API Gateway
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name Count \
  --dimensions Name=ApiName,Value=hospital-boxes-api-dev \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum

# Métricas de Lambda
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=hospital-boxes-api-dev-getBoxes \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum

# Métricas de DynamoDB
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ThrottledRequests \
  --dimensions Name=TableName,Value=HospitalData \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum
```

### CloudWatch Logs

```bash
# Ver logs de Lambda durante experimento
aws logs tail /aws/lambda/hospital-boxes-api-dev-getBoxes \
  --since 10m \
  --follow

# Filtrar errores
aws logs filter-log-events \
  --log-group-name /aws/lambda/hospital-boxes-api-dev-getBoxes \
  --filter-pattern "ERROR" \
  --start-time $(date -u -d '10 minutes ago' +%s)000
```

## 📝 Análisis de Resultados

### Formato de Reporte

Cada experimento genera archivos en `results/`:

```
results/
├── dos-attack-20251026-143022.log
├── chaos-latency-20251026-143530.log
└── recovery-20251026-143820.log
```

### Análisis Automático

```bash
# Contar status codes
grep -c "200" results/dos-attack-*.log
grep -c "429" results/dos-attack-*.log
grep -c "500" results/dos-attack-*.log

# Calcular latencia promedio
grep "Request" results/dos-attack-*.log | \
  cut -d'|' -f2 | cut -d's' -f1 | \
  awk '{ sum += $1; n++ } END { if (n > 0) print "Avg:", sum / n, "s"; }'
```

## 🛡️ Implementar Resiliencia

### 1. Usar Utilidades de Resiliencia

```javascript
// En tus Lambda handlers
const { retryWithBackoff, CircuitBreaker, SimpleCache } = require('../utils/resilience');

// Ejemplo: boxes.js
const breaker = new CircuitBreaker({ failureThreshold: 5, timeout: 60000 });
const cache = new SimpleCache(60000); // Cache de 1 minuto

module.exports.getBoxes = async (event) => {
  try {
    const result = await retryWithBackoff(
      () => breaker.execute(() => dynamodb.scan(params).promise()),
      { maxRetries: 3, baseDelay: 100 }
    );
    
    return {
      statusCode: 200,
      body: JSON.stringify(result)
    };
  } catch (error) {
    // Fallback con datos en caché
    const cached = cache.get('boxes-default');
    if (cached) {
      return {
        statusCode: 200,
        body: JSON.stringify({
          success: true,
          cached: true,
          data: cached
        })
      };
    }
    
    return {
      statusCode: 503,
      body: JSON.stringify({
        success: false,
        error: 'Service temporarily unavailable'
      })
    };
  }
};
```

### 2. Desplegar con Resiliencia

```bash
cd ../serverless-api
serverless deploy
```

### 3. Re-ejecutar Experimentos

Después de implementar mejoras de resiliencia, re-ejecutar experimentos para validar:

```bash
./01-dos-attack.sh > results/dos-attack-with-resilience.log 2>&1
./02-lambda-latency.sh > results/latency-with-resilience.log 2>&1
```

## ⚠️ Advertencias de Seguridad

### IMPORTANTE

- ❌ **NO ejecutar en producción** sin aprobación
- ⚠️ Los experimentos **pueden causar downtime**
- 📊 Ejecutar en horarios de **bajo tráfico**
- 💾 Siempre tener **backups** antes de experimentos destructivos
- 🔄 Tener **plan de rollback** preparado

### Checklist Pre-Experimento

- [ ] Backup de configuración actual
- [ ] Notificación al equipo
- [ ] Monitoreo activo (CloudWatch Dashboard)
- [ ] Plan de rollback documentado
- [ ] Tiempo asignado para recuperación
- [ ] Token JWT válido y listo
- [ ] Ambiente de desarrollo/staging (no producción)

## 📚 Recursos Adicionales

- [AWS Fault Injection Simulator Docs](https://docs.aws.amazon.com/fis/)
- [Principles of Chaos Engineering](https://principlesofchaos.org/)
- [AWS Well-Architected - Reliability](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/)
- [Chaos Engineering Book (Netflix)](https://www.oreilly.com/library/view/chaos-engineering/9781492043867/)

## 🐛 Troubleshooting

### Error: "Permission denied"

```bash
chmod +x bash-scripts/*.sh
```

### Error: "AWS credentials not found"

```bash
aws configure
# O copiar credenciales de AWS Academy
```

### Error: "Token expired"

```bash
# Obtener nuevo token
curl -X POST https://API/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin@hospital.com","password":"Admin123!"}'
```

### Error: "Template validation failed"

```bash
# Validar JSON
cat aws-fis/dynamodb-throttling.json | jq .

# Verificar ARNs
aws dynamodb describe-table --table-name HospitalData
```

## 📞 Soporte

Si encuentras problemas:

1. Revisar logs en `results/`
2. Consultar CloudWatch Logs
3. Verificar estado de recursos AWS
4. Revisar documentación completa en `CHAOS_ENGINEERING_GUIA.md`

---

**✅ ¡Happy Chaos Testing!** 🔥

*Última actualización: Octubre 2025*
