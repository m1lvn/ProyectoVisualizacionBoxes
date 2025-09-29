"""
Vistas para la aplicación de visualización de boxes del hospital.

Este módulo contiene las vistas principales para mostrar el estado
de los boxes del hospital usando API Serverless + DynamoDB.
"""

from django.shortcuts import render, redirect
from django.http import JsonResponse
from django.core.paginator import Paginator, EmptyPage, PageNotAnInteger
from django.contrib import messages
from datetime import datetime, time, timedelta
import requests
from django.conf import settings

# API Configuration
API_BASE_URL = getattr(settings, 'SERVERLESS_API_URL', 'https://r8qjc8hqrl.execute-api.us-east-1.amazonaws.com/dev/api')
AUTH_BASE_URL = getattr(settings, 'SERVERLESS_AUTH_URL', 'https://utcn9m1wwg.execute-api.us-east-1.amazonaws.com')


def get_api_data(endpoint, params=None):
    """
    Helper function to get data from API with error handling
    """
    try:
        url = f"{API_BASE_URL}/{endpoint}"
        response = requests.get(url, params=params, timeout=10)
        if response.status_code == 200:
            return response.json()
        else:
            print(f"API Error: {response.status_code} - {endpoint}")
            return []
    except requests.exceptions.RequestException as e:
        print(f"API Connection Error: {e}")
        return []


def post_api_data(endpoint, data):
    """
    Helper function to post data to API
    """
    try:
        url = f"{API_BASE_URL}/{endpoint}"
        response = requests.post(url, json=data, timeout=10)
        return response.status_code == 200, response.json() if response.status_code == 200 else None
    except requests.exceptions.RequestException as e:
        print(f"API Post Error: {e}")
        return False, None


def visualizacion_general(request):
    """
    Vista principal usando API Serverless - Sin MySQL
    
    Obtiene datos de boxes, pasillos y agendas desde DynamoDB vía API.
    """
    # ===============================
    # OBTENER PARÁMETROS DE FILTROS
    # ===============================
    fecha_str = request.GET.get('fecha', datetime.now().strftime('%Y-%m-%d'))
    pasillo_id = request.GET.get('pasillo', None)
    nombre_medico = request.GET.get('medico', None)
    codigo_box = request.GET.get('box', None)
    page = request.GET.get('page', 1)
    
    # Constantes
    BOXES_POR_PAGINA = 40
    
    # ===============================
    # VALIDAR Y PROCESAR FECHA
    # ===============================
    try:
        fecha = datetime.strptime(fecha_str, '%Y-%m-%d').date()
    except ValueError:
        fecha = datetime.now().date()
    
    hora_actual = datetime.now().time()
    
    # ===============================
    # OBTENER DATOS DE LA API
    # ===============================
    boxes = get_api_data('boxes')
    pasillos = get_api_data('pasillos')
    agendas = get_api_data('agendas', {'fecha': fecha_str})
    
    # ===============================
    # APLICAR FILTROS A BOXES
    # ===============================
    if pasillo_id:
        boxes = [box for box in boxes if str(box.get('pasilloId', '')) == str(pasillo_id)]
    
    if codigo_box:
        boxes = [box for box in boxes if codigo_box.lower() in str(box.get('boxId', '')).lower()]
    
    if nombre_medico:
        # Filtrar por médico en agendas
        agendas_medico = [agenda for agenda in agendas 
                         if nombre_medico.lower() in agenda.get('profesional', '').lower()]
        if agendas_medico:
            box_ids_medico = list(set([agenda['boxId'] for agenda in agendas_medico]))
            boxes = [box for box in boxes if box.get('boxId') in box_ids_medico]
        else:
            boxes = []
    
    # ===============================
    # CALCULAR ESTADO DE BOXES
    # ===============================
    for box in boxes:
        box_id = box.get('boxId')
        box['estado_actual'] = calcular_estado_box(box_id, agendas, hora_actual, fecha)
        box['agenda_actual'] = obtener_agenda_actual(box_id, agendas, hora_actual, fecha)
    
    # ===============================
    # PAGINACIÓN
    # ===============================
    paginator = Paginator(boxes, BOXES_POR_PAGINA)
    
    try:
        boxes_pagina = paginator.page(page)
    except PageNotAnInteger:
        boxes_pagina = paginator.page(1)
    except EmptyPage:
        boxes_pagina = paginator.page(paginator.num_pages)
    
    # ===============================
    # PREPARAR CONTEXTO
    # ===============================
    context = {
        'boxes': boxes_pagina,
        'pasillos': pasillos,
        'fecha': fecha_str,
        'fecha_seleccionada': fecha,
        'filtros': {
            'pasillo': pasillo_id,
            'medico': nombre_medico,
            'box': codigo_box,
        },
        'estadisticas': {
            'total_boxes': len(boxes),
            'boxes_disponibles': len([b for b in boxes if b.get('estado_actual') == 'disponible']),
            'boxes_ocupados': len([b for b in boxes if b.get('estado_actual') == 'ocupado']),
            'total_agendas': len(agendas),
        },
        'usando_api': True,
    }
    
    return render(request, 'visualizacionBoxes/visualizacion_general.html', context)


