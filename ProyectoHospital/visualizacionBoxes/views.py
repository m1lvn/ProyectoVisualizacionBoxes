"""
Vistas para la aplicación de visualización de boxes del hospital.

Este módulo contiene las vistas principales para mostrar el estado
de los boxes del hospital en tiempo real.
"""

from django.shortcuts import render, get_object_or_404
from django.http import JsonResponse
from django.db.models import Q
from datetime import datetime, time, timedelta

from .models import (
    Box, Agenda, Tipoagenda, Pasillo, Especialidad, Profesional
)


def visualizacion_general(request):
    """
    Vista principal para mostrar la visualización general de boxes.
    
    Muestra el estado actual de todos los boxes basado en la hora actual
    y permite filtrar por fecha, pasillo, especialidad, médico y box específico.
    
    Args:
        request: HttpRequest object
        
    Returns:
        HttpResponse: Página con la visualización general de boxes
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
    
    Args:
        request: HttpRequest object con parámetros box_id y fecha
        
    Returns:
        JsonResponse: Información detallada del box y su agenda actual
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


def _generar_horarios(bloque_horario='FULLTIME'):
    """
    Genera lista de horarios según el bloque seleccionado.
    
    Args:
        bloque_horario: 'AM', 'PM' o 'FULLTIME'
        
    Returns:
        list: Lista de horarios en formato 'HH:MM'
    """
    if bloque_horario == 'AM':
        # Horario matutino: 8:00 - 12:00
        hora_inicio = time(8, 0)
        hora_fin = time(12, 0)
    elif bloque_horario == 'PM':
        # Horario vespertino: 14:00 - 18:00
        hora_inicio = time(14, 0)
        hora_fin = time(18, 0)
    else:  # FULLTIME
        # Horario completo: 8:00 - 18:00
        hora_inicio = time(8, 0)
        hora_fin = time(18, 0)
    
    # Generar horarios cada 30 minutos
    horas = []
    current_time = datetime.combine(datetime.today(), hora_inicio)
    end_time = datetime.combine(datetime.today(), hora_fin)
    
    while current_time < end_time:
        horas.append(current_time.strftime('%H:%M'))
        current_time += timedelta(minutes=30)
    
    return horas


def _crear_matriz_disponibilidad(boxes, horas, agendas):
    """
    Crea una matriz que indica el estado de cada box en cada horario.
    
    Args:
        boxes: QuerySet de boxes
        horas: Lista de horarios
        agendas: QuerySet de agendas
        
    Returns:
        dict: Matriz de disponibilidad por box y horario
    """
    matriz = {}
    
    for box in boxes:
        matriz[box.idbox] = {}
        for hora in horas:
            # Convertir hora string a time object
            hora_obj = datetime.strptime(hora, '%H:%M').time()
            
            # Verificar si hay agenda en ese horario para ese box
            agenda_en_horario = agendas.filter(
                idbox=box,
                horainicio__lte=hora_obj,
                horafin__gt=hora_obj
            ).first()
            
            if agenda_en_horario:
                matriz[box.idbox][hora] = {
                    'disponible': False,
                    'tipo_agenda': agenda_en_horario.idtipoagenda.tipoagenda,
                    'agenda_id': agenda_en_horario.idtipoagenda.idtipoagenda,
                    'agenda': {
                        'profesional': agenda_en_horario.idprofesional.nombre,
                        'especialidad': agenda_en_horario.idprofesional.idespecialidad.especialidad,
                        'tipo_agenda': agenda_en_horario.idtipoagenda.tipoagenda,
                        'hora_inicio': agenda_en_horario.horainicio,
                        'hora_fin': agenda_en_horario.horafin
                    }
                }
            else:
                matriz[box.idbox][hora] = {
                    'disponible': True,
                    'tipo_agenda': None,
                    'agenda_id': None,
                    'agenda': None
                }
    
    return matriz