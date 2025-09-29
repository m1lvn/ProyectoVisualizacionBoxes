"""
Configuración del panel de administración de Django.

NOTA: Este módulo ahora está SIMPLIFICADO porque el sistema usa 
API Serverless + DynamoDB en lugar de modelos Django + MySQL.

Solo se mantiene el admin para PerfilUsuario (autenticación local).
"""

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import User
from .models import PerfilUsuario

# ===============================
# ADMIN PARA AUTENTICACIÓN (CONSERVADO)
# ===============================

@admin.register(PerfilUsuario)
class PerfilUsuarioAdmin(admin.ModelAdmin):
    """Configuración del admin para PerfilUsuario."""
    list_display = ('user', 'pasillo_asignado', 'fecha_creacion')
    list_filter = ('pasillo_asignado', 'fecha_creacion')
    search_fields = ('user__username', 'user__first_name', 'user__last_name', 'pasillo_asignado')
    readonly_fields = ('fecha_creacion', 'fecha_actualizacion')
    
    fieldsets = (
        ('Información de Usuario', {
            'fields': ('user',)
        }),
        ('Configuración Hospital', {
            'fields': ('pasillo_asignado',)
        }),
        ('Fechas', {
            'fields': ('fecha_creacion', 'fecha_actualizacion'),
            'classes': ('collapse',)
        }),
    )


# Extender UserAdmin para incluir perfil
class UserAdmin(BaseUserAdmin):
    """Admin personalizado para Usuario con perfil."""
    list_display = BaseUserAdmin.list_display + ('get_pasillo_asignado',)
    list_filter = BaseUserAdmin.list_filter + ('perfilusuario__pasillo_asignado',)
    
    def get_pasillo_asignado(self, obj):
        """Obtener pasillo asignado del perfil."""
        if hasattr(obj, 'perfilusuario'):
            return obj.perfilusuario.pasillo_asignado or 'Sin asignar'
        return 'Sin perfil'
    get_pasillo_asignado.short_description = 'Pasillo Asignado'


# Re-registrar User con el admin personalizado
admin.site.unregister(User)
admin.site.register(User, UserAdmin)


# ===============================
# INFORMACIÓN DEL ADMIN PANEL
# ===============================

admin.site.site_header = "Hospital Boxes - Admin Serverless"
admin.site.site_title = "Hospital Admin"
admin.site.index_title = "Administración del Sistema"

# ===============================
# ADMIN DESHABILITADO - USANDO API
# ===============================

# Los siguientes admins ya no se usan porque el sistema
# ahora maneja datos desde DynamoDB vía API Serverless:

# @admin.register(Pasillo) - Datos en DynamoDB
# @admin.register(Box) - Datos en DynamoDB  
# @admin.register(Especialidad) - Datos en DynamoDB
# @admin.register(Profesional) - Datos en DynamoDB
# @admin.register(Agenda) - Datos en DynamoDB
# @admin.register(TipoAgenda) - Datos en DynamoDB
# @admin.register(TipoUsuario) - Datos en DynamoDB

# NOTA: Para gestionar estos datos, usar:
# 1. API Endpoints directamente
# 2. Scripts de migración  
# 3. AWS Console DynamoDB
# 4. Vistas personalizadas en Django

# ===============================
# URLS API PARA GESTIÓN DE DATOS
# ===============================

# Boxes: https://55omss5p3c.execute-api.us-east-1.amazonaws.com/dev/api/boxes
# Pasillos: https://55omss5p3c.execute-api.us-east-1.amazonaws.com/dev/api/pasillos
# Agendas: https://55omss5p3c.execute-api.us-east-1.amazonaws.com/dev/api/agendas