def visualizacion_pasillo(request):
    """
    Vista de visualización por pasillo usando API
    """
    pasillo_id = request.GET.get('pasillo')
    fecha_str = request.GET.get('fecha', datetime.now().strftime('%Y-%m-%d'))
    
    if not pasillo_id:
        return redirect('visualizacionBoxes:visualizacion_general')
    
    # Obtener datos de la API
    boxes = get_api_data('boxes')
    pasillos = get_api_data('pasillos')
    agendas = get_api_data('agendas', {'fecha': fecha_str})
    
    # Filtrar boxes del pasillo seleccionado
    boxes_pasillo = [box for box in boxes if str(box.get('pasilloId', '')) == str(pasillo_id)]
    
    # Obtener información del pasillo
    pasillo_info = next((p for p in pasillos if str(p.get('pasilloId', '')) == str(pasillo_id)), None)
    
    # Calcular estados
    hora_actual = datetime.now().time()
    fecha = datetime.strptime(fecha_str, '%Y-%m-%d').date()
    
    for box in boxes_pasillo:
        box_id = box.get('boxId')
        box['estado_actual'] = calcular_estado_box(box_id, agendas, hora_actual, fecha)
        box['agenda_actual'] = obtener_agenda_actual(box_id, agendas, hora_actual, fecha)
    
    context = {
        'boxes': boxes_pasillo,
        'pasillo_info': pasillo_info,
        'pasillos': pasillos,
        'fecha': fecha_str,
        'filtros': {'pasillo': pasillo_id},
        'usando_api': True,
    }
    
    return render(request, 'visualizacionBoxes/visualizacion_pasillo.html', context)


def obtener_detalle_box(request):
    """
    API AJAX para obtener detalles de un box específico
    """
    box_id = request.GET.get('box_id')
    fecha_str = request.GET.get('fecha', datetime.now().strftime('%Y-%m-%d'))
    
    if not box_id:
        return JsonResponse({'error': 'Box ID requerido'}, status=400)
    
    # Obtener datos de la API
    boxes = get_api_data('boxes')
    agendas = get_api_data('agendas', {'fecha': fecha_str})
    
    # Encontrar el box
    box = next((b for b in boxes if str(b.get('boxId', '')) == str(box_id)), None)
    
    if not box:
        return JsonResponse({'error': 'Box no encontrado'}, status=404)
    
    # Obtener agendas del box para la fecha
    agendas_box = [agenda for agenda in agendas if str(agenda.get('boxId', '')) == str(box_id)]
    
    # Preparar respuesta
    response_data = {
        'box': box,
        'agendas': agendas_box,
        'fecha': fecha_str,
    }
    
    return JsonResponse(response_data)


def buscar_medicos(request):
    """
    API AJAX para buscar médicos por nombre
    """
    query = request.GET.get('q', '').strip()
    
    if len(query) < 2:
        return JsonResponse({'medicos': []})
    
    # Obtener agendas para extraer médicos
    agendas = get_api_data('agendas')
    
    # Extraer médicos únicos
    medicos = set()
    for agenda in agendas:
        profesional = agenda.get('profesional', '').strip()
        if profesional and query.lower() in profesional.lower():
            medicos.add(profesional)
    
    medicos_list = [{'nombre': medico} for medico in sorted(medicos)]
    
    return JsonResponse({'medicos': medicos_list})


def reportes(request):
    """
    Vista de reportes usando API
    """
    fecha_inicio = request.GET.get('fecha_inicio', datetime.now().strftime('%Y-%m-%d'))
    fecha_fin = request.GET.get('fecha_fin', datetime.now().strftime('%Y-%m-%d'))
    
    # Obtener datos de la API
    boxes = get_api_data('boxes')
    pasillos = get_api_data('pasillos')
    agendas = get_api_data('agendas', {'fecha': fecha_inicio})  # Por simplicidad, una fecha
    
    # Calcular estadísticas
    estadisticas = {
        'total_boxes': len(boxes),
        'total_pasillos': len(pasillos),
        'total_agendas': len(agendas),
        'ocupacion_promedio': calcular_ocupacion_promedio(boxes, agendas),
    }
    
    context = {
        'estadisticas': estadisticas,
        'boxes': boxes,
        'pasillos': pasillos,
        'fecha_inicio': fecha_inicio,
        'fecha_fin': fecha_fin,
        'usando_api': True,
    }
    
    return render(request, 'visualizacionBoxes/reportes.html', context)


