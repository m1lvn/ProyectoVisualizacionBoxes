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
API_BASE_URL = getattr(settings, 'SERVERLESS_API_URL', 'https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api')


def get_api_data(endpoint, params=None):
    """
    Helper function to get data from API with error handling
    """
    try:
        url = f"{API_BASE_URL}/{endpoint}"
        print(f"DEBUG - Calling API: {url} with params: {params}")
        response = requests.get(url, params=params, timeout=10)
        print(f"DEBUG - API Response status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"DEBUG - API Response type: {type(data)}")
            
            # La API devuelve {success: true, data: [...]}
            # Necesitamos extraer solo la lista de 'data'
            if isinstance(data, dict) and 'data' in data:
                actual_data = data['data']
                print(f"DEBUG - Extracted data type: {type(actual_data)}, count: {len(actual_data) if isinstance(actual_data, list) else 'N/A'}")
                return actual_data
            else:
                print(f"DEBUG - Unexpected API response format: {str(data)[:200]}...")
                return []
        else:
            print(f"API Error: {response.status_code} - {endpoint}")
            print(f"Response text: {response.text[:200]}...")
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
    
    # Debug: Verificar formato de datos
    print(f"DEBUG - Final boxes type: {type(boxes)}, count: {len(boxes) if boxes else 0}")
    if boxes and len(boxes) > 0:
        print(f"DEBUG - First box: {boxes[0] if isinstance(boxes, list) else 'Not a list'}")
    
    print(f"DEBUG - Agendas count: {len(agendas) if agendas else 0}")
    if agendas:
        print(f"DEBUG - Primera agenda: {agendas[0]}")
        print(f"DEBUG - Fecha actual: {fecha_str}, Hora actual: {hora_actual}")
    
    # Verificar que boxes sea una lista
    if not isinstance(boxes, list):
        print(f"ERROR - boxes no es lista después del procesamiento: {type(boxes)}")
        boxes = []
    
    # ===============================
    # APLICAR FILTROS A BOXES
    # ===============================
    if pasillo_id:
        boxes = [box for box in boxes if str(box.get('idPasillo', '')) == str(pasillo_id)]
    
    if codigo_box:
        boxes = [box for box in boxes if codigo_box.lower() in str(box.get('idBox', '')).lower()]
    
    if nombre_medico:
        # Filtrar por médico en agendas
        agendas_medico = [agenda for agenda in agendas 
                         if nombre_medico.lower() in agenda.get('profesional', '').lower()]
        if agendas_medico:
            box_ids_medico = list(set([agenda['idBox'] for agenda in agendas_medico]))
            boxes = [box for box in boxes if box.get('idBox') in box_ids_medico]
        else:
            boxes = []
    
    # ===============================
    # CALCULAR ESTADO DE BOXES
    # ===============================
    for box in boxes:
        try:
            if isinstance(box, dict):
                box_id = box.get('idBox')  # MySQL original: 'idBox'
                if box_id:
                    box['estado_actual'] = calcular_estado_box(box_id, agendas, hora_actual, fecha)
                    box['agenda_actual'] = obtener_agenda_actual(box_id, agendas, hora_actual, fecha)
                    
                    # DEBUG: Mostrar algunos boxes con estado
                    if box_id in [175, 1, 2]:  # Algunos boxes específicos
                        print(f"DEBUG - Box {box_id}: estado='{box['estado_actual']}', agenda={box['agenda_actual']}")
                else:
                    print(f"WARNING - Box sin idBox: {box}")
                    box['estado_actual'] = 'disponible'
                    box['agenda_actual'] = None
            else:
                print(f"ERROR - Box no es diccionario: {type(box)} - {box}")
        except Exception as e:
            print(f"ERROR procesando box: {e}")
            if isinstance(box, dict):
                box['estado_actual'] = 'disponible'  
                box['agenda_actual'] = None
    
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
    # PROCESAR PASILLOS PARA TEMPLATE
    # ===============================
    # Ya no necesitamos mapear campos porque API los envía correctos
    print(f"DEBUG - Pasillos count: {len(pasillos)}")
    if pasillos:
        print(f"DEBUG - Primer pasillo: {pasillos[0]}")
    
    # ===============================
    # PREPARAR CONTEXTO
    # ===============================
    context = {
        'boxes': boxes_pagina,
        'pasillos': pasillos,  # API ya envía campos correctos
        'fecha': fecha_str,
        'fecha_seleccionada': fecha,
        'pasillo_seleccionado': pasillo_id,  # Agregar para que funcione el filtro
        'nombre_medico': nombre_medico,  # Agregar para que funcione el filtro
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
    Vista de visualización por pasillo usando API - Funciona igual que antes de la migración
    """
    pasillo_id = request.GET.get('pasillo')  # Solo de filtros superiores
    fecha_str = request.GET.get('fecha', datetime.now().strftime('%Y-%m-%d'))
    
    # Obtener datos de la API
    boxes = get_api_data('boxes')
    pasillos = get_api_data('pasillos')
    agendas = get_api_data('agendas', {'fecha': fecha_str})
    
    # Si hay filtro de pasillo, filtrar boxes
    if pasillo_id:
        boxes_pasillo = [box for box in boxes if str(box.get('idPasillo', '')) == str(pasillo_id)]
        # Obtener información del pasillo específico
        pasillo_info = next((p for p in pasillos if str(p.get('idPasillo', '')) == str(pasillo_id)), None)
    else:
        # Sin filtro: mostrar todos los boxes
        boxes_pasillo = boxes
        pasillo_info = None
    
    # Calcular estados para todos los boxes
    hora_actual = datetime.now().time()
    fecha = datetime.strptime(fecha_str, '%Y-%m-%d').date()
    
    for box in boxes_pasillo:
        box_id = box.get('idBox')
        box['estado_actual'] = calcular_estado_box(box_id, agendas, hora_actual, fecha)
        box['agenda_actual'] = obtener_agenda_actual(box_id, agendas, hora_actual, fecha)
    
    context = {
        'boxes': boxes_pasillo,
        'pasillo_info': pasillo_info,
        'pasillos': pasillos,
        'fecha': fecha_str,
        'fecha_seleccionada': fecha,
        'pasillo_seleccionado': pasillo_id,  # Para que funcione el filtro superior
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
    box = next((b for b in boxes if str(b.get('idBox', '')) == str(box_id)), None)
    
    if not box:
        return JsonResponse({'error': 'Box no encontrado'}, status=404)

    # API ya envía campos correctos, no necesitamos mapear
    
    # Obtener agendas del box para la fecha
    agendas_box = [agenda for agenda in agendas if str(agenda.get('idBox', '')) == str(box_id)]
    
    # Verificar si el box está disponible
    hora_actual = datetime.now().time()
    fecha = datetime.strptime(fecha_str, '%Y-%m-%d').date()
    estado = calcular_estado_box(box_id, agendas, hora_actual, fecha)
    agenda_actual = obtener_agenda_actual(box_id, agendas, hora_actual, fecha)
    
    # Preparar respuesta en formato que espera el JavaScript
    response_data = {
        'box': {
            'id': box.get('idBox'),
            'pasillo': box.get('pasillo', ''),
            'capacidad': box.get('capacidad', ''),
            'disponible': box.get('disponible', True)
        },
        'disponible': estado == 'disponible',
        'fecha': fecha_str,
    }
    
    # Si hay agenda actual, agregar sus datos
    if agenda_actual and estado == 'ocupado':
        response_data['agenda'] = {
            'profesional': agenda_actual.get('profesional', 'No especificado'),
            'especialidad': agenda_actual.get('especialidad', 'No especificada'), 
            'tipo_agenda': agenda_actual.get('tipoAgenda', 'No especificado'),
            'hora_inicio': agenda_actual.get('horaInicio', ''),
            'hora_fin': agenda_actual.get('horaFin', ''),
            'observaciones': agenda_actual.get('observaciones', ''),
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
        if str(agenda.get('idBox', '')) == str(box_id) and agenda.get('fecha') == fecha_str
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
        if str(agenda.get('idBox', '')) == str(box_id) and agenda.get('fecha') == fecha_str
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


def dashboard_usuario(request):
    """
    Dashboard simplificado para usuarios - Redirige a vista principal
    """
    return redirect('visualizacionBoxes:visualizacion_general')


def redirect_after_login(request):
    """
    Redirección después del login - Redirige al dashboard
    """
    return redirect('visualizacionBoxes:visualizacion_general')