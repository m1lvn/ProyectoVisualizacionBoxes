"""
Vistas para la aplicación de visualización de boxes del hospital.

Este módulo contiene las vistas principales para mostrar el estado
de los boxes del hospital en tiempo real.
"""

from django.shortcuts import render, get_object_or_404, redirect
from django.http import JsonResponse
from django.db.models import Q
from django.core.paginator import Paginator, EmptyPage, PageNotAnInteger
from django.contrib import messages
from datetime import datetime, time, timedelta

from .models import (
    Box, Agenda, Tipoagenda, Pasillo, Especialidad, Profesional
)


def visualizacion_general(request):
    """
    Vista principal para mostrar la visualización general de boxes.
    
    Muestra el estado actual de todos los boxes basado en la hora actual
    y permite filtrar por fecha, pasillo, especialidad, médico y box específico.
    Incluye paginación para mejorar el rendimiento.
    
    Parámetros GET:
    - fecha: Fecha en formato YYYY-MM-DD (por defecto: fecha actual)
    - pasillo: ID del pasillo a filtrar
    - medico: ID del profesional para filtrar
    - box: Código del box para filtrar
    - page: Número de página para paginación
    
    Returns:
        HttpResponse: Template con matriz de boxes y sus estados actuales
    """
    # ===============================
    # OBTENER PARÁMETROS DE FILTROS
    # ===============================
    fecha_str = request.GET.get('fecha', datetime.now().strftime('%Y-%m-%d'))
    pasillo_id = request.GET.get('pasillo', None)
    nombre_medico = request.GET.get('medico', None)  # Cambiado de codigo_medico a nombre_medico
    codigo_box = request.GET.get('box', None)
    page = request.GET.get('page', 1)
    
    # Constantes
    BOXES_POR_PAGINA = 40  # Valor optimizado para producción
    
    # ===============================
    # VALIDAR Y PROCESAR FECHA
    # ===============================
    try:
        fecha = datetime.strptime(fecha_str, '%Y-%m-%d').date()
    except ValueError:
        fecha = datetime.now().date()
    
    hora_actual = datetime.now().time()
    
    # ===============================
    # APLICAR FILTROS A BOXES
    # ===============================
    boxes = Box.objects.all().order_by('idbox')
    
    if pasillo_id:
        boxes = boxes.filter(idpasillo=pasillo_id)
    if codigo_box:
        boxes = boxes.filter(idbox__icontains=codigo_box)
    
    # ===============================
    # OBTENER DATOS PARA FILTROS
    # ===============================
    pasillos = Pasillo.objects.all().order_by('pasillo')
    especialidades = Especialidad.objects.all().order_by('especialidad')
    tipos_agenda = Tipoagenda.objects.all().order_by('tipoagenda')
    
    # ===============================
    # OBTENER Y FILTRAR AGENDAS
    # ===============================
    agendas = Agenda.objects.filter(fecha=fecha).select_related('idprofesional', 'idtipoagenda', 'idprofesional__idespecialidad')
    
    if nombre_medico:
        # Buscar médicos que coincidan con el nombre
        medicos_encontrados = Profesional.objects.filter(
            nombre__icontains=nombre_medico
        ).values_list('idprofesional', flat=True)
        
        if medicos_encontrados.exists():
            # Filtrar agendas por los médicos encontrados
            agendas = agendas.filter(idprofesional__in=medicos_encontrados)
            # Si hay nombre médico, filtrar boxes solo a aquellos que tienen agendas de esos médicos
            if agendas.exists():
                boxes_con_medico = agendas.values_list('idbox', flat=True).distinct()
                boxes = boxes.filter(idbox__in=boxes_con_medico)
            else:
                # Si no hay agendas para esos médicos, no mostrar ningún box
                boxes = Box.objects.none()
        else:
            # Si no se encontraron médicos, no mostrar ningún box
            boxes = Box.objects.none()
    
    # ===============================
    # CONFIGURAR PAGINACIÓN
    # ===============================
    paginator = Paginator(boxes, BOXES_POR_PAGINA)
    
    try:
        boxes_page = paginator.page(page)
    except PageNotAnInteger:
        boxes_page = paginator.page(1)
    except EmptyPage:
        boxes_page = paginator.page(paginator.num_pages)
    
    boxes_list = list(boxes_page)
    
    # ===============================
    # GENERAR ESTADO DE BOXES
    # ===============================
    estado_boxes = _crear_estado_actual_boxes(boxes_list, hora_actual, agendas)
    
    # ===============================
    # PREPARAR CONTEXTO DE RESPUESTA
    # ===============================
    context = {
        'boxes': boxes_list,
        'fecha': fecha,
        'hora_actual': hora_actual,
        'pasillos': pasillos,
        'especialidades': especialidades,
        'tipos_agenda': tipos_agenda,
        'pasillo_seleccionado': pasillo_id,
        'nombre_medico': nombre_medico,  # Cambiado de codigo_medico a nombre_medico
        'codigo_box': codigo_box,
        'estado_boxes': estado_boxes,
        # Datos de paginación
        'boxes_page': boxes_page,
        'paginator': paginator,
        'page_obj': boxes_page,
        'is_paginated': paginator.num_pages > 1,
        'page_range': paginator.get_elided_page_range(boxes_page.number),
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
    
    # ===============================
    # VALIDAR PARÁMETROS
    # ===============================
    box_id = request.GET.get('box_id')
    fecha_str = request.GET.get('fecha', datetime.now().strftime('%Y-%m-%d'))
    hora_str = request.GET.get('hora', None)  # Hora específica del bloque clickeado
    
    if not box_id:
        return JsonResponse({'error': 'ID del box requerido'}, status=400)
    
    try:
        # ===============================
        # PROCESAR FECHA Y HORA
        # ===============================
        fecha = datetime.strptime(fecha_str, '%Y-%m-%d').date()
        
        # Si se proporciona una hora específica, usarla; sino usar la hora actual
        if hora_str:
            hora_consulta = datetime.strptime(hora_str, '%H:%M').time()
        else:
            hora_consulta = datetime.now().time()
        
        # ===============================
        # OBTENER BOX
        # ===============================
        box = get_object_or_404(Box, idbox=box_id)
        
        # ===============================
        # BUSCAR AGENDA EN LA HORA ESPECÍFICA
        # ===============================
        agenda = Agenda.objects.filter(
            idbox=box,
            fecha=fecha,
            horainicio__lte=hora_consulta,
            horafin__gt=hora_consulta
        ).first()
        
        # ===============================
        # PREPARAR DATOS DE RESPUESTA
        # ===============================
        box_data = {
            'id': box.idbox,
            'pasillo': box.idpasillo.pasillo,
            'capacidad': box.capacidad
        }
        
        if agenda:
            # Box ocupado
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
            # Box disponible
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
    Incluye paginación optimizada y filtros consistentes.
    
    Parámetros GET:
    - pasillo: ID del pasillo a visualizar
    - fecha: Fecha en formato YYYY-MM-DD (por defecto: fecha actual)
    - jornada: 'AM', 'PM' o vacío para horario completo
    - medico: Nombre del profesional para filtrar
    - box: Código del box para filtrar
    - page: Número de página para paginación
    
    Returns:
        HttpResponse: Template con datos de boxes, horarios y paginación
    """
    # ===============================
    # CONSTANTES Y CONFIGURACIÓN
    # ===============================
    BOXES_POR_PAGINA = 8
    
    # ===============================
    # OBTENER Y VALIDAR PARÁMETROS
    # ===============================
    filtros = {
        'pasillo': request.GET.get('pasillo', None),
        'fecha': request.GET.get('fecha', datetime.now().strftime('%Y-%m-%d')),
        'jornada': request.GET.get('jornada', ''),  # AM, PM, o vacío para FULL TIME
        'medico': request.GET.get('medico', None),
        'box': request.GET.get('box', None),
        'page': request.GET.get('page', 1)
    }
    
    # Validar y procesar fecha
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
    
    # Filtrar por médico si se especifica
    if filtros['medico']:
        boxes = _aplicar_filtro_medico(boxes, filtros['medico'], fecha_procesada)
    
    # ===============================
    # CONFIGURAR PAGINACIÓN
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
    # OBTENER INFORMACIÓN DEL PASILLO
    # ===============================
    pasillo_actual = None
    if filtros['pasillo']:
        try:
            pasillo_actual = Pasillo.objects.get(idpasillo=filtros['pasillo'])
        except Pasillo.DoesNotExist:
            pasillo_actual = None
    
    # ===============================
    # PREPARAR DATOS PARA AGENDAMIENTO
    # ===============================
    # Obtener datos necesarios para el formulario de agendamiento
    todos_boxes = Box.objects.all().order_by('idpasillo__pasillo', 'idbox')
    profesionales = Profesional.objects.all().order_by('nombre')
    tipos_agenda = Tipoagenda.objects.all().order_by('tipoagenda')
    
    # ===============================
    # PREPARAR CONTEXTO DE RESPUESTA
    # ===============================
    context = {
        # Datos principales
        'boxes': boxes_list,
        'horas': horas,
        'fecha': fecha_procesada,
        'hora_actual': hora_actual,
        
        # Datos para filtros
        'pasillos': pasillos,
        'pasillo_seleccionado': filtros['pasillo'],
        'pasillo_actual': pasillo_actual,
        'jornada_seleccionada': filtros['jornada'],
        'nombre_medico': filtros['medico'],
        'codigo_box': filtros['box'],
        
        # Estado de boxes
        'estado_por_box_y_hora': estado_datos['estado'],
        'info_por_box_y_hora': estado_datos['info'],
        
        # Datos de paginación
        'boxes_page': boxes_page,
        'paginator': paginator,
        'page_obj': boxes_page,
        'is_paginated': paginator.num_pages > 1,
        'page_range': paginator.get_elided_page_range(boxes_page.number),
        
        # Datos para agendamiento
        'todos_boxes': todos_boxes,
        'profesionales': profesionales,
        'tipos_agenda': tipos_agenda,
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
            # Box ocupado con agenda activa
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
            # Box disponible
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
    Valida que los horarios sean correctos para horario de 24 horas.
    Permite horarios de 00:00 a 23:59, incluyendo horarios que cruzan medianoche.
    
    Args:
        hora_inicio (time): Hora de inicio
        hora_fin (time): Hora de fin
        
    Returns:
        bool: True si es válido, False en caso contrario
    """
    # Verificar que son objetos time válidos
    if not isinstance(hora_inicio, time) or not isinstance(hora_fin, time):
        return False
    
    # Verificar que las horas están en rango válido (00:00 a 23:59)
    if not (time(0, 0) <= hora_inicio <= time(23, 59)):
        return False
    if not (time(0, 0) <= hora_fin <= time(23, 59)):
        return False
    
    # Permitir horarios que cruzan medianoche o son del mismo día
    # Solo verificar que no sean exactamente iguales
    return hora_inicio != hora_fin


# ==================== FUNCIONES AUXILIARES PARA VISUALIZACIÓN DE PASILLO ====================

def _obtener_boxes_filtrados(pasillo_id, codigo_box):
    """
    Obtiene boxes filtrados por pasillo y código de box.
    
    Args:
        pasillo_id: ID del pasillo a filtrar (None para todos)
        codigo_box: Código del box a filtrar (None para todos)
        
    Returns:
        QuerySet: Boxes filtrados ordenados por ID
    """
    boxes = Box.objects.all().order_by('idbox')
    
    if pasillo_id:
        boxes = boxes.filter(idpasillo=pasillo_id)
    
    if codigo_box:
        boxes = boxes.filter(idbox__icontains=codigo_box)
    
    return boxes


def _aplicar_filtro_medico(boxes, nombre_medico, fecha):
    """
    Aplica filtro por médico a los boxes usando búsqueda por nombre.
    
    Args:
        boxes: QuerySet de boxes
        nombre_medico: Nombre del médico a filtrar (búsqueda parcial)
        fecha: Fecha para buscar agendas
        
    Returns:
        QuerySet: Boxes filtrados por médico o QuerySet vacío si no hay coincidencias
    """
    if not nombre_medico:
        return boxes
    
    # Buscar médicos que coincidan con el nombre
    medicos_encontrados = Profesional.objects.filter(
        nombre__icontains=nombre_medico
    ).values_list('idprofesional', flat=True)
    
    if not medicos_encontrados.exists():
        return Box.objects.none()
    
    # Obtener agendas de los médicos encontrados en la fecha especificada
    agendas = Agenda.objects.filter(
        fecha=fecha,
        idprofesional__in=medicos_encontrados
    ).select_related('idprofesional', 'idtipoagenda', 'idprofesional__idespecialidad')
    
    if agendas.exists():
        boxes_con_medico = agendas.values_list('idbox', flat=True).distinct()
        return boxes.filter(idbox__in=boxes_con_medico)
    else:
        return Box.objects.none()


def _generar_estado_boxes_pasillo(boxes_list, fecha, horas, nombre_medico=None):
    """
    Genera el estado de los boxes para la visualización de pasillo.
    
    Args:
        boxes_list: Lista de boxes a procesar
        fecha: Fecha para buscar agendas
        horas: Lista de horas a procesar
        nombre_medico: Nombre del médico para filtrar (opcional)
        
    Returns:
        dict: Diccionario con 'estado' e 'info' de cada box por hora
    """
    # Obtener agendas del día
    agendas = Agenda.objects.filter(
        fecha=fecha
    ).select_related('idprofesional', 'idtipoagenda', 'idprofesional__idespecialidad')
    
    # Aplicar filtro por médico si existe
    if nombre_medico:
        medicos_encontrados = Profesional.objects.filter(
            nombre__icontains=nombre_medico
        ).values_list('idprofesional', flat=True)
        
        if medicos_encontrados.exists():
            agendas = agendas.filter(idprofesional__in=medicos_encontrados)
        else:
            agendas = Agenda.objects.none()
    
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
                estado_tipo, info_texto = _determinar_estado_agenda(agenda_en_horario)
                estado_por_box_y_hora[key] = estado_tipo
                info_por_box_y_hora[key] = info_texto
            else:
                estado_por_box_y_hora[key] = "Disponible"
                info_por_box_y_hora[key] = ""
    
    return {
        'estado': estado_por_box_y_hora,
        'info': info_por_box_y_hora
    }


def _determinar_estado_agenda(agenda):
    """
    Determina el estado y la información a mostrar basado en el tipo de agenda.
    
    Args:
        agenda: Objeto Agenda con la información de la cita
        
    Returns:
        tuple: (estado, info) donde estado es el tipo y info es el texto a mostrar
    """
    tipo_agenda = agenda.idtipoagenda.tipoagenda.lower()
    
    if 'limpieza' in tipo_agenda:
        return "Limpieza", "Limpieza"
    elif 'mantencion' in tipo_agenda or 'mantención' in tipo_agenda:
        return "En mantención", "En mantenimiento"
    elif 'inhabilitado' in tipo_agenda:
        return "Inhabilitado", "Inhabilitado"
    else:
        return "Reservado", agenda.idprofesional.nombre


# ==================== FUNCIONES AUXILIARES GENERALES ====================


def reportes(request):
    """
    Vista para el módulo de reportes del sistema hospitalario.
    
    Genera reportes detallados sobre ocupación de boxes, profesionales,
    especialidades y tipos de agenda en un rango de fechas específico.
    Soporta vista previa AJAX y descarga en múltiples formatos.
    
    Parámetros POST:
    - fechainicio: Fecha inicio del reporte (formato YYYY-MM-DD)
    - fechafin: Fecha fin del reporte (formato YYYY-MM-DD)
    - pasillo: ID del pasillo ("General" para todos los pasillos)
    - tipo_reporte: Tipo (ocupacion, profesionales, especialidades, tipos_agenda)
    - formato: Formato de salida (csv, excel, pdf)
    - action: Acción (preview, download)
    
    Returns:
        HttpResponse: Template de reportes o archivo de descarga
        JsonResponse: Vista previa en formato AJAX
    """
    # ===============================
    # IMPORTACIONES LOCALIZADAS
    # ===============================
    from django.http import HttpResponse
    from django.db.models import Count, Sum, Avg, F, Case, When, IntegerField
    from django.db.models.functions import Cast
    import csv
    import json
    from datetime import datetime, timedelta
    
    # ===============================
    # OBTENER DATOS BASE
    # ===============================
    pasillos = Pasillo.objects.all().order_by('pasillo')
    
    # ===============================
    # PROCESAR SOLICITUD POST
    # ===============================
    if request.method == 'POST':
        # ===============================
        # OBTENER PARÁMETROS DEL FORM
        # ===============================
        parametros = {
            'fecha_inicio_str': request.POST.get('fechainicio'),
            'fecha_fin_str': request.POST.get('fechafin'),
            'pasillo_id': request.POST.get('pasillo'),
            'tipo_reporte': request.POST.get('tipo_reporte', 'ocupacion'),
            'formato': request.POST.get('formato', 'csv'),
            'action': request.POST.get('action', 'preview')
        }
        
        # ===============================
        # VALIDAR Y PROCESAR FECHAS
        # ===============================
        try:
            fecha_inicio = datetime.strptime(parametros['fecha_inicio_str'], '%Y-%m-%d').date()
            fecha_fin = datetime.strptime(parametros['fecha_fin_str'], '%Y-%m-%d').date()
        except (ValueError, TypeError):
            return JsonResponse({
                'success': False, 
                'message': 'Fechas inválidas. Use formato YYYY-MM-DD.'
            })
        
        if fecha_inicio > fecha_fin:
            return JsonResponse({
                'success': False,
                'message': 'La fecha de inicio no puede ser posterior a la fecha de fin.'
            })
        
        # ===============================
        # CONSTRUIR QUERY BASE
        # ===============================
        agendas_query = Agenda.objects.filter(
            fecha__gte=fecha_inicio,
            fecha__lte=fecha_fin
        ).select_related('idbox', 'idbox__idpasillo', 'idprofesional', 'idtipoagenda')
        
        # Filtrar por pasillo si se especifica
        if parametros['pasillo_id'] and parametros['pasillo_id'] != 'General':
            agendas_query = agendas_query.filter(idbox__idpasillo=parametros['pasillo_id'])
        
        # ===============================
        # GENERAR DATOS DEL REPORTE
        # ===============================
        if parametros['tipo_reporte'] == 'ocupacion':
            datos = _generar_reporte_ocupacion(agendas_query, fecha_inicio, fecha_fin)
        elif parametros['tipo_reporte'] == 'profesionales':
            datos = _generar_reporte_profesionales(agendas_query, fecha_inicio, fecha_fin)
        elif parametros['tipo_reporte'] == 'especialidades':
            datos = _generar_reporte_especialidades(agendas_query, fecha_inicio, fecha_fin)
        elif parametros['tipo_reporte'] == 'tipos_agenda':
            datos = _generar_reporte_tipos_agenda(agendas_query, fecha_inicio, fecha_fin)
        else:
            return JsonResponse({
                'success': False,
                'message': 'Tipo de reporte no válido.'
            })
        
        # ===============================
        # PROCESAR SEGÚN ACCIÓN
        # ===============================
        if parametros['action'] == 'preview':
            if not datos['registros']:
                return JsonResponse({
                    'success': False,
                    'message': 'No se encontraron datos para los filtros seleccionados.'
                })
            
            # Generar HTML para vista previa
            html_preview = _generar_html_preview(datos)
            return JsonResponse({
                'success': True,
                'html': html_preview,
                'total_registros': len(datos['registros'])
            })
        
        # Acción de descarga
        elif parametros['action'] == 'download':
            if parametros['formato'] == 'csv':
                return _generar_csv_response(datos, parametros['tipo_reporte'], fecha_inicio, fecha_fin)
            elif parametros['formato'] == 'excel':
                return _generar_excel_response(datos, parametros['tipo_reporte'], fecha_inicio, fecha_fin)
            elif parametros['formato'] == 'pdf':
                return _generar_pdf_response(datos, parametros['tipo_reporte'], fecha_inicio, fecha_fin)
    
    # ===============================
    # PROCESAR SOLICITUD GET
    # ===============================
    context = {
        'pasillos': pasillos,
    }
    
    return render(request, 'visualizacionBoxes/reportes.html', context)


def _generar_reporte_ocupacion(agendas_query, fecha_inicio, fecha_fin):
    """
    Genera reporte de ocupación de boxes con estadísticas detalladas.
    """
    from django.db.models import Count, Sum, F, Case, When, DurationField
    from django.db.models.functions import Cast
    from datetime import datetime, timedelta
    
    # Calcular duración de cada agenda en horas
    agendas_con_duracion = agendas_query.annotate(
        duracion_segundos=Cast(
            F('horafin') - F('horainicio'),
            DurationField()
        )
    )
    
    # Agrupar por box y calcular estadísticas
    estadisticas_box = agendas_con_duracion.values(
        'idbox__idbox',
        'idbox__idpasillo__pasillo'
    ).annotate(
        total_agendas=Count('idagenda'),
        total_horas=Sum(
            Cast(F('duracion_segundos'), DurationField())
        )
    ).order_by('idbox__idbox')
    
    registros = []
    for stat in estadisticas_box:
        # Convertir duración a horas
        duracion_total = stat['total_horas']
        horas_ocupacion = duracion_total.total_seconds() / 3600 if duracion_total else 0
        
        # Calcular días en el rango
        dias_periodo = (fecha_fin - fecha_inicio).days + 1
        horas_disponibles = dias_periodo * 24  # Asumiendo 24 horas disponibles por día
        
        porcentaje_ocupacion = (horas_ocupacion / horas_disponibles * 100) if horas_disponibles > 0 else 0
        
        registros.append({
            'Box': f"Box {stat['idbox__idbox']}",
            'Pasillo': stat['idbox__idpasillo__pasillo'],
            'Total Agendas': stat['total_agendas'],
            'Horas Ocupación': round(horas_ocupacion, 2),
            'Horas Disponibles': horas_disponibles,
            'Porcentaje Ocupación': f"{porcentaje_ocupacion:.1f}%"
        })
    
    return {
        'registros': registros,
        'columnas': ['Box', 'Pasillo', 'Total Agendas', 'Horas Ocupación', 'Horas Disponibles', 'Porcentaje Ocupación'],
        'titulo': 'Reporte de Ocupación de Boxes'
    }


def _generar_reporte_profesionales(agendas_query, fecha_inicio, fecha_fin):
    """
    Genera reporte de actividad por profesional.
    """
    from django.db.models import Count, F
    
    estadisticas_prof = agendas_query.values(
        'idprofesional__idprofesional',
        'idprofesional__nombre',
        'idprofesional__idespecialidad__especialidad'
    ).annotate(
        total_agendas=Count('idagenda'),
        boxes_utilizados=Count('idbox', distinct=True)
    ).order_by('-total_agendas')
    
    registros = []
    for stat in estadisticas_prof:
        registros.append({
            'ID Profesional': stat['idprofesional__idprofesional'],
            'Nombre': stat['idprofesional__nombre'],
            'Especialidad': stat['idprofesional__idespecialidad__especialidad'],
            'Total Agendas': stat['total_agendas'],
            'Boxes Utilizados': stat['boxes_utilizados']
        })
    
    return {
        'registros': registros,
        'columnas': ['ID Profesional', 'Nombre', 'Especialidad', 'Total Agendas', 'Boxes Utilizados'],
        'titulo': 'Reporte de Actividad por Profesional'
    }


def _generar_reporte_especialidades(agendas_query, fecha_inicio, fecha_fin):
    """
    Genera reporte de actividad por especialidad.
    """
    from django.db.models import Count
    
    estadisticas_esp = agendas_query.values(
        'idprofesional__idespecialidad__especialidad'
    ).annotate(
        total_agendas=Count('idagenda'),
        profesionales_activos=Count('idprofesional', distinct=True),
        boxes_utilizados=Count('idbox', distinct=True)
    ).order_by('-total_agendas')
    
    registros = []
    for stat in estadisticas_esp:
        registros.append({
            'Especialidad': stat['idprofesional__idespecialidad__especialidad'],
            'Total Agendas': stat['total_agendas'],
            'Profesionales Activos': stat['profesionales_activos'],
            'Boxes Utilizados': stat['boxes_utilizados']
        })
    
    return {
        'registros': registros,
        'columnas': ['Especialidad', 'Total Agendas', 'Profesionales Activos', 'Boxes Utilizados'],
        'titulo': 'Reporte de Actividad por Especialidad'
    }


def _generar_reporte_tipos_agenda(agendas_query, fecha_inicio, fecha_fin):
    """
    Genera reporte de actividad por tipo de agenda.
    """
    from django.db.models import Count
    
    estadisticas_tipo = agendas_query.values(
        'idtipoagenda__tipoagenda'
    ).annotate(
        total_agendas=Count('idagenda'),
        boxes_utilizados=Count('idbox', distinct=True),
        profesionales_involucrados=Count('idprofesional', distinct=True)
    ).order_by('-total_agendas')
    
    registros = []
    for stat in estadisticas_tipo:
        registros.append({
            'Tipo de Agenda': stat['idtipoagenda__tipoagenda'],
            'Total Agendas': stat['total_agendas'],
            'Boxes Utilizados': stat['boxes_utilizados'],
            'Profesionales Involucrados': stat['profesionales_involucrados']
        })
    
    return {
        'registros': registros,
        'columnas': ['Tipo de Agenda', 'Total Agendas', 'Boxes Utilizados', 'Profesionales Involucrados'],
        'titulo': 'Reporte de Actividad por Tipo de Agenda'
    }


def _generar_html_preview(datos):
    """
    Genera HTML para vista previa de los datos del reporte.
    """
    if not datos['registros']:
        return '<div class="alert alert-info-custom">No hay datos para mostrar</div>'
    
    # Identificar el box más y menos utilizado si es reporte de ocupación
    stats_extra = ""
    if 'Porcentaje Ocupación' in datos['columnas'] and len(datos['registros']) > 0:
        # Encontrar box más utilizado
        box_mas_usado = max(datos['registros'], 
                           key=lambda x: float(x.get('Porcentaje Ocupación', '0%').replace('%', '')))
        box_menos_usado = min(datos['registros'], 
                             key=lambda x: float(x.get('Porcentaje Ocupación', '0%').replace('%', '')))
        
        stats_extra = f'''
        <div class="row mt-3 mb-3">
            <div class="col-md-6">
                <div class="card bg-success text-white">
                    <div class="card-body text-center py-2">
                        <small><strong>Box más utilizado:</strong> {box_mas_usado.get('Box', '')}</small>
                    </div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="card bg-warning text-dark">
                    <div class="card-body text-center py-2">
                        <small><strong>Box menos utilizado:</strong> {box_menos_usado.get('Box', '')}</small>
                    </div>
                </div>
            </div>
        </div>
        '''
    
    html = f'<h6 class="mb-3 text-center">{datos["titulo"]}</h6>'
    html += stats_extra
    html += '<div class="table-responsive">'
    html += '<table class="table table-preview table-striped">'
    html += '<thead><tr>'
    
    for columna in datos['columnas']:
        html += f'<th>{columna}</th>'
    html += '</tr></thead><tbody>'
    
    # Mostrar solo los primeros 15 registros en preview para parecerse más a la imagen
    registros_preview = datos['registros'][:15]
    
    for i, registro in enumerate(registros_preview):
        # Alternar colores como en la imagen
        row_class = ""
        html += f'<tr{row_class}>'
        for columna in datos['columnas']:
            valor = registro.get(columna, "")
            # Formatear valores especiales
            if 'Porcentaje' in columna and isinstance(valor, str) and '%' in valor:
                porcentaje = float(valor.replace('%', ''))
                if porcentaje > 75:
                    html += f'<td><span class="badge bg-success">{valor}</span></td>'
                elif porcentaje > 50:
                    html += f'<td><span class="badge bg-warning">{valor}</span></td>'
                else:
                    html += f'<td><span class="badge bg-secondary">{valor}</span></td>'
            elif 'Box' in columna:
                # Formatear número de box
                if isinstance(valor, str) and 'Box' in valor:
                    numero = valor.replace('Box ', '')
                    html += f'<td><strong>{numero.zfill(2)}</strong></td>'
                else:
                    html += f'<td><strong>{valor}</strong></td>'
            else:
                html += f'<td>{valor}</td>'
        html += '</tr>'
    
    html += '</tbody></table>'
    
    if len(datos['registros']) > 15:
        html += f'<div class="text-center mt-3">'
        html += f'<small class="text-muted">Mostrando 15 de {len(datos["registros"])} registros. '
        html += f'Descarga el reporte completo para ver todos los datos.</small>'
        html += f'</div>'
    
    html += '</div>'
    
    return html


def _generar_csv_response(datos, tipo_reporte, fecha_inicio, fecha_fin):
    """
    Genera respuesta HTTP con archivo CSV.
    """
    import csv
    from django.http import HttpResponse
    
    filename = f'reporte_{tipo_reporte}_{fecha_inicio}_{fecha_fin}.csv'
    response = HttpResponse(content_type='text/csv; charset=utf-8')
    response['Content-Disposition'] = f'attachment; filename="{filename}"'
    
    # Agregar BOM para UTF-8
    response.write('\ufeff')
    
    writer = csv.writer(response)
    
    # Escribir encabezados
    writer.writerow(datos['columnas'])
    
    # Escribir datos
    for registro in datos['registros']:
        fila = [registro.get(columna, '') for columna in datos['columnas']]
        writer.writerow(fila)
    
    return response


def _generar_excel_response(datos, tipo_reporte, fecha_inicio, fecha_fin):
    """
    Genera respuesta HTTP con archivo Excel.
    Requiere: pip install openpyxl
    """
    try:
        from openpyxl import Workbook
        from openpyxl.styles import Font, PatternFill
        from django.http import HttpResponse
        import io
        
        wb = Workbook()
        ws = wb.active
        ws.title = datos['titulo']
        
        # Escribir encabezados con estilo
        for col, columna in enumerate(datos['columnas'], 1):
            cell = ws.cell(row=1, column=col, value=columna)
            cell.font = Font(bold=True)
            cell.fill = PatternFill(start_color="CCCCCC", end_color="CCCCCC", fill_type="solid")
        
        # Escribir datos
        for row, registro in enumerate(datos['registros'], 2):
            for col, columna in enumerate(datos['columnas'], 1):
                ws.cell(row=row, column=col, value=registro.get(columna, ''))
        
        # Ajustar ancho de columnas
        for column in ws.columns:
            max_length = 0
            column_letter = column[0].column_letter
            for cell in column:
                try:
                    if len(str(cell.value)) > max_length:
                        max_length = len(str(cell.value))
                except:
                    pass
            adjusted_width = min(max_length + 2, 50)
            ws.column_dimensions[column_letter].width = adjusted_width
        
        # Guardar en memoria
        output = io.BytesIO()
        wb.save(output)
        output.seek(0)
        
        filename = f'reporte_{tipo_reporte}_{fecha_inicio}_{fecha_fin}.xlsx'
        response = HttpResponse(
            output.getvalue(),
            content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        )
        response['Content-Disposition'] = f'attachment; filename="{filename}"'
        
        return response
        
    except ImportError:
        # Si openpyxl no está instalado, fallback a CSV
        return _generar_csv_response(datos, tipo_reporte, fecha_inicio, fecha_fin)


def _generar_pdf_response(datos, tipo_reporte, fecha_inicio, fecha_fin):
    """
    Genera respuesta HTTP con archivo PDF.
    Requiere: pip install reportlab
    """
    try:
        from reportlab.lib import colors
        from reportlab.lib.pagesizes import letter, A4
        from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
        from reportlab.lib.styles import getSampleStyleSheet
        from django.http import HttpResponse
        import io
        
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4)
        elements = []
        
        styles = getSampleStyleSheet()
        
        # Título
        title = Paragraph(datos['titulo'], styles['Title'])
        elements.append(title)
        elements.append(Spacer(1, 12))
        
        # Rango de fechas
        date_range = Paragraph(f"Período: {fecha_inicio} al {fecha_fin}", styles['Normal'])
        elements.append(date_range)
        elements.append(Spacer(1, 12))
        
        # Preparar datos para tabla
        table_data = [datos['columnas']]
        for registro in datos['registros']:
            fila = [str(registro.get(columna, '')) for columna in datos['columnas']]
            table_data.append(fila)
        
        # Crear tabla
        table = Table(table_data)
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        elements.append(table)
        
        doc.build(elements)
        
        buffer.seek(0)
        filename = f'reporte_{tipo_reporte}_{fecha_inicio}_{fecha_fin}.pdf'
        response = HttpResponse(buffer.getvalue(), content_type='application/pdf')
        response['Content-Disposition'] = f'attachment; filename="{filename}"'
        
        return response
        
    except ImportError:
        # Si reportlab no está instalado, fallback a CSV
        return _generar_csv_response(datos, tipo_reporte, fecha_inicio, fecha_fin)


