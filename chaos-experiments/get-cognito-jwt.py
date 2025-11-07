#!/usr/bin/env python3
"""
Script para obtener JWT token desde Cognito User Pool
Usado para autenticación en chaos engineering tests
"""

import boto3
import json
import sys
import os
from botocore.exceptions import ClientError

def get_stack_outputs(stack_name='hospital-boxes-api-dev'):
    """Obtiene los outputs del stack de CloudFormation"""
    try:
        cfn = boto3.client('cloudformation', region_name='us-east-1')
        response = cfn.describe_stacks(StackName=stack_name)
        
        if not response['Stacks']:
            print(f"❌ Stack '{stack_name}' no encontrado", file=sys.stderr)
            return None
            
        outputs = {}
        for output in response['Stacks'][0].get('Outputs', []):
            outputs[output['OutputKey']] = output['OutputValue']
            
        return outputs
    except ClientError as e:
        print(f"❌ Error obteniendo stack outputs: {e}", file=sys.stderr)
        return None

def get_test_user_credentials():
    """
    Retorna credenciales de usuario de prueba
    Puedes modificar estos valores según los usuarios creados por setup-test-users
    """
    users = {
        'admin': {
            'username': 'admin@hospital.test',
            'password': 'Admin123!',
            'description': 'Usuario administrador de prueba'
        },
        'personal': {
            'username': 'personal@hospital.test', 
            'password': 'Personal123!',
            'description': 'Usuario personal médico de prueba'
        },
        'test': {
            'username': 'test@hospital.test',
            'password': 'Test123!',
            'description': 'Usuario genérico de prueba'
        }
    }
    
    # Usar admin por defecto
    user_type = os.environ.get('TEST_USER', 'admin')
    return users.get(user_type, users['admin'])

def authenticate_user(user_pool_id, client_id, username, password):
    """Autentica usuario y obtiene tokens"""
    try:
        cognito = boto3.client('cognito-idp', region_name='us-east-1')
        
        print(f"🔐 Autenticando usuario: {username}...", file=sys.stderr)
        
        response = cognito.admin_initiate_auth(
            UserPoolId=user_pool_id,
            ClientId=client_id,
            AuthFlow='ADMIN_NO_SRP_AUTH',
            AuthParameters={
                'USERNAME': username,
                'PASSWORD': password
            }
        )
        
        if 'AuthenticationResult' not in response:
            print("❌ Respuesta de autenticación no contiene tokens", file=sys.stderr)
            return None
            
        return response['AuthenticationResult']
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        
        if error_code == 'NotAuthorizedException':
            print(f"❌ Usuario o contraseña incorrectos", file=sys.stderr)
        elif error_code == 'UserNotFoundException':
            print(f"❌ Usuario no existe: {username}", file=sys.stderr)
            print("💡 Asegúrate de que setup-test-users creó los usuarios correctamente", file=sys.stderr)
        elif error_code == 'UserNotConfirmedException':
            print(f"⚠️  Usuario no confirmado, confirmando automáticamente...", file=sys.stderr)
            try:
                cognito.admin_confirm_sign_up(
                    UserPoolId=user_pool_id,
                    Username=username
                )
                print("✅ Usuario confirmado, reintentando autenticación...", file=sys.stderr)
                return authenticate_user(user_pool_id, client_id, username, password)
            except Exception as confirm_error:
                print(f"❌ Error confirmando usuario: {confirm_error}", file=sys.stderr)
        else:
            print(f"❌ Error de autenticación: {error_code} - {e}", file=sys.stderr)
            
        return None

def update_env_file(jwt_token, api_endpoint):
    """Actualiza el archivo .env con el nuevo JWT"""
    env_file = os.path.join(os.path.dirname(__file__), '.env')
    
    try:
        # Leer contenido actual
        if os.path.exists(env_file):
            with open(env_file, 'r') as f:
                lines = f.readlines()
        else:
            lines = []
        
        # Actualizar o agregar JWT_TOKEN
        jwt_found = False
        endpoint_found = False
        new_lines = []
        
        for line in lines:
            if line.startswith('JWT_TOKEN='):
                new_lines.append(f'JWT_TOKEN={jwt_token}\n')
                jwt_found = True
            elif line.startswith('API_ENDPOINT='):
                new_lines.append(f'API_ENDPOINT={api_endpoint}\n')
                endpoint_found = True
            else:
                new_lines.append(line)
        
        if not jwt_found:
            new_lines.append(f'JWT_TOKEN={jwt_token}\n')
        if not endpoint_found:
            new_lines.append(f'API_ENDPOINT={api_endpoint}\n')
            
        # Escribir archivo
        with open(env_file, 'w') as f:
            f.writelines(new_lines)
            
        print(f"✅ Archivo .env actualizado", file=sys.stderr)
        
    except Exception as e:
        print(f"⚠️  Error actualizando .env: {e}", file=sys.stderr)

