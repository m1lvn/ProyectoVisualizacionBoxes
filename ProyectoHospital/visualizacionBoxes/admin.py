"""
Configuración del panel de administración de Django.

Este módulo registra y configura los modelos para su gestión
a través del panel de administración de Django.
"""

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import User
from .models import (
    Box, Agenda, Tipoagenda, Pasillo, Especialidad, Profesional,
    TipoUsuario, PerfilUsuario
)


@admin.register(Pasillo)
class PasilloAdmin(admin.ModelAdmin):
    """Configuración del admin para Pasillo."""
    list_display = ('idpasillo', 'pasillo')
    search_fields = ('pasillo',)
    ordering = ('pasillo',)


@admin.register(Especialidad)
class EspecialidadAdmin(admin.ModelAdmin):
    """Configuración del admin para Especialidad."""
    list_display = ('idespecialidad', 'especialidad')
    search_fields = ('especialidad',)
    ordering = ('especialidad',)


@admin.register(Profesional)
class ProfesionalAdmin(admin.ModelAdmin):
    """Configuración del admin para Profesional."""
    list_display = ('idprofesional', 'nombre', 'idespecialidad')
    list_filter = ('idespecialidad',)
    search_fields = ('nombre', 'idespecialidad__especialidad')
    ordering = ('nombre',)


@admin.register(Tipoagenda)
class TipoagendaAdmin(admin.ModelAdmin):
    """Configuración del admin para Tipo de Agenda."""
    list_display = ('idtipoagenda', 'tipoagenda')
    search_fields = ('tipoagenda',)
    ordering = ('tipoagenda',)


@admin.register(Box)
class BoxAdmin(admin.ModelAdmin):
    """Configuración del admin para Box."""
    list_display = ('idbox', 'idpasillo', 'capacidad')
    list_filter = ('idpasillo',)
    search_fields = ('idbox', 'idpasillo__pasillo')
    ordering = ('idbox',)


@admin.register(Agenda)
class AgendaAdmin(admin.ModelAdmin):
    """Configuración del admin para Agenda."""
    list_display = (
        'idagenda', 'idbox', 'idprofesional', 'idtipoagenda', 
        'fecha', 'horainicio', 'horafin'
    )
    list_filter = (
        'fecha', 'idtipoagenda', 'idprofesional__idespecialidad', 
        'idbox__idpasillo'
    )
    search_fields = (
        'idbox__idbox', 'idprofesional__nombre', 
        'idtipoagenda__tipoagenda'
    )
    date_hierarchy = 'fecha'
    ordering = ('-fecha', 'horainicio', 'idbox')
    
    fieldsets = (
        ('Información Básica', {
            'fields': ('idtipoagenda', 'idprofesional', 'idbox')
        }),
        ('Fecha y Horario', {
            'fields': ('fecha', 'horainicio', 'horafin')
        }),
    )
    
    def get_queryset(self, request):
        """Optimizar consultas con select_related."""
        qs = super().get_queryset(request)
        return qs.select_related(
            'idbox', 'idprofesional', 'idtipoagenda', 
            'idprofesional__idespecialidad', 'idbox__idpasillo'
        )


# ===============================
# ADMINISTRACIÓN DE USUARIOS Y PERFILES
# ===============================

@admin.register(TipoUsuario)
class TipoUsuarioAdmin(admin.ModelAdmin):
    """Configuración del admin para TipoUsuario."""
    list_display = ('nombre', 'descripcion', 'activo', 'fecha_creacion')
    list_filter = ('activo', 'fecha_creacion')
    search_fields = ('nombre', 'descripcion')
    ordering = ('nombre',)
    readonly_fields = ('fecha_creacion', 'fecha_modificacion')
    
    fieldsets = (
        ('Información Básica', {
            'fields': ('nombre', 'descripcion', 'activo')
        }),
        ('Fechas', {
            'fields': ('fecha_creacion', 'fecha_modificacion'),
            'classes': ('collapse',)
        }),
    )


class PerfilUsuarioInline(admin.StackedInline):
    """Inline para mostrar el perfil de usuario en el admin de User."""
    model = PerfilUsuario
    can_delete = False
    verbose_name_plural = 'Perfil de Usuario'
    
    fields = ('tipo_usuario', 'activo', 'telefono', 'ultimo_acceso')
    readonly_fields = ('fecha_creacion', 'fecha_modificacion', 'ultimo_acceso')


@admin.register(PerfilUsuario)
class PerfilUsuarioAdmin(admin.ModelAdmin):
    """Configuración del admin para PerfilUsuario."""
    list_display = (
        'get_nombre_completo', 'get_email', 'tipo_usuario', 
        'pasillo_asignado', 'activo', 'ultimo_acceso', 'fecha_creacion'
    )
    list_display_links = ('get_nombre_completo', 'get_email')  # Hacer clickeable el email
    list_filter = ('tipo_usuario', 'pasillo_asignado', 'activo', 'fecha_creacion')
    search_fields = (
        'usuario__username', 'usuario__email', 
        'usuario__first_name', 'usuario__last_name', 'telefono'
    )
    ordering = ('-fecha_creacion',)
    readonly_fields = ('fecha_creacion', 'fecha_modificacion')
    
    fieldsets = (
        ('Usuario', {
            'fields': ('usuario',)
        }),
        ('Perfil y Permisos', {
            'fields': ('tipo_usuario', 'pasillo_asignado', 'activo', 'telefono'),
            'description': 'El campo "Pasillo asignado" solo es necesario para Personal Médico.'
        }),
        ('Fechas', {
            'fields': ('fecha_creacion', 'fecha_modificacion', 'ultimo_acceso'),
            'classes': ('collapse',)
        }),
    )
    
    def get_nombre_completo(self, obj):
        """Obtener nombre completo del usuario."""
        return obj.nombre_completo
    get_nombre_completo.short_description = 'Nombre Completo'
    get_nombre_completo.admin_order_field = 'usuario__first_name'
    
    def get_email(self, obj):
        """Obtener email del usuario."""
        return obj.usuario.email
    get_email.short_description = 'Email'
    get_email.admin_order_field = 'usuario__email'
    
    def get_queryset(self, request):
        """Optimizar consultas con select_related."""
        qs = super().get_queryset(request)
        return qs.select_related('usuario', 'tipo_usuario')


# Extender el admin de User para incluir el perfil
class UserAdmin(BaseUserAdmin):
    """Admin personalizado para User que incluye el perfil."""
    inlines = (PerfilUsuarioInline,)
    
    def get_inline_instances(self, request, obj=None):
        """Solo mostrar inline si el usuario ya existe."""
        if not obj:
            return list()
        return super().get_inline_instances(request, obj)


# Re-registrar el admin de User
admin.site.unregister(User)
admin.site.register(User, UserAdmin)