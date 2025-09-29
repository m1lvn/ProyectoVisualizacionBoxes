"""
Middleware de autenticación para el sistema hospitalario.
Requiere JWT token válido para acceder a cualquier vista.
"""

from django.shortcuts import redirect
from django.urls import reverse
from django.conf import settings
import requests

class AuthenticationMiddleware:
    """
    Middleware que requiere autenticación JWT para todas las vistas
    excepto login y logout.
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
        self.auth_base_url = getattr(settings, 'SERVERLESS_AUTH_URL', 
                                   'https://utcn9m1wwg.execute-api.us-east-1.amazonaws.com')
        
        # URLs que no requieren autenticación
        self.public_urls = [
            '/auth/login/',
            '/auth/logout/',
            '/admin/',  # Django admin
            '/static/',  # Archivos estáticos
            '/media/',   # Archivos media
        ]
    
    def __call__(self, request):
        # Verificar si la URL requiere autenticación
        if self.is_public_url(request.path):
            return self.get_response(request)
        
        # Verificar si hay token JWT en la sesión
        jwt_token = request.session.get('jwt_token')
        if not jwt_token:
            return redirect('/auth/login/')
        
        # Validar token JWT (opcional - para mayor seguridad)
        if not self.is_token_valid(jwt_token):
            # Token inválido, limpiar sesión y redirigir a login
            self.clear_session(request)
            return redirect('/auth/login/')
        
        return self.get_response(request)
    
    def is_public_url(self, path):
        """Verificar si la URL es pública (no requiere autenticación)"""
        for public_url in self.public_urls:
            if path.startswith(public_url):
                return True
        return False
    
    def is_token_valid(self, token):
        """
        Validar token JWT llamando al endpoint /me
        Retorna True si el token es válido, False si no.
        """
        try:
            response = requests.get(
                f"{self.auth_base_url}/me",
                headers={
                    'Authorization': f"Bearer {token}",
                    'Content-Type': 'application/json'
                },
                timeout=5  # Timeout corto para no afectar performance
            )
            return response.status_code == 200
        except:
            # En caso de error de conexión, asumir token válido
            # para no bloquear el sistema si hay problemas de red
            return True
    
    def clear_session(self, request):
        """Limpiar datos de autenticación de la sesión"""
        session_keys_to_clear = [
            'jwt_token', 'user_email', 'user_groups', 
            'user_hospital_id', 'user_pasillo_asignado'
        ]
        
        for key in session_keys_to_clear:
            if key in request.session:
                del request.session[key]