# ==================== FUNCIONES AUXILIARES GENERALES ====================


def buscar_medicos(request):
    """
    Vista AJAX para buscar médicos por nombre.
    
    Busca profesionales cuyo nombre contenga el término de búsqueda
    y retorna una lista con ID y nombre para autocompletado.
    
    Parámetros GET:
    - q: Término de búsqueda (nombre del médico)
    
    Returns:
        JsonResponse: Lista de médicos encontrados con formato:
        {
            'medicos': [
                {'id': 1, 'nombre': 'Dr. Juan Pérez', 'especialidad': 'Cardiología'},
                ...
            ]
        }
    """
    termino = request.GET.get('q', '').strip()
    
    if len(termino) < 2:
        return JsonResponse({'medicos': []})
    
    # Buscar médicos que coincidan con el término
    medicos = Profesional.objects.filter(
        nombre__icontains=termino
    ).select_related('idespecialidad').order_by('nombre')[:10]  # Limitar a 10 resultados
    
    # Formatear respuesta
    medicos_data = []
    for medico in medicos:
        medicos_data.append({
            'id': medico.idprofesional,
            'nombre': medico.nombre,
            'especialidad': medico.idespecialidad.especialidad if medico.idespecialidad else 'Sin especialidad'
        })
    
    return JsonResponse({'medicos': medicos_data})


