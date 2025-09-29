"""
URLs para autenticación con Amazon Cognito.
"""

from django.urls import path
from . import auth_views

app_name = 'auth'

urlpatterns = [
    # Login - página principal si no está autenticado
    path('login/', auth_views.login_view, name='login'),
    
    # Logout - cerrar sesión
    path('logout/', auth_views.logout_view, name='logout'),
    
    # Perfil de usuario
    path('profile/', auth_views.user_profile_view, name='profile'),
]