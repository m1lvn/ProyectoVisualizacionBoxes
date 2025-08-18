"""
Template tags personalizados para la visualización por pasillo.

Este módulo contiene filtros y tags útiles para manipular datos
en los templates de visualización por pasillo.
"""

from django import template

register = template.Library()


@register.filter
def get_item(dictionary, key):
    """
    Obtiene un item del diccionario usando una clave.
    
    Args:
        dictionary: Diccionario de donde obtener el valor
        key: Clave a buscar
        
    Returns:
        El valor asociado a la clave o None si no existe
    """
    if not isinstance(dictionary, dict):
        return None
    return dictionary.get(key)


@register.filter
def lower(value):
    """
    Convierte un string a minúsculas.
    
    Args:
        value: String a convertir
        
    Returns:
        String en minúsculas
    """
    if value:
        return str(value).lower()
    return ""


@register.filter
def default_if_none(value, default):
    """
    Retorna un valor por defecto si el valor es None.
    
    Args:
        value: Valor a evaluar
        default: Valor por defecto
        
    Returns:
        El valor original o el por defecto si es None
    """
    return value if value is not None else default


@register.filter
def formato_hora(hora):
    """
    Formatea una hora en formato HH:MM.
    
    Args:
        hora: Objeto time o string de hora
        
    Returns:
        String formateado como HH:MM
    """
    if hasattr(hora, 'strftime'):
        return hora.strftime('%H:%M')
    return str(hora)


@register.filter
def estado_box_clase_css(estado):
    """
    Convierte el estado de un box en clase CSS apropiada.
    
    Args:
        estado: String con el estado del box
        
    Returns:
        String con la clase CSS correspondiente
    """
    estado_clases = {
        'Disponible': 'libre',
        'Reservado': 'ocupado',
        'Inhabilitado': 'inhabilitado',
        'En mantención': 'mantencion',
        'Limpieza': 'limpieza'
    }
    return estado_clases.get(estado, 'desconocido')


@register.filter
def tipo_agenda_to_css_class(tipo_agenda):
    """
    Convierte el tipo de agenda a una clase CSS para styling.
    
    Args:
        tipo_agenda: String con el tipo de agenda
        
    Returns:
        String con la clase CSS correspondiente
    """
    if not tipo_agenda:
        return 'disponible'
    
    # Mapeo de tipos de agenda a clases CSS
    mapeo_css = {
        'hora médica': 'hora-medica',
        'hora no médica': 'hora-no-medica', 
        'limpieza': 'limpieza',
        'mantención': 'mantencion',
        'mantención técnica': 'mantencion',
        'capacitación': 'capacitacion',
        'reunión clínica': 'reunion',
        'bloqueado por gestión': 'bloqueado-gestion',
        'bloqueo administrativo': 'bloqueo-admin',
        'reservado para urgencias': 'urgencias',
        'inhabilitado': 'deshabilitado'
    }
    
    # Normalizar el tipo de agenda (minúsculas, sin acentos extra)
    tipo_normalizado = tipo_agenda.lower().strip()
    
    # Buscar coincidencia exacta primero
    if tipo_normalizado in mapeo_css:
        return mapeo_css[tipo_normalizado]
    
    # Buscar coincidencias parciales
    for tipo_key, css_class in mapeo_css.items():
        if tipo_key in tipo_normalizado:
            return css_class
    
    # Si no encuentra coincidencia, usar ocupado como default
    return 'ocupado'


@register.inclusion_tag('visualizacionBoxes/components/box_cell.html')
def render_box_cell(box, hora, estado, pasillo):
    """
    Renderiza una celda de box para la matriz de visualización.
    
    Args:
        box: Objeto Box
        hora: String con la hora
        estado: Estado del box en esa hora
        pasillo: Nombre del pasillo
        
    Returns:
        Dict con contexto para el template
    """
    return {
        'box': box,
        'hora': hora,
        'estado': estado,
        'pasillo': pasillo.lower() if pasillo else '',
        'css_class': estado_box_clase_css(estado)
    }
