#!/bin/bash

echo "=== Testing Módulo de Personalización ==="

# URLs
AUTH_URL="https://utcn9m1wwg.execute-api.us-east-1.amazonaws.com"
API_URL="https://r8qjc8hqrl.execute-api.us-east-1.amazonaws.com/dev/api"

echo "1. Obteniendo token JWT..."
JWT_RESPONSE=$(curl -s -X POST "$AUTH_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@hospital.com","password":"Hospital123!"}')

JWT_TOKEN=$(echo $JWT_RESPONSE | jq -r '.token')

if [ "$JWT_TOKEN" = "null" ]; then
  echo "Error: No se pudo obtener el token JWT"
  echo "Response: $JWT_RESPONSE"
  exit 1
fi

echo "Token obtenido exitosamente"
echo ""

echo "2. Listando clientes existentes..."
curl -s -X GET "$API_URL/config" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" | jq '.'

echo ""

echo "3. Obteniendo configuración del cliente hospital001 (debería devolver defaults)..."
curl -s -X GET "$API_URL/config/hospital001" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" | jq '.'

echo ""

echo "4. Creando configuración personalizada para hospital001..."
curl -s -X PUT "$API_URL/config/hospital001" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "branding": {
      "colors": {
        "primary": "#2c3e50",
        "secondary": "#e74c3c", 
        "accent": "#f39c12"
      },
      "name": "Hospital San Juan",
      "logo": "https://example.com/logo.png"
    },
    "texts": {
      "welcomeMessage": "Bienvenido al Sistema Hospital San Juan",
      "labels": {
        "boxes": "Consultorios",
        "pasillos": "Sectores",
        "agendas": "Citas Médicas",
        "profesionales": "Doctores"
      },
      "messages": {
        "loading": "Cargando información...",
        "noData": "Sin información disponible",
        "error": "Error en el sistema"
      }
    }
  }' | jq '.'

echo ""

echo "5. Verificando configuración actualizada..."
curl -s -X GET "$API_URL/config/hospital001" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" | jq '.'

echo ""

echo "6. Creando configuración para otro cliente (hospital002)..."
curl -s -X PUT "$API_URL/config/hospital002" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "branding": {
      "colors": {
        "primary": "#8e44ad",
        "secondary": "#27ae60",
        "accent": "#3498db"
      },
      "name": "Hospital Central",
      "logo": "https://example.com/logo2.png"
    },
    "texts": {
      "welcomeMessage": "Sistema Hospitalario Central",
      "labels": {
        "boxes": "Boxes Médicos",
        "pasillos": "Pasillos",
        "agendas": "Turnos",
        "profesionales": "Médicos"
      }
    }
  }' | jq '.'

echo ""

echo "7. Listando todos los clientes después de las configuraciones..."
curl -s -X GET "$API_URL/config" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" | jq '.'

echo ""

echo "8. Testando acceso con usuario no-admin (debe fallar en PUT)..."
PERSONAL_RESPONSE=$(curl -s -X POST "$AUTH_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"medico1@hospital.com","password":"Hospital123!"}')

PERSONAL_TOKEN=$(echo $PERSONAL_RESPONSE | jq -r '.token')

echo "Intentando PUT con usuario Personal (debe retornar 403):"
curl -s -X PUT "$API_URL/config/hospital001" \
  -H "Authorization: Bearer $PERSONAL_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"branding": {"name": "Test"}}' | jq '.'

echo ""
echo "Intentando GET con usuario Personal (debe funcionar):"
curl -s -X GET "$API_URL/config/hospital001" \
  -H "Authorization: Bearer $PERSONAL_TOKEN" \
  -H "Content-Type: application/json" | jq '.'

echo ""
echo "=== Testing Completado ==="