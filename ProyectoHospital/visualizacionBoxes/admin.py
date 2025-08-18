"""
Configuración del panel de administración de Django.

Este módulo registra y configura los modelos para su gestión
a través del panel de administración de Django.
"""

from django.contrib import admin
from django.contrib.auth.admin import GroupAdmin as BaseGroupAdmin
from django.contrib.auth.models import Group
from .models import (
    Box, Agenda, Tipoagenda, Pasillo, Especialidad, Profesional
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
# ADMINISTRACIÓN DE TIPOS DE USUARIO (GROUPS)
# ===============================

# Configuración personalizada para Groups (Tipos de Usuario)
class GroupAdmin(BaseGroupAdmin):
    """Admin personalizado para Groups con mejor visualización."""
    list_display = ('name', 'get_user_count', 'get_permissions_count')
    search_fields = ('name',)
    ordering = ('name',)
    
    def get_user_count(self, obj):
        """Mostrar cantidad de usuarios en el grupo."""
        return obj.user_set.count()
    get_user_count.short_description = 'Usuarios'
    
    def get_permissions_count(self, obj):
        """Mostrar cantidad de permisos del grupo."""
        return obj.permissions.count()
    get_permissions_count.short_description = 'Permisos'


# Re-registrar el admin de Group con configuración personalizada
admin.site.unregister(Group)
admin.site.register(Group, GroupAdmin)

# Personalizar títulos del admin
admin.site.site_header = "Administración del Hospital"
admin.site.site_title = "Admin Hospital"
admin.site.index_title = "Panel de Administración"
