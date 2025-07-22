"""
Vistas para la aplicación de visualización de boxes del hospital.

Este módulo contiene las vistas principales para mostrar el estado
de los boxes del hospital en tiempo real.
"""

from django.shortcuts import render, get_object_or_404
from django.http import JsonResponse
from django.db.models import Q
from django.core.paginator import Paginator, EmptyPage, PageNotAnInteger
from datetime import datetime, time, timedelta

from .models import (
    Box, Agenda, Tipoagenda, Pasillo, Especialidad, Profesional
)


def visualizacion_general(request):
    """
    Vista principal para mostrar la visualización general de boxes.
    
    Muestra el estado actual de todos los boxes basado en la hora actual
    y permite filtrar por fecha, pasillo, especialidad, médico y box específico.
    
    Parámetros GET:
    - fecha: Fecha en formato YYYY-MM-DD (por defecto: fecha actual)
    - pasillo: ID del pasillo a filtrar
    - medico: ID del profesional para filtrar
    - box: Código del box para filtrar
    
    Returns:
        HttpResponse: Template con matriz de boxes y sus estados actuales
    """
    # Obtener parámetros de filtros desde la URL
    fecha_str = request.GET.get('fecha', datetime.now().strftime('%Y-%m-%d'))
    pasillo_id = request.GET.get('pasillo', None)
    codigo_medico = request.GET.get('medico', None)
    codigo_box = request.GET.get('box', None)
    
    # Validar y parsear la fecha
    try:
        fecha = datetime.strptime(fecha_str, '%Y-%m-%d').date()
    except ValueError:
        fecha = datetime.now().date()
    
    # Obtener hora actual
    hora_actual = datetime.now().time()
    
    # Aplicar filtros a los boxes
    boxes = Box.objects.all().order_by('idbox')
    if pasillo_id:
        boxes = boxes.filter(idpasillo=pasillo_id)
    if codigo_box:
        boxes = boxes.filter(idbox__icontains=codigo_box)
    
    # Obtener datos para filtros
    pasillos = Pasillo.objects.all().order_by('pasillo')
    especialidades = Especialidad.objects.all().order_by('especialidad')
    tipos_agenda = Tipoagenda.objects.all().order_by('tipoagenda')
    
    # Obtener agendas del día
    agendas = Agenda.objects.filter(fecha=fecha)
    if codigo_medico:
        # Buscar por idprofesional en la tabla Agenda
        agendas = agendas.filter(idprofesional=codigo_medico)
        # Si hay código médico, filtrar boxes solo a aquellos que tienen agendas de ese médico
        if agendas.exists():
            boxes_con_medico = agendas.values_list('idbox', flat=True).distinct()
            boxes = boxes.filter(idbox__in=boxes_con_medico)
        else:
            # Si no hay agendas para ese médico, no mostrar ningún box
            boxes = Box.objects.none()
    
    # Crear estado actual de cada box
    estado_boxes = _crear_estado_actual_boxes(boxes, hora_actual, agendas)
    
    context = {
        'boxes': boxes,
        'fecha': fecha,
        'hora_actual': hora_actual,
        'pasillos': pasillos,
        'especialidades': especialidades,
        'tipos_agenda': tipos_agenda,
        'pasillo_seleccionado': pasillo_id,
        'codigo_medico': codigo_medico,
        'codigo_box': codigo_box,
        'estado_boxes': estado_boxes,
    }
    
    return render(request, 'visualizacionBoxes/visualizacionGeneral.html', context)