def perfil_usuario(request):
    """
    Vista de perfil de usuario (simplificada sin BD)
    """
    context = {
        'usuario': request.user,
        'usando_api': True,
    }
    return render(request, 'visualizacionBoxes/perfil.html', context)


# ===============================
# FUNCIONES AUXILIARES
# ===============================

def calcular_estado_box(box_id, agendas, hora_actual, fecha):
    """
    Calcular el estado actual de un box basado en las agendas
    """
    fecha_str = fecha.strftime('%Y-%m-%d')
    agendas_box_hoy = [
        agenda for agenda in agendas 
        if str(agenda.get('boxId', '')) == str(box_id) and agenda.get('fecha') == fecha_str
    ]
    
    for agenda in agendas_box_hoy:
        try:
            hora_inicio = datetime.strptime(agenda.get('horaInicio', ''), '%H:%M').time()
            hora_fin = datetime.strptime(agenda.get('horaFin', ''), '%H:%M').time()
            
            if hora_inicio <= hora_actual <= hora_fin:
                return 'ocupado'
        except ValueError:
            continue
    
    return 'disponible'


def obtener_agenda_actual(box_id, agendas, hora_actual, fecha):
    """
    Obtener la agenda actual de un box si está ocupado
    """
    fecha_str = fecha.strftime('%Y-%m-%d')
    agendas_box_hoy = [
        agenda for agenda in agendas 
        if str(agenda.get('boxId', '')) == str(box_id) and agenda.get('fecha') == fecha_str
    ]
    
    for agenda in agendas_box_hoy:
        try:
            hora_inicio = datetime.strptime(agenda.get('horaInicio', ''), '%H:%M').time()
            hora_fin = datetime.strptime(agenda.get('horaFin', ''), '%H:%M').time()
            
            if hora_inicio <= hora_actual <= hora_fin:
                return agenda
        except ValueError:
            continue
    
    return None


def calcular_ocupacion_promedio(boxes, agendas):
    """
    Calcular el porcentaje de ocupación promedio
    """
    if not boxes:
        return 0
    
    total_boxes = len(boxes)
    boxes_con_agenda = len(set([agenda.get('boxId') for agenda in agendas]))
    
    return round((boxes_con_agenda / total_boxes) * 100, 1)


# ===============================
# NUEVAS VISTAS PARA CREAR AGENDAS
# ===============================

def crear_agenda(request):
    """
    Vista para crear una nueva agenda usando la API
    """
    if request.method == 'POST':
        data = {
            'boxId': request.POST.get('boxId'),
            'fecha': request.POST.get('fecha'),
            'horaInicio': request.POST.get('horaInicio'),
            'horaFin': request.POST.get('horaFin'),
            'tipoAgenda': request.POST.get('tipoAgenda', 'Consulta'),
            'profesional': request.POST.get('profesional', ''),
        }
        
        success, result = post_api_data('agendas', data)
        
        if success:
            messages.success(request, '✅ Agenda creada exitosamente')
            return redirect('visualizacionBoxes:visualizacion_general')
        else:
            messages.error(request, '❌ Error al crear agenda')
    
    # GET - Mostrar formulario
    boxes = get_api_data('boxes')
    context = {
        'boxes': boxes,
        'usando_api': True,
    }
    
    return render(request, 'visualizacionBoxes/crear_agenda.html', context)


def test_api(request):
    """
    Vista para probar conectividad con la API
    """
    endpoints = {
        'boxes': get_api_data('boxes'),
        'pasillos': get_api_data('pasillos'),
        'agendas': get_api_data('agendas', {'fecha': datetime.now().strftime('%Y-%m-%d')}),
    }
    
    results = {}
    for name, data in endpoints.items():
        results[name] = {
            'status': 'OK' if data else 'ERROR',
            'count': len(data) if data else 0,
            'sample': data[0] if data else None
        }
    
    return JsonResponse({
        'api_url': API_BASE_URL,
        'endpoints': results,
        'timestamp': datetime.now().isoformat()
    })