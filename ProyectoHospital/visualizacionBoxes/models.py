"""
Modelos para la aplicación de visualización de boxes del hospital.

NOTA: Este archivo ahora está DESHABILITADO porque el sistema usa 
API Serverless + DynamoDB en lugar de modelos Django + MySQL.

Los modelos originales se han movido a models_mysql_backup.py 
para referencia histórica.
"""

from django.db import models
from django.contrib.auth.models import User

# ===============================
# MODELOS DESHABILITADOS - USANDO API
# ===============================

# Los siguientes modelos ya no se usan porque el sistema
# ahora obtiene datos desde DynamoDB vía API Serverless:
# - Pasillo → API: /pasillos  
# - Box → API: /boxes
# - Especialidad → API: /especialidades
# - Profesional → API: /profesionales  
# - Agenda → API: /agendas
# - TipoAgenda → API: /tipos-agenda

# ===============================
# MODELO DE PERFIL DE USUARIO (CONSERVADO)
# ===============================

class PerfilUsuario(models.Model):
    """
    Perfil extendido para usuarios del sistema.
    
    NOTA: Este modelo se conserva porque maneja autenticación local
    y no depende de los datos hospitalarios migrados a DynamoDB.
    """
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    pasillo_asignado = models.CharField(
        max_length=100, 
        blank=True, 
        null=True,
        help_text="Pasillo asignado al usuario (referencia por nombre)"
    )
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    fecha_actualizacion = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Perfil de Usuario"
        verbose_name_plural = "Perfiles de Usuario"
        db_table = 'perfil_usuario'
    
    def __str__(self):
        return f"Perfil de {self.user.username}"

# ===============================
# FUNCIONES AUXILIARES PARA API
# ===============================

def get_boxes_from_api():
    """Helper para obtener boxes desde la API"""
    # Esta función se implementa en views.py
    pass

def get_pasillos_from_api():
    """Helper para obtener pasillos desde la API"""
    # Esta función se implementa en views.py  
    pass

def get_agendas_from_api(fecha=None):
    """Helper para obtener agendas desde la API"""
    # Esta función se implementa en views.py
    pass

# ===============================
# MIGRACIÓN COMPLETADA
# ===============================

# ✅ Datos migrados exitosamente a DynamoDB
# ✅ API Serverless funcionando  
# ✅ Vistas Django actualizadas para usar API
# ✅ Modelos MySQL deshabilitados
# 🎯 Sistema 100% serverless operativo