def obtener_detalle_box(request):
    """
    Vista AJAX para obtener detalles de un box en el estado actual.
    
    Parámetros GET requeridos:
    - box_id: ID del box a consultar
    - fecha: Fecha en formato YYYY-MM-DD (opcional, por defecto: fecha actual)
    
    Returns:
        JsonResponse: Datos del box incluyendo estado, agenda y profesional asignado
    """
    if request.method != 'GET':
        return JsonResponse({'error': 'Método no permitido'}, status=405)
    
    box_id = request.GET.get('box_id')
    fecha_str = request.GET.get('fecha', datetime.now().strftime('%Y-%m-%d'))
    
    if not box_id:
        return JsonResponse({'error': 'ID del box requerido'}, status=400)
    
    try:
        fecha = datetime.strptime(fecha_str, '%Y-%m-%d').date()
        hora_actual = datetime.now().time()
        box = get_object_or_404(Box, idbox=box_id)
        
        # Buscar agenda activa en este momento
        agenda = Agenda.objects.filter(
            idbox=box,
            fecha=fecha,
            horainicio__lte=hora_actual,
            horafin__gt=hora_actual
        ).first()
        
        box_data = {
            'id': box.idbox,
            'pasillo': box.idpasillo.pasillo,
            'capacidad': box.capacidad
        }
        
        if agenda:
            data = {
                'disponible': False,
                'box': box_data,
                'agenda': {
                    'profesional': agenda.idprofesional.nombre,
                    'especialidad': agenda.idprofesional.idespecialidad.especialidad,
                    'tipo_agenda': agenda.idtipoagenda.tipoagenda,
                    'hora_inicio': agenda.horainicio.strftime('%H:%M'),
                    'hora_fin': agenda.horafin.strftime('%H:%M')
                }
            }
        else:
            data = {
                'disponible': True,
                'box': box_data,
                'agenda': None
            }
        
        return JsonResponse(data)
        
    except ValueError:
        return JsonResponse({'error': 'Formato de fecha inválido'}, status=400)
    except Exception as e:
        return JsonResponse({'error': f'Error interno: {str(e)}'}, status=500)


def visualizacion_pasillo(request):
    """
    Vista para mostrar la visualización de boxes por pasillo específico.
    
    Muestra una matriz de horarios vs boxes para un pasillo determinado,
    permitiendo ver la ocupación de boxes a lo largo del día.
    Incluye paginación (8 boxes por página) y filtros consistentes.
    
    Parámetros GET:
    - pasillo: ID del pasillo a visualizar
    - fecha: Fecha en formato YYYY-MM-DD (por defecto: fecha actual)
    - jornada: 'AM', 'PM' o vacío para horario completo
    - medico: ID del profesional para filtrar
    - box: Código del box para filtrar
    - page: Número de página para paginación
    
    Returns:
        HttpResponse: Template con datos de boxes, horarios y paginación
    """
    # ===============================
    # PARÁMETROS DE FILTROS
    # ===============================
    filtros = {
        'pasillo': request.GET.get('pasillo', None),
        'fecha': request.GET.get('fecha', datetime.now().strftime('%Y-%m-%d')),
        'jornada': request.GET.get('jornada', ''),  # AM, PM, o vacío para FULL TIME
        'medico': request.GET.get('medico', None),
        'box': request.GET.get('box', None),
        'page': request.GET.get('page', 1)
    }
    
    # Constantes
    BOXES_POR_PAGINA = 8
    
    # ===============================
    # VALIDACIÓN Y PROCESAMIENTO
    # ===============================
    # Validar y parsear la fecha
    try:
        fecha_procesada = datetime.strptime(filtros['fecha'], '%Y-%m-%d').date()
    except ValueError:
        fecha_procesada = datetime.now().date()
    
    hora_actual = datetime.now().time()
    
    # ===============================
    # OBTENER DATOS BASE
    # ===============================
    pasillos = Pasillo.objects.all().order_by('pasillo')
    
    # ===============================
    # APLICAR FILTROS A BOXES
    # ===============================
    boxes = _obtener_boxes_filtrados(filtros['pasillo'], filtros['box'])
    
    # ===============================
    # FILTRAR POR MÉDICO
    # ===============================
    if filtros['medico']:
        boxes = _aplicar_filtro_medico(boxes, filtros['medico'], fecha_procesada)
    
    # ===============================
    # PAGINACIÓN
    # ===============================
    paginator = Paginator(boxes, BOXES_POR_PAGINA)
    
    try:
        boxes_page = paginator.page(filtros['page'])
    except PageNotAnInteger:
        boxes_page = paginator.page(1)
    except EmptyPage:
        boxes_page = paginator.page(paginator.num_pages)
    
    boxes_list = list(boxes_page)
    
    # ===============================
    # GENERAR HORARIOS Y ESTADO
    # ===============================
    horas = _generar_horarios_por_jornada(filtros['jornada'])
    estado_datos = _generar_estado_boxes_pasillo(boxes_list, fecha_procesada, horas, filtros['medico'])
    
    # ===============================
    # CONTEXTO DE RESPUESTA
    # ===============================
    pasillo_actual = None
    if filtros['pasillo']:
        try:
            pasillo_actual = Pasillo.objects.get(idpasillo=filtros['pasillo'])
        except Pasillo.DoesNotExist:
            pasillo_actual = None
    
    context = {
        'boxes': boxes_list,
        'horas': horas,
        'fecha': fecha_procesada,
        'hora_actual': hora_actual,
        'pasillos': pasillos,
        'pasillo_seleccionado': filtros['pasillo'],
        'pasillo_actual': pasillo_actual,
        'jornada_seleccionada': filtros['jornada'],
        'codigo_medico': filtros['medico'],
        'codigo_box': filtros['box'],
        'estado_por_box_y_hora': estado_datos['estado'],
        'info_por_box_y_hora': estado_datos['info'],
        # Datos de paginación
        'boxes_page': boxes_page,
        'paginator': paginator,
        'page_obj': boxes_page,
        'is_paginated': paginator.num_pages > 1,
        'page_range': paginator.get_elided_page_range(boxes_page.number),
    }
    
    return render(request, 'visualizacionBoxes/visualizacionPasillo.html', context)