# ===============================
# VISTAS DE AUTENTICACIÓN Y USUARIO
# ===============================

from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.shortcuts import redirect
from .models import PerfilUsuario, TipoUsuario


def perfil_usuario(request):
    """
    Vista para mostrar el perfil del usuario autenticado.
    
    Muestra información del usuario y permite actualizaciones básicas.
    """
    if not request.user.is_authenticated:
        messages.warning(request, 'Debes iniciar sesión para ver tu perfil.')
        return redirect('account_login')
    
    try:
        perfil = request.user.perfilusuario
    except PerfilUsuario.DoesNotExist:
        # Crear perfil si no existe (usuarios creados antes del sistema)
        tipo_visitante = TipoUsuario.objects.get_or_create(
            nombre='Visitante',
            defaults={'descripcion': 'Usuario visitante con acceso limitado', 'activo': True}
        )[0]
        
        perfil = PerfilUsuario.objects.create(
            usuario=request.user,
            tipo_usuario=tipo_visitante,
            activo=True
        )
        messages.info(request, 'Se ha creado tu perfil como Visitante.')
    
    context = {
        'perfil': perfil,
        'tipos_usuario': TipoUsuario.objects.filter(activo=True).order_by('nombre')
    }
    
    return render(request, 'visualizacionBoxes/perfil_usuario.html', context)


