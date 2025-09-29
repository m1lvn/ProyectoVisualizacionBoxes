"""
Vistas de autenticación para el sistema hospitalario.
Integración con Amazon Cognito vía API Serverless.
"""

from django.shortcuts import render, redirect
from django.http import JsonResponse
from django.contrib import messages
from django.conf import settings
import requests
import json

AUTH_BASE_URL = getattr(settings, 'SERVERLESS_AUTH_URL', 'https://utcn9m1wwg.execute-api.us-east-1.amazonaws.com')

def login_view(request):
    """Vista de login - página inicial del sistema"""
    if request.method == 'POST':
        email = request.POST.get('email')
        password = request.POST.get('password')
        
        if not email or not password:
            messages.error(request, 'Email y contraseña son requeridos')
            return render(request, 'auth/login.html')
        
        # Llamar API de autenticación
        try:
            print(f"DEBUG - Intentando login con email: {email}")
            print(f"DEBUG - AUTH_BASE_URL: {AUTH_BASE_URL}")
            
            response = requests.post(
                f"{AUTH_BASE_URL}/auth/login",
                json={
                    'username': email,  # La API espera 'username', no 'email'
                    'password': password
                },
                headers={'Content-Type': 'application/json'},
                timeout=10
            )
            
            print(f"DEBUG - Status Code: {response.status_code}")
            print(f"DEBUG - Response Text: {response.text}")
            
            if response.status_code == 200:
                data = response.json()
                
                # Verificar que la respuesta sea exitosa
                if data.get('ok', False):
                    # Obtener tokens
                    id_token = data.get('idToken')
                    access_token = data.get('accessToken')
                    refresh_token = data.get('refreshToken')
                    expires_in = data.get('expiresIn')
                    
                    # Guardar los tokens en la sesión
                    request.session['jwt_token'] = id_token
                    request.session['access_token'] = access_token
                    request.session['refresh_token'] = refresh_token
                    request.session['expires_in'] = expires_in
                    request.session['user_email'] = email
                    
                    # Decodificar JWT para obtener información del usuario
                    try:
                        import base64
                        import json
                        
                        # Decodificar el payload del JWT (sin verificación de firma por simplicidad)
                        payload = id_token.split('.')[1]
                        # Agregar padding si es necesario
                        payload += '=' * (4 - len(payload) % 4)
                        decoded = base64.urlsafe_b64decode(payload)
                        jwt_data = json.loads(decoded.decode('utf-8'))
                        
                        print(f"DEBUG - JWT Data: {jwt_data}")
                        
                        # Extraer grupos de Cognito
                        cognito_groups = jwt_data.get('cognito:groups', [])
                        if isinstance(cognito_groups, str):
                            # Si viene como string, convertir a lista
                            cognito_groups = [cognito_groups]
                        
                        # Guardar grupos en la sesión
                        request.session['user_groups'] = cognito_groups
                        request.session['user_hospital_id'] = jwt_data.get('custom:hospital_id', 'HOSPITAL_001')
                        request.session['user_pasillo_asignado'] = jwt_data.get('custom:pasillo_asignado')
                        
                        print(f"DEBUG - User Groups: {cognito_groups}")
                        print(f"DEBUG - Hospital ID: {jwt_data.get('custom:hospital_id')}")
                        
                    except Exception as e:
                        print(f"ERROR decodificando JWT: {e}")
                        request.session['user_groups'] = []
                    
                    messages.success(request, f'Bienvenido {email}')
                    return redirect('visualizacionBoxes:visualizacion_general')
                else:
                    messages.error(request, 'Credenciales inválidas')
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else {}
                error_message = error_data.get('message', error_data.get('error', 'Credenciales inválidas'))
                print(f"DEBUG - Error Data: {error_data}")
                messages.error(request, f'Error de autenticación: {error_message}')
                
        except requests.RequestException as e:
            messages.error(request, f'Error de conexión: {str(e)}')
        except Exception as e:
            messages.error(request, f'Error inesperado: {str(e)}')
    
    return render(request, 'auth/login.html')

def logout_view(request):
    """Vista de logout - limpiar sesión"""
    # Limpiar todos los datos de sesión relacionados con autenticación
    session_keys_to_clear = [
        'jwt_token', 'access_token', 'refresh_token', 'expires_in', 'user_email', 
        'user_groups', 'user_hospital_id', 'user_pasillo_asignado'
    ]
    
    for key in session_keys_to_clear:
        if key in request.session:
            del request.session[key]
    
    messages.success(request, 'Sesión cerrada exitosamente')
    return redirect('auth:login')

def user_profile_view(request):
    """Vista de perfil de usuario - mostrar información del usuario logueado"""
    if not request.session.get('jwt_token'):
        return redirect('auth:login')
    
    try:
        # Obtener información actualizada del usuario
        response = requests.get(
            f"{AUTH_BASE_URL}/me",
            headers={
                'Authorization': f"Bearer {request.session.get('jwt_token')}",
                'Content-Type': 'application/json'
            },
            timeout=10
        )
        
        if response.status_code == 200:
            user_data = response.json()
        else:
            user_data = {
                'email': request.session.get('user_email'),
                'groups': request.session.get('user_groups', []),
                'hospital_id': request.session.get('user_hospital_id'),
                'pasillo_asignado': request.session.get('user_pasillo_asignado')
            }
    except:
        user_data = {
            'email': request.session.get('user_email'),
            'groups': request.session.get('user_groups', []),
            'hospital_id': request.session.get('user_hospital_id'),
            'pasillo_asignado': request.session.get('user_pasillo_asignado')
        }
    
    context = {
        'user_data': user_data
    }
    
    return render(request, 'auth/profile.html', context)