"""
Configuración del panel de administración de Django.

Este módulo registra y configura los modelos para su gestión
a través del panel de administración de Django.
"""

from django.contrib import admin
from .models import Box, Agenda, Tipoagenda, Pasillo, Especialidad, Profesional


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