@login_required
def dashboard_usuario(request):
    """
    Vista del dashboard personalizado según el tipo de usuario.
    """
    perfil = request.user.perfilusuario
    
    # Actualizar último acceso
    perfil.ultimo_acceso = datetime.now()
    perfil.save()
    
    # Datos específicos según tipo de usuario
    context = {
        'perfil': perfil,
    }
    
    if perfil.es_administrador:
        # Estadísticas para administradores
        context.update({
            'total_usuarios': PerfilUsuario.objects.filter(activo=True).count(),
            'total_boxes': Box.objects.count(),
            'agendas_hoy': Agenda.objects.filter(fecha=datetime.now().date()).count(),
        })
    elif perfil.es_personal_medico or perfil.es_personal_administrativo:
        # Información relevante para personal médico/administrativo
        context.update({
            'agendas_hoy': Agenda.objects.filter(fecha=datetime.now().date()).count(),
            'boxes_ocupados': Box.objects.filter(
                agenda__fecha=datetime.now().date(),
                agenda__horainicio__lte=datetime.now().time(),
                agenda__horafin__gte=datetime.now().time()
            ).distinct().count(),
        })
    
    return render(request, 'visualizacionBoxes/dashboard_usuario.html', context)


def verificar_permisos(user, accion='lectura'):
    """
    Función auxiliar para verificar permisos de usuario.
    
    Args:
        user: Usuario de Django
        accion: 'lectura' o 'escritura'
    
    Returns:
        bool: True si tiene permisos, False en caso contrario
    """
    if not user.is_authenticated:
        return False
    
    try:
        perfil = user.perfilusuario
        if not perfil.activo or not perfil.tipo_usuario.activo:
            return False
        
        if accion == 'lectura':
            return perfil.tiene_permiso_lectura()
        elif accion == 'escritura':
            return perfil.tiene_permiso_escritura()
        
        return False
    except PerfilUsuario.DoesNotExist:
        return False


