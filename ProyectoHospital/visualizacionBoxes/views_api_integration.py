# Ejemplo de vista Django actualizada para usar la API Serverless
# Agregar esto al archivo views.py

from django.shortcuts import render
from datetime import datetime
from .api_client import api_client

def visualizacion_api_test(request):
    """
    Vista de prueba para la nueva API Serverless
    """
    # Obtener datos desde la API en lugar de MySQL
    pasillos_response = api_client.get_pasillos()
    boxes_response = api_client.get_boxes()
    agendas_response = api_client.get_agendas()
    
    context = {
        'pasillos_data': pasillos_response,
        'boxes_data': boxes_response, 
        'agendas_data': agendas_response,
        'api_working': all([
            pasillos_response.get('success', False),
            boxes_response.get('success', False),
            agendas_response.get('success', False)
        ])
    }
    
    return render(request, 'visualizacionBoxes/api_test.html', context)

def visualizacion_general_api(request):
    """
    Nueva versión de visualización general usando API Serverless
    """
    # Obtener filtros
    fecha = request.GET.get('fecha', datetime.now().strftime('%Y-%m-%d'))
    pasillo_filtro = request.GET.get('pasillo', None)
    
    # Llamar a la API Serverless
    pasillos_response = api_client.get_pasillos()
    
    if pasillo_filtro:
        boxes_response = api_client.get_boxes(pasillo=pasillo_filtro)
    else:
        boxes_response = api_client.get_boxes()
    
    agendas_response = api_client.get_agendas(fecha=fecha)
    
    # Procesar datos para el template
    pasillos = pasillos_response.get('data', []) if pasillos_response.get('success') else []
    boxes = boxes_response.get('data', []) if boxes_response.get('success') else []
    agendas = agendas_response.get('data', []) if agendas_response.get('success') else []
    
    context = {
        'pasillos': pasillos,
        'boxes': boxes,
        'agendas': agendas,
        'fecha': fecha,
        'pasillo_filtro': pasillo_filtro,
        'api_working': pasillos_response.get('success', False)
    }
    
    return render(request, 'visualizacionBoxes/visualizacion_general.html', context)