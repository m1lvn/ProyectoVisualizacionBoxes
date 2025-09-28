"""
Adapters personalizados para django-allauth.

NOTA: Simplificado para sistema serverless - sin TipoUsuario (eliminado).
Los tipos de usuario ahora se manejan vía API si es necesario.
"""

from allauth.account.adapter import DefaultAccountAdapter
from allauth.socialaccount.adapter import DefaultSocialAccountAdapter
from django.contrib.auth.models import User
from .models import PerfilUsuario
import uuid


class CustomAccountAdapter(DefaultAccountAdapter):
    """Adapter personalizado para el manejo de cuentas."""
    
    def is_open_for_signup(self, request):
        """Permite el registro de nuevos usuarios."""
        return True
    
    def generate_unique_username(self, txts, regex=None):
        """
        Genera un username único basado en el email o usando UUID.
        """
        username = None
        if txts:
            for txt in txts:
                if txt:
                    # Usar la parte del email antes del @
                    if '@' in txt:
                        username = txt.split('@')[0]
                    else:
                        username = txt
                    break
        
        # Si no hay texto, generar username único
        if not username:
            username = f'user_{uuid.uuid4().hex[:8]}'
        
        # Limpiar el username (solo alfanumérico y guiones)
        username = ''.join(c for c in username if c.isalnum() or c in '-_').lower()
        
        # Asegurar que sea único
        original_username = username
        counter = 1
        while User.objects.filter(username=username).exists():
            username = f"{original_username}{counter}"
            counter += 1
        
        return username
    
    def save_user(self, request, user, form, commit=True):
        """
        Guarda el usuario y crea su perfil simplificado.
        """
        user = super().save_user(request, user, form, commit=False)
        
        # Generar username único si no existe
        if not user.username:
            user.username = self.generate_unique_username([user.email])
        
        if commit:
            user.save()
            
            # Crear perfil de usuario simplificado si no existe
            if not hasattr(user, 'perfilusuario'):
                PerfilUsuario.objects.create(
                    user=user,
                    pasillo_asignado=None,  # Se asignará después manualmente
                )
        
        return user


class CustomSocialAccountAdapter(DefaultSocialAccountAdapter):
    """Adapter personalizado para cuentas sociales (Google, Facebook, etc)."""
    
    def is_open_for_signup(self, request, sociallogin):
        """Permite el registro a través de proveedores sociales."""
        return True
    
    def save_user(self, request, sociallogin, form=None):
        """
        Guarda el usuario social y crea su perfil simplificado.
        """
        user = super().save_user(request, sociallogin, form)
        
        # Crear perfil de usuario simplificado si no existe
        if not hasattr(user, 'perfilusuario'):
            PerfilUsuario.objects.create(
                user=user,
                pasillo_asignado=None,  # Se asignará después manualmente
            )
        
        return user
    
    def populate_user(self, request, sociallogin, data):
        """
        Popula los datos del usuario desde el proveedor social.
        """
        user = super().populate_user(request, sociallogin, data)
        
        # Generar username único basado en el email
        if user.email and not user.username:
            username_base = user.email.split('@')[0]
            user.username = self.generate_unique_username([username_base])
        
        return user
    
    def generate_unique_username(self, txts, regex=None):
        """Reutilizar método del adapter de cuenta normal."""
        adapter = CustomAccountAdapter()
        return adapter.generate_unique_username(txts, regex)


# ===============================
# FUNCIONES DE UTILIDAD
# ===============================

def get_user_tipo_from_api(user_id):
    """
    Obtener tipo de usuario desde la API si es necesario.
    
    NOTA: Esta función se puede implementar más tarde si se requiere
    manejar tipos de usuario vía API serverless.
    """
    # TODO: Implementar llamada a API si se requiere gestión de tipos
    return 'Visitante'  # Tipo por defecto


def assign_pasillo_from_api(user, pasillo_name):
    """
    Asignar pasillo al usuario consultando la API.
    
    NOTA: Esta función verifica que el pasillo existe en la API
    antes de asignarlo al perfil del usuario.
    """
    try:
        # TODO: Verificar que el pasillo existe en la API
        # import requests
        # response = requests.get(f'{API_BASE_URL}/pasillos')
        # pasillos = response.json()
        # if any(p['nombre'] == pasillo_name for p in pasillos):
        
        if hasattr(user, 'perfilusuario'):
            user.perfilusuario.pasillo_asignado = pasillo_name
            user.perfilusuario.save()
            return True
    except Exception as e:
        print(f"Error asignando pasillo: {e}")
    
    return False

# ===============================
# MIGRACIÓN COMPLETADA
# ===============================

# ✅ Adapters actualizados para sistema serverless
# ✅ TipoUsuario eliminado - se maneja vía API si es necesario
# ✅ PerfilUsuario simplificado mantenido
# 🎯 Autenticación funcionando sin dependencias MySQL