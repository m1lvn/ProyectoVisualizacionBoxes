"""
URLs para la aplicación de visualización de boxes.

Este módulo define las rutas de la aplicación para acceder a las diferentes
vistas de visualización y gestión de boxes del hospital usando API Serverless.
"""

from django.urls import path
from . import views

app_name = 'visualizacionBoxes'

urlpatterns = [
    # Vista principal - Visualización general de boxes (API Serverless)
    path('', views.visualizacion_general, name='visualizacion_general'),
    
    # Vista de visualización por pasillo  
    path('pasillo/', views.visualizacion_pasillo, name='visualizacion_pasillo'),
    
    # Vista de reportes
    path('reportes/', views.reportes, name='reportes'),
    
    # URLs de autenticación y perfil de usuario
    path('perfil/', views.perfil_usuario, name='perfil_usuario'),
    path('dashboard/', views.dashboard_usuario, name='dashboard_usuario'),
    path('redirect-after-login/', views.redirect_after_login, name='redirect_after_login'),
    
    # Crear nueva agenda
    path('crear-agenda/', views.crear_agenda, name='crear_agenda'),
    
    # API AJAX - Obtener detalles de un box específico
    path('detalle-box/', views.obtener_detalle_box, name='detalle_box'),
    
    # API AJAX - Buscar médicos por nombre
    path('buscar-medicos/', views.buscar_medicos, name='buscar_medicos'),
    
    # Test API connectivity  
    path('test-api/', views.test_api, name='test_api'),
]

# ===============================
# URLS DESHABILITADAS - SISTEMA ANTERIOR
# ===============================

# Las siguientes URLs ya no se usan porque el sistema
# ahora obtiene datos desde DynamoDB vía API Serverless:

# path('api/', views_api.visualizacion_api, name='visualizacion_api'),
# path('api/test/', views_api.api_test_view, name='api_test'),

# NOTA: Todas las vistas principales ahora usan la API serverless por defecto
# No hay necesidad de URLs separadas para "API" vs "MySQL"