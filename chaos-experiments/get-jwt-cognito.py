#!/usr/bin/env python3
"""
Script para obtener JWT desde Cognito automáticamente.
Usa las mismas credenciales que tu aplicación Django.
"""

import requests
import json
import sys
import os
from datetime import datetime

# Configuración
# Por defecto usa la URL de settings.py de Django
# Puedes override con variable de entorno SERVERLESS_AUTH_URL
AUTH_BASE_URL = os.getenv('SERVERLESS_AUTH_URL', 'https://44wvhl6j05.execute-api.us-east-1.amazonaws.com')
COGNITO_USERNAME = os.getenv('COGNITO_USERNAME', '')
COGNITO_PASSWORD = os.getenv('COGNITO_PASSWORD', '')

def get_jwt_from_cognito(username=None, password=None):
    """
    Obtiene JWT desde Cognito usando las credenciales.
    Hace exactamente lo mismo que auth_views.py de Django.
    """
    
    # Usar variables de entorno o parámetros
    username = username or COGNITO_USERNAME
    password = password or COGNITO_PASSWORD
    
    if not username or not password:
        print("❌ Error: Debes proporcionar username y password", file=sys.stderr)
        print("\nOpciones:", file=sys.stderr)
        print("  1. Variables de entorno:", file=sys.stderr)
        print("     export COGNITO_USERNAME='tu_email@example.com'", file=sys.stderr)
        print("     export COGNITO_PASSWORD='tu_password'", file=sys.stderr)
        print("\n  2. Argumentos:", file=sys.stderr)
        print("     python3 get-jwt-cognito.py <username> <password>", file=sys.stderr)
        return None
    
    try:
        print(f"🔐 Autenticando con Cognito...", file=sys.stderr)
        print(f"   Usuario: {username}", file=sys.stderr)
        print(f"   URL: {AUTH_BASE_URL}/auth/login", file=sys.stderr)
        
        # Llamar a la misma API que usa Django
        response = requests.post(
            f"{AUTH_BASE_URL}/auth/login",
            json={
                'username': username,
                'password': password
            },
            headers={'Content-Type': 'application/json'},
            timeout=10
        )
        
        if response.status_code != 200:
            print(f"❌ Error HTTP {response.status_code}: {response.text}", file=sys.stderr)
            return None
        
        data = response.json()
        
        # Verificar respuesta exitosa
        if not data.get('ok', False):
            print(f"❌ Login fallido: {data.get('message', 'Error desconocido')}", file=sys.stderr)
            return None
        
        # Extraer tokens
        id_token = data.get('idToken')
        access_token = data.get('accessToken')
        refresh_token = data.get('refreshToken')
        expires_in = data.get('expiresIn', 3600)
        
        if not id_token:
            print("❌ No se recibió idToken en la respuesta", file=sys.stderr)
            return None
        
        print("✅ Autenticación exitosa", file=sys.stderr)
        print(f"   Token expira en: {expires_in}s (~{expires_in//60} minutos)", file=sys.stderr)
        
        # Retornar solo el ID token (que es el JWT que necesitamos)
        return {
            'jwt_token': id_token,
            'access_token': access_token,
            'refresh_token': refresh_token,
            'expires_in': expires_in,
            'obtained_at': datetime.now().isoformat()
        }
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Error de conexión: {e}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"❌ Error inesperado: {e}", file=sys.stderr)
        return None


def save_to_secrets_manager(jwt_data):
    """Guarda el JWT en AWS Secrets Manager"""
    import boto3
    
    try:
        client = boto3.client('secretsmanager')
        
        secret_name = "chaos-engineering/jwt-token"
        secret_value = {
            'token': jwt_data['jwt_token'],
            'expires_in': jwt_data['expires_in'],
            'obtained_at': jwt_data['obtained_at']
        }
        
        # Intentar actualizar o crear
        try:
            client.update_secret(
                SecretId=secret_name,
                SecretString=json.dumps(secret_value)
            )
            print(f"✅ JWT actualizado en Secrets Manager: {secret_name}", file=sys.stderr)
        except client.exceptions.ResourceNotFoundException:
            client.create_secret(
                Name=secret_name,
                SecretString=json.dumps(secret_value),
                Description='JWT Token para Chaos Engineering'
            )
            print(f"✅ JWT creado en Secrets Manager: {secret_name}", file=sys.stderr)
        
        return True
        
    except Exception as e:
        print(f"⚠️  No se pudo guardar en Secrets Manager: {e}", file=sys.stderr)
        return False


def save_to_env_file(jwt_data):
    """Guarda el JWT en archivo .env como backup"""
    try:
        env_file = os.path.join(os.path.dirname(__file__), '.env')
        
        with open(env_file, 'w') as f:
            f.write(f"# JWT Token obtenido automáticamente\n")
            f.write(f"# Fecha: {jwt_data['obtained_at']}\n")
            f.write(f"# Expira en: {jwt_data['expires_in']} segundos\n")
            f.write(f"JWT_TOKEN={jwt_data['jwt_token']}\n")
        
        print(f"✅ JWT guardado en {env_file}", file=sys.stderr)
        return True
        
    except Exception as e:
        print(f"⚠️  No se pudo guardar en .env: {e}", file=sys.stderr)
        return False


def main():
    """Función principal"""
    
    # Leer username y password de argumentos o variables de entorno
    username = sys.argv[1] if len(sys.argv) > 1 else None
    password = sys.argv[2] if len(sys.argv) > 2 else None
    
    # Obtener JWT
    jwt_data = get_jwt_from_cognito(username, password)
    
    if not jwt_data:
        sys.exit(1)
    
    # Guardar en Secrets Manager
    saved_sm = save_to_secrets_manager(jwt_data)
    
    # Guardar en .env como backup
    saved_env = save_to_env_file(jwt_data)
    
    # Imprimir el token en stdout (para que otros scripts puedan capturarlo)
    print(jwt_data['jwt_token'])
    
    if saved_sm or saved_env:
        sys.exit(0)
    else:
        print("\n⚠️  Token obtenido pero no se pudo guardar", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
