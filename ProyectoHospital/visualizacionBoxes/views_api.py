"""
Vista híbrida para integrar la API serverless con Django.

Esta vista utiliza la API serverless de DynamoDB como fuente de datos
manteniendo la interfaz de usuario de Django.
"""

from django.shortcuts import render
from django.http import JsonResponse
from datetime import datetime
import requests
import json
from django.conf import settings


def visualizacion_api(request):
    """
    Vista que utiliza la API serverless para obtener datos de boxes.
    """
    # Obtener fecha del request o usar actual
    fecha_str = request.GET.get('fecha', datetime.now().strftime('%Y-%m-%d'))
    
    try:
        # Obtener datos de la API serverless
        boxes_response = requests.get(f"{settings.SERVERLESS_API_URL}/boxes")
        pasillos_response = requests.get(f"{settings.SERVERLESS_API_URL}/pasillos")
        agendas_response = requests.get(f"{settings.SERVERLESS_API_URL}/agendas", 
                                     params={'fecha': fecha_str})
        
        if boxes_response.status_code == 200:
            boxes = boxes_response.json()
        else:
            boxes = []
            
        if pasillos_response.status_code == 200:
            pasillos = pasillos_response.json()
        else:
            pasillos = []
            
        if agendas_response.status_code == 200:
            agendas = agendas_response.json()
        else:
            agendas = []
            
        # Crear contexto similar al original
        context = {
            'boxes': boxes,
            'pasillos': pasillos,
            'agendas': agendas,
            'fecha': fecha_str,
            'usando_api': True,  # Flag para identificar en el template
        }
        
        return render(request, 'visualizacionBoxes/visualizacion_api.html', context)
        
    except requests.exceptions.RequestException as e:
        # Si hay error con la API, mostrar mensaje de error
        context = {
            'error': f'Error conectando con la API: {str(e)}',
            'boxes': [],
            'pasillos': [],
            'agendas': [],
            'fecha': fecha_str,
        }
        return render(request, 'visualizacionBoxes/visualizacion_api.html', context)


def api_test_view(request):
    """
    Vista para probar la conectividad con la API.
    """
    try:
        # Probar cada endpoint
        endpoints = {
            'boxes': f"{settings.SERVERLESS_API_URL}/boxes",
            'pasillos': f"{settings.SERVERLESS_API_URL}/pasillos", 
            'agendas': f"{settings.SERVERLESS_API_URL}/agendas",
        }
        
        results = {}
        for name, url in endpoints.items():
            try:
                response = requests.get(url, timeout=10)
                results[name] = {
                    'status': response.status_code,
                    'ok': response.status_code == 200,
                    'data_count': len(response.json()) if response.status_code == 200 else 0
                }
            except Exception as e:
                results[name] = {
                    'status': 'ERROR',
                    'ok': False,
                    'error': str(e)
                }
        
        return JsonResponse({
            'api_url': settings.SERVERLESS_API_URL,
            'endpoints': results,
            'all_ok': all(r['ok'] for r in results.values())
        })
        
    except Exception as e:
        return JsonResponse({
            'error': str(e),
            'all_ok': False
        })