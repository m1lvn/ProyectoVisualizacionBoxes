# Configuración del Sistema de Visualización de Boxes

# Colores para los tipos de agenda (CSS classes)
COLORES_TIPOS_AGENDA = {
    1: 'tipo-agenda-1',   # Consulta
    2: 'tipo-agenda-2',   # Cirugía
    3: 'tipo-agenda-3',   # Urgencia
    4: 'tipo-agenda-4',   # Procedimiento
    5: 'tipo-agenda-5',   # Rehabilitación
    6: 'tipo-agenda-6',   # Diagnóstico
    7: 'tipo-agenda-7',   # Seguimiento
    8: 'tipo-agenda-8',   # Emergencia
    9: 'tipo-agenda-9',   # Especializada
    10: 'tipo-agenda-10', # Otros
}

# Intervalos de actualización (en milisegundos)
INTERVALOS_ACTUALIZACION = {
    'RAPIDO': 10000,    # 10 segundos
    'NORMAL': 30000,    # 30 segundos
    'LENTO': 60000,     # 1 minuto
}

# Configuración de horarios
HORARIOS = {
    'INICIO_DIA': '08:00',
    'FIN_DIA': '18:00',
    'INTERVALO_MINUTOS': 30,
    'BLOQUES': {
        'AM': {'inicio': '08:00', 'fin': '12:00'},
        'PM': {'inicio': '14:00', 'fin': '18:00'},
        'FULLTIME': {'inicio': '08:00', 'fin': '18:00'},
    }
}

# Configuración de la interfaz
INTERFAZ = {
    'BOXES_POR_FILA': 12,
    'MOSTRAR_NUMEROS_BOX': True,
    'MOSTRAR_LEYENDA': True,
    'PERMITIR_CLICK_DETALLE': True,
    'ACTUALIZACION_AUTOMATICA': True,
}

# Mensajes del sistema
MENSAJES = {
    'ERROR_CONEXION': 'Error de conexión al servidor',
    'ERROR_DATOS': 'Error al cargar los datos',
    'BOX_DISPONIBLE': 'Box disponible',
    'BOX_OCUPADO': 'Box ocupado',
    'CARGANDO': 'Cargando...',
    'SIN_DATOS': 'No hay datos disponibles',
}

# Configuración de filtros
FILTROS = {
    'PERMITIR_FILTRO_FECHA': True,
    'PERMITIR_FILTRO_PASILLO': True,
    'PERMITIR_FILTRO_ESPECIALIDAD': True,
    'FECHA_POR_DEFECTO': 'HOY',  # 'HOY' o fecha específica
}