def redirect_after_login(request):
    """
    Vista para redireccionar al usuario después del login según su tipo.
    """
    if not request.user.is_authenticated:
        return redirect('account_login')
    
    try:
        perfil = request.user.perfilusuario
        
        # Mensaje de bienvenida personalizado
        if perfil.es_administrador:
            messages.success(request, f'¡Bienvenido, {perfil.nombre_completo}! Tienes acceso completo como administrador.')
        elif perfil.es_personal_medico:
            messages.success(request, f'¡Bienvenido, {perfil.nombre_completo}! Accede a las funciones médicas.')
        elif perfil.es_personal_administrativo:
            messages.success(request, f'¡Bienvenido, {perfil.nombre_completo}! Gestiona las funciones administrativas.')
        else:
            messages.info(request, f'¡Bienvenido, {perfil.nombre_completo}! Tienes acceso como visitante.')
        
        # Redireccionar según preferencias
        return redirect('visualizacionBoxes:visualizacion_general')
        
    except PerfilUsuario.DoesNotExist:
        messages.warning(request, 'Tu perfil no está configurado. Contacta al administrador.')
        return redirect('visualizacionBoxes:visualizacion_general')


def crear_agenda(request):
    """
    Vista para crear una nueva agenda desde el panel de agendamiento.
    
    Procesa los datos del formulario de agendamiento y crea una nueva
    entrada en la agenda si los datos son válidos.
    
    Returns:
        JsonResponse: Respuesta con el resultado de la operación
    """
    if request.method == 'POST':
        try:
            # Verificar permisos del usuario
            if not request.user.is_authenticated:
                return JsonResponse({'error': 'Usuario no autenticado'}, status=401)
            
            # Verificar que el usuario tenga permisos para crear agendas
            perfil = request.user.perfilusuario
            if not (perfil.es_administrador or perfil.es_personal_administrativo):
                return JsonResponse({'error': 'Sin permisos para crear agendas'}, status=403)
            
            # Obtener datos del formulario
            box_id = request.POST.get('box')
            fecha = request.POST.get('fecha')
            hora_inicio = request.POST.get('hora_inicio')
            hora_fin = request.POST.get('hora_fin')
            profesional_id = request.POST.get('profesional')  # Opcional
            tipo_agenda_id = request.POST.get('tipo_agenda')
            observaciones = request.POST.get('observaciones', '')
            
            # Validar datos requeridos (solo los obligatorios)
            # Nota: Profesional es técnicamente requerido en BD, pero puede implementarse un "profesional genérico"
            if not all([box_id, fecha, hora_inicio, hora_fin, tipo_agenda_id]):
                return JsonResponse({'error': 'Faltan datos requeridos. Campos obligatorios: Box, Fecha, Hora inicio, Hora fin, Tipo de agenda'}, status=400)
            
            # Validar y obtener objetos relacionados
            try:
                box = Box.objects.get(idbox=box_id)
                tipo_agenda = Tipoagenda.objects.get(idtipoagenda=tipo_agenda_id)
                fecha_obj = datetime.strptime(fecha, '%Y-%m-%d').date()
                hora_inicio_obj = datetime.strptime(hora_inicio, '%H:%M').time()
                hora_fin_obj = datetime.strptime(hora_fin, '%H:%M').time()
                
                # Profesional: si no se especifica, usar un profesional genérico o el primero disponible
                if profesional_id:
                    profesional = Profesional.objects.get(idprofesional=profesional_id)
                else:
                    # Usar el primer profesional disponible como "genérico"
                    profesional = Profesional.objects.first()
                    if not profesional:
                        return JsonResponse({'error': 'No hay profesionales disponibles en el sistema'}, status=400)
                    
            except Box.DoesNotExist:
                return JsonResponse({'error': 'Box no encontrado'}, status=400)
            except Tipoagenda.DoesNotExist:
                return JsonResponse({'error': 'Tipo de agenda no encontrado'}, status=400)
            except Profesional.DoesNotExist:
                return JsonResponse({'error': 'Profesional no encontrado'}, status=400)
            except ValueError:
                return JsonResponse({'error': 'Formato de fecha u hora inválido'}, status=400)
            
            # Validar que hora_fin sea posterior a hora_inicio
            if hora_fin_obj <= hora_inicio_obj:
                return JsonResponse({'error': 'La hora de fin debe ser posterior a la hora de inicio'}, status=400)
            
            # Verificar conflictos de horario en el mismo box
            conflictos = Agenda.objects.filter(
                idbox=box,
                fecha=fecha_obj
            ).filter(
                Q(horainicio__lt=hora_fin_obj, horafin__gt=hora_inicio_obj)
            )
            
            if conflictos.exists():
                return JsonResponse({'error': 'Ya existe una agenda en ese horario para el box seleccionado'}, status=400)
            
            # Crear la nueva agenda
            nueva_agenda = Agenda.objects.create(
                idbox=box,
                idprofesional=profesional,  # Requerido en BD - usa profesional seleccionado o genérico
                idtipoagenda=tipo_agenda,
                fecha=fecha_obj,
                horainicio=hora_inicio_obj,
                horafin=hora_fin_obj,
                observaciones=observaciones
            )
            
            return JsonResponse({
                'success': True,
                'message': 'Agenda creada exitosamente',
                'agenda_id': nueva_agenda.idagenda
            })
            
        except Exception as e:
            return JsonResponse({'error': f'Error interno: {str(e)}'}, status=500)
    
    return JsonResponse({'error': 'Método no permitido'}, status=405)
