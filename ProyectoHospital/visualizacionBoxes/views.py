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

# Paginación
BOXES_POR_PAGINA = 40


def get_api_data(endpoint, params=None, request=None):
    """
    Helper function to get data from API with JWT authentication
    """
    try:
        url = f"{API_BASE_URL}/{endpoint}"
        print(f"DEBUG - Calling API: {url} with params: {params}")
        
        # Preparar headers con JWT token si está disponible
        headers = {'Content-Type': 'application/json'}
        if request and request.session.get('jwt_token'):
            headers['Authorization'] = f"Bearer {request.session.get('jwt_token')}"
        
        response = requests.get(url, params=params, headers=headers, timeout=10)
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
        'page_obj': boxes_pagina,  # Necesario para la paginación
        'paginator': paginator,     # Necesario para la paginación
        'is_paginated': boxes_pagina.has_other_pages(),  # Necesario para mostrar controles
        'pasillos': pasillos,  # API ya envía campos correctos
        'fecha': fecha_str,
        'fecha_seleccionada': fecha,
        'pasillo_seleccionado': pasillo_id,  # Agregar para que funcione el filtro
        'nombre_medico': nombre_medico,  # Agregar para que funcione el filtro
        'codigo_box': codigo_box,  # Agregar para que funcione el filtro
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
    Vista de visualización por pasillo usando API - Con paginación restaurada
    """
    # Obtener parámetros de filtros y paginación
    pasillo_id = request.GET.get('pasillo')
    fecha_str = request.GET.get('fecha', datetime.now().strftime('%Y-%m-%d'))
    nombre_medico = request.GET.get('medico', '')
    codigo_box = request.GET.get('box', '')
    jornada_seleccionada = request.GET.get('jornada', '')
    page = request.GET.get('page', 1)
    
    print(f"DEBUG - Filtros pasillo: pasillo_id={pasillo_id}, medico={nombre_medico}, box={codigo_box}, jornada={jornada_seleccionada}")
    
    # Obtener datos de la API
    boxes = get_api_data('boxes', request=request)
    pasillos = get_api_data('pasillos', request=request)
    agendas = get_api_data('agendas', {'fecha': fecha_str}, request=request)
    
    # Aplicar filtros
    boxes_filtrados = boxes
    
    # Filtro por pasillo
    if pasillo_id:
        boxes_filtrados = [box for box in boxes_filtrados if str(box.get('idPasillo', '')) == str(pasillo_id)]
    
    # Filtro por profesional
    if nombre_medico:
        agendas_medico = [agenda for agenda in agendas if nombre_medico.lower() in agenda.get('profesional', '').lower()]
        box_ids_medico = [str(agenda.get('idBox')) for agenda in agendas_medico]
        boxes_filtrados = [box for box in boxes_filtrados if str(box.get('idBox')) in box_ids_medico]
    
    # Filtro por código de box
    if codigo_box:
        boxes_filtrados = [box for box in boxes_filtrados if codigo_box.lower() in str(box.get('idBox', '')).lower()]
    
    # Filtro por jornada
    if jornada_seleccionada:
        # Filtrar agendas por jornada y luego boxes por esas agendas
        if jornada_seleccionada == 'AM':
            # AM: 08:00 - 11:59
            agendas_jornada = [agenda for agenda in agendas 
                             if agenda.get('horaInicio', '00:00') >= '08:00' and agenda.get('horaInicio', '00:00') < '12:00']
        elif jornada_seleccionada == 'PM':
            # PM: 12:00 - 19:59
            agendas_jornada = [agenda for agenda in agendas 
                             if agenda.get('horaInicio', '00:00') >= '12:00' and agenda.get('horaInicio', '00:00') < '20:00']
        else:
            agendas_jornada = agendas
        
        # Obtener boxes que tienen agendas en la jornada seleccionada
        if agendas_jornada:
            box_ids_jornada = list(set([str(agenda.get('idBox')) for agenda in agendas_jornada]))
            boxes_filtrados = [box for box in boxes_filtrados if str(box.get('idBox')) in box_ids_jornada]
        else:
            # Si no hay agendas en esa jornada, mostrar boxes vacíos (para permitir agendamiento)
            pass
    
    # Calcular estados para todos los boxes filtrados
    hora_actual = datetime.now().time()
    fecha = datetime.strptime(fecha_str, '%Y-%m-%d').date()
    
    for box in boxes_filtrados:
        box_id = box.get('idBox')
        box['estado_actual'] = calcular_estado_box(box_id, agendas, hora_actual, fecha)
        box['agenda_actual'] = obtener_agenda_actual(box_id, agendas, hora_actual, fecha)
        
        # DEBUG: Mostrar estados para algunos boxes
        if box_id in [175, 1, 2] or box['estado_actual'] == 'ocupado':  
            print(f"DEBUG PASILLO - Box {box_id}: estado='{box['estado_actual']}', agenda={box['agenda_actual']}")
    
    # ===============================
    # GENERAR HORAS PARA LA MATRIZ (como el sistema original)
    # ===============================
    # Generar bloques de horario cada 30 minutos de 8:00 a 20:00
    horas_bloque = []
    hora_inicio = time(8, 0)  # 8:00 AM
    hora_fin = time(20, 0)    # 8:00 PM
    
    current_time = datetime.combine(fecha, hora_inicio)
    end_time = datetime.combine(fecha, hora_fin)
    
    while current_time <= end_time:
        horas_bloque.append(current_time.strftime('%H:%M'))
        current_time += timedelta(minutes=30)
    
    # ===============================
    # GENERAR DATOS ESPECÍFICOS POR HORA PARA LA MATRIZ
    # ===============================
    # Crear diccionarios para estados y agendas por box+hora
    estados_por_box_hora = {}
    agendas_por_box_hora = {}
    
    for box in boxes_filtrados:
        box_id = box.get('idBox')
        for hora in horas_bloque:
            key = f"{box_id}-{hora}"
            estados_por_box_hora[key] = calcular_estado_box_en_hora_especifica(box_id, agendas, hora, fecha)
            agendas_por_box_hora[key] = obtener_agenda_en_hora_especifica(box_id, agendas, hora, fecha)
    
    # Debug: Mostrar algunos estados específicos
    print(f"DEBUG PASILLO - Estados por hora para Box 1:")
    for hora in horas_bloque[:5]:  # Solo primeras 5 horas
        key = f"1-{hora}"
        estado = estados_por_box_hora.get(key, 'disponible')
        agenda = agendas_por_box_hora.get(key)
        print(f"  {hora}: {estado} - {agenda.get('profesional') if agenda else 'Sin agenda'}")
    
    # ===============================
    # PAGINACIÓN (8 boxes por página para pasillo)
    # ===============================
    BOXES_POR_PAGINA_PASILLO = 8
    paginator = Paginator(boxes_filtrados, BOXES_POR_PAGINA_PASILLO)
    
    try:
        boxes_pagina = paginator.page(page)
    except PageNotAnInteger:
        boxes_pagina = paginator.page(1)
    except EmptyPage:
        boxes_pagina = paginator.page(paginator.num_pages)
    
    # Obtener información del pasillo específico si hay filtro
    pasillo_info = None
    if pasillo_id:
        pasillo_info = next((p for p in pasillos if str(p.get('idPasillo', '')) == str(pasillo_id)), None)
    
    context = {
        'boxes': boxes_pagina,  # Usar boxes paginados
        'horas_bloque': horas_bloque,  # Horarios para la matriz
        'estados_por_box_hora': estados_por_box_hora,  # Estados específicos por celda
        'agendas_por_box_hora': agendas_por_box_hora,  # Agendas específicas por celda
        'page_obj': boxes_pagina,  # Necesario para la paginación
        'paginator': paginator,     # Necesario para la paginación
        'is_paginated': boxes_pagina.has_other_pages(),  # Necesario para mostrar controles
        'pasillo_info': pasillo_info,
        'pasillos': pasillos,
        'fecha': fecha_str,
        'fecha_seleccionada': fecha,
        'pasillo_seleccionado': pasillo_id,
        'nombre_medico': nombre_medico,
        'codigo_box': codigo_box,
        'jornada_seleccionada': jornada_seleccionada,
        'filtros': {
            'pasillo': pasillo_id,
            'medico': nombre_medico,
            'box': codigo_box,
            'jornada': jornada_seleccionada
        },
        'usando_api': True,
        # Estadísticas con datos totales (no paginados)
        'estadisticas': {
            'total_boxes': len(boxes_filtrados),
            'boxes_disponibles': len([b for b in boxes_filtrados if b.get('estado_actual') == 'disponible']),
            'boxes_ocupados': len([b for b in boxes_filtrados if b.get('estado_actual') == 'ocupado']),
            'total_agendas': len(agendas),
        },
    }
    
    return render(request, 'visualizacionBoxes/visualizacion_pasillo.html', context)


def obtener_detalle_box(request):
    """
    API AJAX para obtener detalles de un box específico en un bloque horario específico
    """
    box_id = request.GET.get('box_id')
    fecha_str = request.GET.get('fecha', datetime.now().strftime('%Y-%m-%d'))
    hora_str = request.GET.get('hora')  # Nuevo parámetro de hora específica
    
    if not box_id:
        return JsonResponse({'error': 'Box ID requerido'}, status=400)
    
    # Obtener datos de la API
    boxes = get_api_data('boxes')
    agendas = get_api_data('agendas', {'fecha': fecha_str})
    
    # Encontrar el box
    box = next((b for b in boxes if str(b.get('idBox', '')) == str(box_id)), None)
    
    if not box:
        return JsonResponse({'error': 'Box no encontrado'}, status=404)
    
    # Obtener agendas del box para la fecha
    agendas_box = [agenda for agenda in agendas if str(agenda.get('idBox', '')) == str(box_id)]
    
    # Si se especifica una hora, usar esa hora, sino usar la hora actual
    if hora_str:
        # Validar formato de hora
        try:
            datetime.strptime(hora_str, '%H:%M')  # Solo validar, no convertir
            hora_especifica = hora_str
        except ValueError:
            return JsonResponse({'error': 'Formato de hora inválido. Use HH:MM'}, status=400)
    else:
        hora_especifica = datetime.now().strftime('%H:%M')  # Convertir a string
    
    fecha = datetime.strptime(fecha_str, '%Y-%m-%d').date()
    
    # Calcular estado específico para esa hora
    estado_hora = calcular_estado_box_en_hora_especifica(box_id, agendas, hora_especifica, fecha)
    agenda_hora = obtener_agenda_en_hora_especifica(box_id, agendas, hora_especifica, fecha)
    
    # Preparar respuesta en formato que espera el JavaScript
    response_data = {
        'box': {
            'id': box.get('idBox'),
            'pasillo': box.get('pasillo', ''),
            'capacidad': box.get('capacidad', ''),
            'disponible': box.get('disponible', True)
        },
        'disponible': estado_hora == 'disponible',
        'fecha': fecha_str,
        'hora': hora_especifica,  # Usar la hora procesada (string)
        'bloque_horario': f"{hora_especifica} - Box {box_id}",
    }
    
    # Si hay agenda en esa hora específica, agregar sus datos
    if agenda_hora and estado_hora == 'ocupado':
        response_data['agenda'] = {
            'profesional': agenda_hora.get('profesional', 'No especificado'),
            'especialidad': agenda_hora.get('especialidad', 'No especificada'), 
            'tipo_agenda': agenda_hora.get('tipoAgenda', 'No especificado'),
            'hora_inicio': agenda_hora.get('horaInicio', ''),
            'hora_fin': agenda_hora.get('horaFin', ''),
            'observaciones': agenda_hora.get('observaciones', ''),
        }
        response_data['mensaje'] = f"Box ocupado en el horario {agenda_hora.get('horaInicio', '')} - {agenda_hora.get('horaFin', '')}"
    else:
        response_data['mensaje'] = f"Box disponible en el horario {hora_especifica}"
    
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
    Vista de reportes usando API - Solo para Admins y Personal Administrativo
    """
    print("=== DEBUG REPORTES ===")
    print(f"JWT Token: {bool(request.session.get('jwt_token'))}")
    print(f"User Groups: {request.session.get('user_groups', [])}")
    print(f"User Email: {request.session.get('user_email')}")
    
    # Verificar permisos JWT
    if not request.session.get('jwt_token'):
        print("ERROR: No JWT token found")
        messages.error(request, 'Acceso no autorizado. Debe iniciar sesión.')
        return redirect('auth:login')
    
    user_groups = request.session.get('user_groups', [])
    print(f"Checking permissions for groups: {user_groups}")
    
    if 'Admin' not in user_groups and 'PersonalAdministrativo' not in user_groups:
        print("ERROR: User does not have required permissions")
        messages.error(request, 'No tiene permisos para acceder a los reportes.')
        return redirect('visualizacionBoxes:visualizacion_general')
    
    print("SUCCESS: User has access to reports")
    fecha_inicio = request.GET.get('fecha_inicio', datetime.now().strftime('%Y-%m-%d'))
    fecha_fin = request.GET.get('fecha_fin', datetime.now().strftime('%Y-%m-%d'))
    
    # Obtener datos de la API
    boxes = get_api_data('boxes', request=request)
    pasillos = get_api_data('pasillos', request=request)
    agendas = get_api_data('agendas', {'fecha': fecha_inicio}, request=request)  # Por simplicidad, una fecha
    
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
        'user_groups': user_groups,  # Para uso en el template
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