# ==================== FUNCIONES AUXILIARES ====================

def _crear_estado_actual_boxes(boxes, hora_actual, agendas):
    """
    Crea el estado actual de cada box basado en la hora actual.
    
    Args:
        boxes: QuerySet de boxes a evaluar
        hora_actual: Hora actual (time object)
        agendas: QuerySet de agendas del día
        
    Returns:
        dict: Estado de cada box con su disponibilidad y datos de agenda
    """
    estado = {}
    
    for box in boxes:
        # Verificar si hay agenda activa en la hora actual para ese box
        agenda_activa = agendas.filter(
            idbox=box,
            horainicio__lte=hora_actual,
            horafin__gt=hora_actual
        ).first()
        
        if agenda_activa:
            estado[box.idbox] = {
                'disponible': False,
                'tipo_agenda': agenda_activa.idtipoagenda.tipoagenda,
                'tipo_agenda_id': agenda_activa.idtipoagenda.idtipoagenda,
                'profesional': agenda_activa.idprofesional.nombre,
                'especialidad': agenda_activa.idprofesional.idespecialidad.especialidad,
                'hora_inicio': agenda_activa.horainicio,
                'hora_fin': agenda_activa.horafin
            }
        else:
            estado[box.idbox] = {
                'disponible': True,
                'tipo_agenda': None,
                'tipo_agenda_id': None,
                'profesional': None,
                'especialidad': None,
                'hora_inicio': None,
                'hora_fin': None
            }
    
    return estado


def _generar_horarios_por_jornada(jornada=''):
    """
    Genera lista de horarios según la jornada seleccionada.
    
    Args:
        jornada: 'AM', 'PM', o vacío para FULL TIME
        
    Returns:
        list: Lista de horarios en formato 'HH:MM'
    """
    if jornada == 'AM':
        # Horario matutino: 00:00 - 11:59
        hora_inicio = time(0, 0)
        hora_fin = time(12, 0)
    elif jornada == 'PM':
        # Horario vespertino: 12:00 - 23:59
        hora_inicio = time(12, 0)
        hora_fin = time(23, 59)
    else:  # FULL TIME (vacío)
        # Horario completo: 00:00 - 23:59 (24 horas)
        hora_inicio = time(0, 0)
        hora_fin = time(23, 59)
    
    # Generar horarios cada 30 minutos
    horas = []
    current_time = datetime.combine(datetime.today(), hora_inicio)
    end_time = datetime.combine(datetime.today(), hora_fin)
    
    while current_time < end_time:
        horas.append(current_time.strftime('%H:%M'))
        current_time += timedelta(minutes=30)
    
    return horas


def validar_horario_24h(hora_inicio, hora_fin):
    """
    Valida que los horarios sean correctos sin restricciones de rango.
    Permite horarios de 00:00 a 23:59.
    
    Args:
        hora_inicio (time): Hora de inicio
        hora_fin (time): Hora de fin
        
    Returns:
        bool: True si es válido, False en caso contrario
    """
    # Permitir cualquier horario válido de 00:00 a 23:59
    if not isinstance(hora_inicio, time) or not isinstance(hora_fin, time):
        return False
    
    # Solo verificar que la hora de inicio sea menor que la de fin
    return hora_inicio < hora_fin


# ==================== FUNCIONES AUXILIARES PARA VISUALIZACIÓN DE PASILLO ====================