def main():
    print("=" * 60, file=sys.stderr)
    print("🔑 Obteniendo JWT Token desde Cognito User Pool", file=sys.stderr)
    print("=" * 60, file=sys.stderr)
    
    # 1. Obtener información del stack
    print("\n📦 Obteniendo información del stack...", file=sys.stderr)
    outputs = get_stack_outputs()
    
    if not outputs:
        print("\n❌ No se pudo obtener información del stack", file=sys.stderr)
        sys.exit(1)
    
    user_pool_id = outputs.get('UserPoolId')
    client_id = outputs.get('UserPoolClientId')
    api_endpoint = outputs.get('ApiGatewayUrl')
    
    if not all([user_pool_id, client_id, api_endpoint]):
        print("❌ Faltan outputs requeridos del stack:", file=sys.stderr)
        print(f"   UserPoolId: {user_pool_id}", file=sys.stderr)
        print(f"   UserPoolClientId: {client_id}", file=sys.stderr)
        print(f"   ApiGatewayUrl: {api_endpoint}", file=sys.stderr)
        sys.exit(1)
    
    print(f"✅ User Pool ID: {user_pool_id}", file=sys.stderr)
    print(f"✅ Client ID: {client_id}", file=sys.stderr)
    print(f"✅ API Endpoint: {api_endpoint}", file=sys.stderr)
    
    # 2. Obtener credenciales de usuario de prueba
    print("\n👤 Obteniendo credenciales de usuario de prueba...", file=sys.stderr)
    test_user = get_test_user_credentials()
    print(f"✅ Usando usuario: {test_user['username']}", file=sys.stderr)
    print(f"   ({test_user['description']})", file=sys.stderr)
    
    # 3. Autenticar y obtener tokens
    print("\n🔐 Autenticando usuario...", file=sys.stderr)
    auth_result = authenticate_user(
        user_pool_id,
        client_id,
        test_user['username'],
        test_user['password']
    )
    
    if not auth_result:
        print("\n❌ No se pudo obtener token JWT", file=sys.stderr)
        print("\n💡 Posibles soluciones:", file=sys.stderr)
        print("   1. Verifica que los usuarios de prueba fueron creados:", file=sys.stderr)
        print("      aws cognito-idp list-users --user-pool-id", user_pool_id, file=sys.stderr)
        print("   2. Crea un usuario manualmente:", file=sys.stderr)
        print("      aws cognito-idp admin-create-user --user-pool-id", user_pool_id, "\\", file=sys.stderr)
        print("        --username admin@hospital.test --user-attributes Name=email,Value=admin@hospital.test", file=sys.stderr)
        print("   3. Establece la contraseña:", file=sys.stderr)
        print("      aws cognito-idp admin-set-user-password --user-pool-id", user_pool_id, "\\", file=sys.stderr)
        print("        --username admin@hospital.test --password Admin123! --permanent", file=sys.stderr)
        sys.exit(1)
    
    id_token = auth_result.get('IdToken')
    access_token = auth_result.get('AccessToken')
    
    print("✅ Autenticación exitosa!", file=sys.stderr)
    print(f"   Token expira en: {auth_result.get('ExpiresIn', 'N/A')} segundos", file=sys.stderr)
    
    # 4. Actualizar .env
    print("\n📝 Actualizando archivo .env...", file=sys.stderr)
    update_env_file(id_token, api_endpoint)
    
    # 5. Mostrar resumen
    print("\n" + "=" * 60, file=sys.stderr)
    print("✅ JWT Token obtenido exitosamente", file=sys.stderr)
    print("=" * 60, file=sys.stderr)
    print(f"\n🔗 API Endpoint: {api_endpoint}", file=sys.stderr)
    print(f"👤 Usuario: {test_user['username']}", file=sys.stderr)
    print(f"⏰ Válido por: {auth_result.get('ExpiresIn', 'N/A')} segundos (~{auth_result.get('ExpiresIn', 0)//60} minutos)", file=sys.stderr)
    
    # Imprimir el token en stdout para captura en scripts
    print(id_token)
    
    return 0

if __name__ == '__main__':
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\n⚠️  Operación cancelada por el usuario", file=sys.stderr)
        sys.exit(130)
    except Exception as e:
        print(f"\n❌ Error inesperado: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
        sys.exit(1)
