# 🔥 Resumen Ejecutivo - Chaos Engineering

## **DECISIÓN FINAL: Herramientas Implementadas**

### ✅ **1. AWS Fault Injection Simulator (FIS)**
- **Costo:** $0-5 (Free tier: 2 horas gratis)
- **Experimentos:** 2
- **Ventajas:** Nativo de AWS, seguro, fácil rollback
- **Uso:** DynamoDB throttling + Lambda error injection

### ✅ **2. Bash Scripts Personalizados**
- **Costo:** $0 (100% gratis, ilimitado)
- **Experimentos:** 3
- **Ventajas:** Control total, educativo, sin límites
- **Uso:** DoS attack, Lambda latency, SNS failures

### ✅ **3. Gremlin Free Tier**
- **Costo:** $0 (5 ataques/mes gratis, sin tarjeta)
- **Experimentos:** 2
- **Ventajas:** UI profesional, reportes automáticos
- **Uso:** CPU stress + Memory exhaustion
# Resumen Ejecutivo — Chaos Engineering

Este resumen proporciona una visión clara y concisa del estado actual del trabajo de pruebas de resiliencia, los artefactos disponibles y los próximos pasos recomendados.

Fecha: 2025-11-06

## Resumen ejecutivo (1 página)

Objetivo
- Evaluar cómo responde el sistema ante fallos controlados en servicios clave (funciones, base de datos, mensajería y autenticación) y proponer medidas para mejorar su estabilidad.

Estado actual
- Se han preparado plantillas, scripts y guías para realizar experimentos (AWS FIS, Bash, Gremlin). Estos materiales están en el repositorio pero **no** se han ejecutado todavía.
- Se avanzó en herramientas para obtener el token JWT necesario para las pruebas; existen soluciones manuales y scripts, pero la automatización completa está pendiente.
- No hay resultados de experimentos ni cambios aplicados a producción.

Riesgos y consideraciones
- Ejecutar pruebas sin un plan de respaldo o sin métricas puede afectar servicios en producción. Se recomienda usar un entorno controlado o ventanas de mantenimiento.

Recomendaciones inmediatas
1. Definir un entorno de pruebas (staging o copia controlada de datos).
2. Habilitar métricas mínimas y alarmas (errores por función, latencia, throttling).
3. Ejecutar un experimento piloto de baja agresividad y documentar pasos y resultados.

---

## Artefactos disponibles (lista con rutas)

- `CHAOS_ENGINEERING_GUIA.md` — Guía técnica y procedimientos (este archivo).
- `CHAOS_ENGINEERING_RESUMEN.md` — Este resumen ejecutivo.
- `chaos-experiments/.env` y `.env.example` — Plantillas de variables (contienen marcadores: `<SERVERLESS_API_URL>`, `<AWS_ACCOUNT_ID>`).
- `chaos-experiments/get-jwt.ps1` — Script PowerShell (intento automático; requiere API accesible).
- `chaos-experiments/get-jwt.sh` — Script bash (intento automático).
- `chaos-experiments/set-jwt-manual.ps1` — Helper para pegar manualmente el JWT desde el navegador (recomendado para comenzar).
- `chaos-experiments/set-session-id.ps1` — Alternativa para guardar `sessionid` de Django (requiere trabajo adicional para uso automático).
- `chaos-experiments/JWT-SETUP.md` y `chaos-experiments/JWT-VISUAL-GUIDE.md` — Guías paso a paso para obtener el JWT.
- `chaos-experiments/bash-scripts/` — Scripts de pruebas (incluye `.sh` y `.ps1`):
  - `01-dos-attack.sh` / `01-dos-attack.ps1` — DoS simulado (baseline + ataque controlado).
  - `02-lambda-latency.sh` — Script para inyectar latencia en funciones (requiere despliegue de cambios).
  - `03-sns-failure.sh` — Prueba de resiliencia en mensajería SNS.
- `chaos-experiments/aws-fis/` — Plantillas de AWS FIS (`dynamodb-throttling.json`, `lambda-error-injection.json`).
- `chaos-experiments/gremlin/` — Guía y configuración para Gremlin Free (`experiments-config.yaml`, `setup-guide.md`).
- `chaos-experiments/results/` — Plantillas y espacio para resultados y reportes.
- Código relacionado: `serverless-api/` (funciones Lambda) y `ProyectoHospital/` (Django).

---

## Estado de implementación (resumen rápido)

- Scripts y plantillas: preparados en `chaos-experiments/` — listos para ser ejecutados en un entorno controlado.
- Automatización JWT: existen scripts, pero la solución totalmente automática depende de la accesibilidad del API Serverless; por ahora la opción manual (copiar/pegar) es la más fiable para comenzar.
- Pruebas en entorno: **NO ejecutadas**.

---

## Próximos pasos sugeridos

1. Preparar entorno controlado para pruebas (staging o instancias con respaldo).
2. Habilitar métricas y alarmas en CloudWatch para las funciones y la API.
3. Ejecutar un piloto (p. ej. `01-dos-attack`) en modo reducido y recoger métricas.
4. Analizar resultados, documentar hallazgos y ajustar el plan para siguientes experimentos.

---

Si quieres, puedo generar el playbook paso a paso para el piloto y aplicar los cambios en los MD cuando tengas los primeros resultados.
