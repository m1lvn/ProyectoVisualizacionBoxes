"""
URL configuration for ProyectoHospital project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from django.shortcuts import redirect

def root_redirect(request):
    """Redirigir la URL raíz a login si no está autenticado, sino al dashboard"""
    if request.session.get('jwt_token'):
        return redirect('visualizacionBoxes:visualizacion_general')
    else:
        return redirect('auth:login')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('accounts/', include('allauth.urls')),  # URLs de autenticación (legacy)
    path('auth/', include('visualizacionBoxes.auth_urls')),  # Nueva autenticación Cognito
    path('dashboard/', include('visualizacionBoxes.urls')),  # Dashboard protegido
    path('', root_redirect, name='root'),  # Redirigir URL raíz
]
