# 🚀 Inicio Rápido - JWT Automático

## ⚡ TL;DR - 3 Comandos

```bash
# 1. Setup (una vez)
cp .env.example .env
nano .env  # Agrega tus credenciales de Cognito

# 2. Instalar + Configurar (una vez)
./install-dependencies.sh
./setup-jwt-secrets-manager.sh  # Selecciona opción A

# 3. Ejecutar experimentos (siempre que quieras)
./run-all-chaos-experiments.sh
```

---

## 🔐 Configuración de .env

```bash
# En .env (NO subir a git)
COGNITO_USERNAME=tu_email@example.com
COGNITO_PASSWORD=tu_password_real
SERVERLESS_AUTH_URL=https://utcn9m1wwg.execute-api.us-east-1.amazonaws.com
```

**Estas son las MISMAS credenciales que usas en tu aplicación Django.**

---

## ✅ Verificación

```bash
# Probar autenticación manualmente
python3 get-jwt-cognito.py

# Debe imprimir:
# 🔐 Autenticando con Cognito...
#    Usuario: tu_email@example.com
# ✅ Autenticación exitosa
# eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0...
```

---

## 🎯 Ventajas

- ✅ **100% automático** - Sin copy-paste manual
- ✅ **Mismas credenciales** - Que usas en Django
- ✅ **Seguro** - JWT en AWS Secrets Manager
- ✅ **Reutilizable** - Una vez configurado, funciona siempre

---

## 📚 Documentación Completa

- `JWT-AUTO-GUIDE.md` - Guía técnica completa
- `README.md` - Documentación general
- `.env.example` - Template de configuración

---

## ❓ Troubleshooting

### Error: "No se pudo obtener automáticamente"

```bash
# 1. Verificar credenciales
cat .env | grep COGNITO

# 2. Probar manualmente
python3 get-jwt-cognito.py

# 3. Verificar que requests esté instalado
pip3 install requests boto3
```

### Error: "Module 'requests' not found"

```bash
# Instalar dependencias Python
pip3 install -r requirements.txt
```

---

**¿Preguntas?** Lee `JWT-AUTO-GUIDE.md` para la explicación técnica completa.
