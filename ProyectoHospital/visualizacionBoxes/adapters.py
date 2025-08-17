from allauth.account.adapter import DefaultAccountAdapter
from allauth.socialaccount.adapter import DefaultSocialAccountAdapter
from django.contrib.auth.models import User
from .models import PerfilUsuario, TipoUsuario


class CustomAccountAdapter(DefaultAccountAdapter):
    """Adapter personalizado para el manejo de cuentas."""
    
    def is_open_for_signup(self, request):
        """Permite el registro de nuevos usuarios."""
        return True


class CustomSocialAccountAdapter(DefaultSocialAccountAdapter):
    """Adapter personalizado para el manejo de cuentas sociales."""
    
    def is_open_for_signup(self, request, sociallogin):
        """Permite el registro a través de proveedores sociales."""
        return True
    
    def save_user(self, request, sociallogin, form=None):
        """
        Guarda el usuario y crea su perfil con tipo por defecto.
        """
        user = super().save_user(request, sociallogin, form)
        
        # Crear perfil de usuario si no existe
        if not hasattr(user, 'perfilusuario'):
            # Obtener o crear tipo de usuario por defecto (Visitante)
            tipo_visitante, created = TipoUsuario.objects.get_or_create(
                nombre='Visitante',
                defaults={
                    'descripcion': 'Usuario visitante con acceso limitado',
                    'activo': True
                }
            )
            
            # Crear perfil de usuario
            PerfilUsuario.objects.create(
                usuario=user,
                tipo_usuario=tipo_visitante,
                activo=True
            )
        
        return user
    
    def populate_user(self, request, sociallogin, data):
        """
        Popula los datos del usuario desde la información social.
        """
        user = super().populate_user(request, sociallogin, data)
        
        # Agregar información adicional del perfil de Google
        extra_data = sociallogin.account.extra_data
        if extra_data:
            if 'given_name' in extra_data:
                user.first_name = extra_data['given_name']
            if 'family_name' in extra_data:
                user.last_name = extra_data['family_name']
        
        return user