def _obtener_boxes_filtrados(pasillo_id, codigo_box):
    """
    Obtiene boxes filtrados por pasillo y código de box.
    
    Args:
        pasillo_id: ID del pasillo a filtrar (None para todos)
        codigo_box: Código del box a filtrar (None para todos)
        
    Returns:
        QuerySet: Boxes filtrados
    """
    if pasillo_id:
        boxes = Box.objects.filter(idpasillo=pasillo_id).order_by('idbox')
    else:
        boxes = Box.objects.all().order_by('idbox')
    
    if codigo_box:
        boxes = boxes.filter(Q(idbox__icontains=codigo_box) | Q(box__icontains=codigo_box))
    
    return boxes


def _aplicar_filtro_medico(boxes, codigo_medico, fecha):
    """
    Aplica filtro por médico a los boxes.
    
    Args:
        boxes: QuerySet de boxes
        codigo_medico: Código del médico a filtrar
        fecha: Fecha para buscar agendas
        
    Returns:
        QuerySet: Boxes filtrados por médico
    """
    if not codigo_medico:
        return boxes
    
    # Obtener agendas del médico en la fecha especificada
    agendas = Agenda.objects.filter(
        fecha=fecha,
        idprofesional=codigo_medico
    ).select_related('idprofesional', 'idtipoagenda', 'idprofesional__idespecialidad')
    
    if agendas.exists():
        boxes_con_medico = agendas.values_list('idbox', flat=True).distinct()
        return boxes.filter(idbox__in=boxes_con_medico)
    else:
        return Box.objects.none()


def _generar_estado_boxes_pasillo(boxes_list, fecha, horas, codigo_medico):
    """
    Genera el estado de los boxes para la visualización de pasillo.
    
    Args:
        boxes_list: Lista de boxes a procesar
        fecha: Fecha para buscar agendas
        horas: Lista de horas a procesar
        codigo_medico: Código del médico (para optimización)
        
    Returns:
        dict: Diccionario con estado e info de cada box por hora
    """
    # Obtener agendas del día
    agendas = Agenda.objects.filter(
        fecha=fecha
    ).select_related('idprofesional', 'idtipoagenda', 'idprofesional__idespecialidad')
    
    # Aplicar filtro por médico si existe
    if codigo_medico:
        agendas = agendas.filter(idprofesional=codigo_medico)
    
    # Filtrar agendas por los boxes que se van a mostrar
    box_ids = [box.idbox for box in boxes_list]
    agendas = agendas.filter(idbox__in=box_ids)
    
    # Crear diccionario de agendas indexado por box
    agendas_por_box = {}
    for agenda in agendas:
        box_id = agenda.idbox.idbox
        if box_id not in agendas_por_box:
            agendas_por_box[box_id] = []
        agendas_por_box[box_id].append(agenda)
    
    # Crear matrices de estado e información
    estado_por_box_y_hora = {}
    info_por_box_y_hora = {}
    
    for box in boxes_list:
        box_agendas = agendas_por_box.get(box.idbox, [])
        
        for hora in horas:
            key = f"{box.idbox}-{hora}"
            hora_obj = datetime.strptime(hora, '%H:%M').time()
            
            # Buscar agenda activa en este horario
            agenda_en_horario = None
            for agenda in box_agendas:
                if agenda.horainicio <= hora_obj < agenda.horafin:
                    agenda_en_horario = agenda
                    break
            
            if agenda_en_horario:
                # Determinar el tipo de estado basado en el tipo de agenda
                tipo_agenda = agenda_en_horario.idtipoagenda.tipoagenda.lower()
                if 'limpieza' in tipo_agenda:
                    estado_por_box_y_hora[key] = "Limpieza"
                    info_por_box_y_hora[key] = "Limpieza"
                elif 'mantencion' in tipo_agenda or 'mantención' in tipo_agenda:
                    estado_por_box_y_hora[key] = "En mantención"
                    info_por_box_y_hora[key] = "En mantenimiento"
                elif 'inhabilitado' in tipo_agenda:
                    estado_por_box_y_hora[key] = "Inhabilitado"
                    info_por_box_y_hora[key] = "Inhabilitado"
                else:
                    estado_por_box_y_hora[key] = "Reservado"
                    info_por_box_y_hora[key] = agenda_en_horario.idprofesional.idprofesional
            else:
                estado_por_box_y_hora[key] = "Disponible"
                info_por_box_y_hora[key] = ""
    
    return {
        'estado': estado_por_box_y_hora,
        'info': info_por_box_y_hora
    }


# ==================== FUNCIONES AUXILIARES GENERALES ====================
