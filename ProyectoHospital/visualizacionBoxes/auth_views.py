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
            response = requests.post(
                f"{AUTH_BASE_URL}/auth/login",
                json={
                    'email': email,
                    'password': password
                },
                headers={'Content-Type': 'application/json'},
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                # Guardar token y datos de usuario en sesión
                request.session['jwt_token'] = data.get('token')
                request.session['user_email'] = data.get('user', {}).get('email', email)
                request.session['user_groups'] = data.get('user', {}).get('groups', [])
                request.session['user_hospital_id'] = data.get('user', {}).get('hospital_id')
                request.session['user_pasillo_asignado'] = data.get('user', {}).get('pasillo_asignado')
                
                messages.success(request, f'Bienvenido {email}')
                return redirect('visualizacionBoxes:visualizacion_general')
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else {}
                error_message = error_data.get('message', 'Credenciales inválidas')
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
        'jwt_token', 'user_email', 'user_groups', 
        'user_hospital_id', 'user_pasillo_asignado'
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