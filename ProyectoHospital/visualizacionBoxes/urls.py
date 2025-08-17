"""
URLs para la aplicación de visualización de boxes.

Este módulo define las rutas de la aplicación para acceder a las diferentes
vistas de visualización y gestión de boxes del hospital.
"""

from django.urls import path
from . import views

app_name = 'visualizacionBoxes'

urlpatterns = [
    # Vista principal - Visualización general de boxes
    path('', views.visualizacion_general, name='visualizacion_general'),
    
    # Vista de visualización por pasillo - NUEVA
    path('pasillo/', views.visualizacion_pasillo, name='visualizacion_pasillo'),
    
    # Vista de reportes
    path('reportes/', views.reportes, name='reportes'),
    
    # API AJAX - Obtener detalles de un box específico
    path('detalle-box/', views.obtener_detalle_box, name='detalle_box'),
    
    # API AJAX - Buscar médicos por nombre
    path('buscar-medicos/', views.buscar_medicos, name='buscar_medicos'),
    
    # URLs de autenticación y perfil de usuario
    path('perfil/', views.perfil_usuario, name='perfil_usuario'),
    path('dashboard/', views.dashboard_usuario, name='dashboard_usuario'),
    path('redirect-after-login/', views.redirect_after_login, name='redirect_after_login'),
    
    # API AJAX - Crear nueva agenda
    path('crear-agenda/', views.crear_agenda, name='crear_agenda'),
]