def calcular_estado_box_en_hora_especifica(box_id, agendas, hora_especifica, fecha):
    """
    Calcular el estado de un box en una hora específica de la matriz
    """
    fecha_str = fecha.strftime('%Y-%m-%d')
    agendas_box_hoy = [
        agenda for agenda in agendas 
        if str(agenda.get('idBox', '')) == str(box_id) and agenda.get('fecha') == fecha_str
    ]
    
    # Convertir hora específica a objeto time
    try:
        hora_especifica_obj = datetime.strptime(hora_especifica, '%H:%M').time()
    except ValueError:
        return 'disponible'
    
    for agenda in agendas_box_hoy:
        try:
            hora_inicio = datetime.strptime(agenda.get('horaInicio', ''), '%H:%M').time()
            hora_fin = datetime.strptime(agenda.get('horaFin', ''), '%H:%M').time()
            
            # Verificar si la hora específica está dentro del rango de la agenda
            if hora_inicio <= hora_especifica_obj < hora_fin:  # < para que no incluya el final
                return 'ocupado'
        except ValueError:
            continue
    
    return 'disponible'


def obtener_agenda_en_hora_especifica(box_id, agendas, hora_especifica, fecha):
    """
    Obtener la agenda específica de un box en una hora determinada
    """
    fecha_str = fecha.strftime('%Y-%m-%d')
    agendas_box_hoy = [
        agenda for agenda in agendas 
        if str(agenda.get('idBox', '')) == str(box_id) and agenda.get('fecha') == fecha_str
    ]
    
    # Convertir hora específica a objeto time
    try:
        hora_especifica_obj = datetime.strptime(hora_especifica, '%H:%M').time()
    except ValueError:
        return None
    
    for agenda in agendas_box_hoy:
        try:
            hora_inicio = datetime.strptime(agenda.get('horaInicio', ''), '%H:%M').time()
            hora_fin = datetime.strptime(agenda.get('horaFin', ''), '%H:%M').time()
            
            # Verificar si la hora específica está dentro del rango de la agenda
            if hora_inicio <= hora_especifica_obj < hora_fin:
                return agenda
        except ValueError:
            continue
    
    return None


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