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
# ADMIN DESHABILITADO - USANDO API
# ===============================

# Los siguientes admins ya no se usan porque el sistema
# ahora maneja datos desde DynamoDB vía API Serverless:
# - PasilloAdmin → API: /pasillos  
# - BoxAdmin → API: /boxes
# - EspecialidadAdmin → API: /especialidades
# - ProfesionalAdmin → API: /profesionales  
# - AgendaAdmin → API: /agendas
# - TipoAgendaAdmin → API: /tipos-agenda

# ===============================
# ADMIN PARA AUTENTICACIÓN (CONSERVADO)
# ===============================


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
    list_display = ('idbox', 'get_pasillo', 'capacidad')
    list_filter = ('idpasillo',)
    search_fields = ('idbox', 'idpasillo__pasillo')
    ordering = ('idbox',)
    
    def get_pasillo(self, obj):
        """Mostrar el nombre del pasillo."""
        return obj.idpasillo.pasillo
    get_pasillo.short_description = 'Pasillo'
    get_pasillo.admin_order_field = 'idpasillo__pasillo'


@admin.register(Agenda)
class AgendaAdmin(admin.ModelAdmin):
    """Configuración del admin para Agenda."""
    list_display = (
        'idagenda', 'get_box', 'get_tipo_agenda', 
        'get_profesional', 'fecha', 'horainicio', 'horafin'
    )
    list_filter = (
        'idtipoagenda', 'fecha', 'idbox__idpasillo',
        'idprofesional__idespecialidad'
    )
    search_fields = (
        'idbox__idbox', 'idprofesional__nombre',
        'idtipoagenda__tipoagenda', 'observaciones'
    )
    ordering = ('-fecha', 'horainicio')
    date_hierarchy = 'fecha'
    
    def get_box(self, obj):
        """Mostrar información del box."""
        return f"Box {obj.idbox.idbox} - {obj.idbox.idpasillo.pasillo}"
    get_box.short_description = 'Box'
    get_box.admin_order_field = 'idbox__idbox'
    
    def get_tipo_agenda(self, obj):
        """Mostrar el tipo de agenda."""
        return obj.idtipoagenda.tipoagenda
    get_tipo_agenda.short_description = 'Tipo de Agenda'
    get_tipo_agenda.admin_order_field = 'idtipoagenda__tipoagenda'
    
    def get_profesional(self, obj):
        """Mostrar el profesional asignado."""
        if obj.idprofesional:
            return f"{obj.idprofesional.nombre} ({obj.idprofesional.idespecialidad.especialidad})"
        return "Sin asignar"
    get_profesional.short_description = 'Profesional'
    get_profesional.admin_order_field = 'idprofesional__nombre'
    
    def get_queryset(self, request):
        """Optimizar consultas con select_related."""
        qs = super().get_queryset(request)
        return qs.select_related(
            'idbox', 'idprofesional', 'idtipoagenda', 
            'idprofesional__idespecialidad', 'idbox__idpasillo'
        )


# ===============================
# ADMINISTRACIÓN DE TIPOS DE USUARIO
# ===============================

@admin.register(TipoUsuario)
class TipoUsuarioAdmin(admin.ModelAdmin):
    """Admin para los tipos de usuario del sistema."""
    list_display = ('nombre', 'descripcion_corta', 'activo', 'fecha_creacion', 'get_usuarios_count')
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
    
    def descripcion_corta(self, obj):
        """Muestra una versión corta de la descripción."""
        return obj.descripcion[:50] + '...' if len(obj.descripcion) > 50 else obj.descripcion
    descripcion_corta.short_description = 'Descripción'
    
    def get_usuarios_count(self, obj):
        """Muestra la cantidad de usuarios de este tipo."""
        return obj.perfilusuario_set.count()
    get_usuarios_count.short_description = 'Usuarios'


@admin.register(PerfilUsuario)
class PerfilUsuarioAdmin(admin.ModelAdmin):
    """Admin para los perfiles de usuario."""
    list_display = ('get_nombre_completo', 'get_email', 'tipo_usuario', 'pasillo_asignado', 'activo', 'fecha_creacion')
    list_filter = ('tipo_usuario', 'pasillo_asignado', 'activo', 'fecha_creacion')
    search_fields = ('usuario__username', 'usuario__first_name', 'usuario__last_name', 'usuario__email', 'telefono')
    ordering = ('-fecha_creacion',)
    readonly_fields = ('fecha_creacion', 'fecha_modificacion')
    
    fieldsets = (
        ('Usuario Django', {
            'fields': ('usuario',)
        }),
        ('Perfil Hospital', {
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


# ===============================
# ADMINISTRACIÓN DE USUARIOS CON PERFIL INLINE
# ===============================

# Inline para PerfilUsuario en User
class PerfilUsuarioInline(admin.StackedInline):
    model = PerfilUsuario
    extra = 0
    can_delete = False
    verbose_name = "Perfil del Hospital"
    verbose_name_plural = "Perfil del Hospital"
    
    fieldsets = (
        ('Información del Hospital', {
            'fields': ('tipo_usuario', 'pasillo_asignado', 'telefono', 'activo'),
            'description': 'Configuración específica del hospital para este usuario.'
        }),
    )

# Admin personalizado para User que incluye PerfilUsuario
class UserAdminCustom(BaseUserAdmin):
    inlines = (PerfilUsuarioInline,)
    
    # Agregar campos del perfil a la vista de lista
    list_display = BaseUserAdmin.list_display + ('get_tipo_usuario', 'get_pasillo_asignado', 'get_activo')
    list_filter = BaseUserAdmin.list_filter + ('perfilusuario__tipo_usuario', 'perfilusuario__pasillo_asignado', 'perfilusuario__activo')
    
    def get_tipo_usuario(self, obj):
        try:
            return obj.perfilusuario.tipo_usuario.nombre
        except PerfilUsuario.DoesNotExist:
            return "Sin perfil"
    get_tipo_usuario.short_description = 'Tipo de Usuario'
    
    def get_pasillo_asignado(self, obj):
        try:
            return obj.perfilusuario.pasillo_asignado.nombre if obj.perfilusuario.pasillo_asignado else "Sin asignar"
        except PerfilUsuario.DoesNotExist:
            return "Sin perfil"
    get_pasillo_asignado.short_description = 'Pasillo'
    
    def get_activo(self, obj):
        try:
            return "✓" if obj.perfilusuario.activo else "✗"
        except PerfilUsuario.DoesNotExist:
            return "Sin perfil"
    get_activo.short_description = 'Activo'

# Re-registrar el admin de User con configuración personalizada
admin.site.unregister(User)
admin.site.register(User, UserAdminCustom)


# Personalizar títulos del admin
admin.site.site_header = "Administración del Hospital"
admin.site.site_title = "Admin Hospital"
admin.site.index_title = "Panel de Administración"
