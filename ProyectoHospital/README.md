# Sistema de Visualización de Boxes del Hospital

## Descripción

Este sistema permite visualizar el estado en tiempo real de los boxes del hospital, mostrando su disponibilidad y ocupación según las agendas programadas. La aplicación está desarrollada con Django y ofrece una interfaz intuitiva para monitorear el estado de todos los boxes.

## Características Principales

- **Visualización en tiempo real**: Muestra el estado actual de todos los boxes
- **Filtros avanzados**: Filtrar por fecha, pasillo y especialidad
- **Interfaz responsiva**: Adaptable a diferentes tamaños de pantalla
- **Código de colores**: Cada tipo de agenda tiene un color específico
- **Detalles por box**: Modal con información detallada de cada box
- **Navegación de fechas**: Fácil navegación entre días

## Estructura del Proyecto

```
ProyectoHospital/
├── manage.py                          # Script principal de Django
├── db.sqlite3                         # Base de datos SQLite
├── ProyectoHospital/                  # Configuración principal
│   ├── __init__.py
│   ├── settings.py                    # Configuración de Django
│   ├── urls.py                        # URLs principales
│   ├── wsgi.py                        # Configuración WSGI
│   └── asgi.py                        # Configuración ASGI
└── visualizacionBoxes/                # Aplicación principal
    ├── __init__.py
    ├── admin.py                       # Configuración del admin
    ├── apps.py                        # Configuración de la app
    ├── models.py                      # Modelos de datos
    ├── views.py                       # Vistas de la aplicación
    ├── urls.py                        # URLs de la aplicación
    ├── templatetags/                  # Filtros personalizados
    │   ├── __init__.py
    │   └── box_filters.py             # Filtros para templates
    ├── templates/                     # Templates HTML
    │   └── visualizacionBoxes/
    │       ├── base.html              # Template base
    │       ├── header.html            # Cabecera
    │       ├── visualizacionGeneral.html # Vista principal
    │       ├── leyendaBoxes.html      # Leyenda de colores
    │       └── filtrosSuperioresGeneral.html # Filtros
    └── static/                        # Archivos estáticos
        ├── css/
        │   ├── visualizacionGeneral.css # Estilos principales
        │   └── filtrosSuperioresGeneral.css # Estilos de filtros
        ├── js/
        │   └── visualizacionGeneral.js # JavaScript principal
        └── img/                       # Imágenes
```

## Modelos de Datos

### Box
Representa un box del hospital con su ubicación y capacidad.

- `idbox`: ID único del box
- `idpasillo`: Referencia al pasillo donde se ubica
- `capacidad`: Capacidad máxima del box

### Agenda
Representa una cita o reserva programada en un box.

- `idagenda`: ID único de la agenda
- `idtipoagenda`: Tipo de agenda (consulta, cirugía, etc.)
- `idprofesional`: Profesional asignado
- `idbox`: Box reservado
- `fecha`: Fecha de la agenda
- `horainicio`: Hora de inicio
- `horafin`: Hora de finalización

### Pasillo
Representa los pasillos del hospital donde se ubican los boxes.

- `idpasillo`: ID único del pasillo
- `pasillo`: Nombre del pasillo

### Especialidad
Representa las diferentes especialidades médicas.

- `idespecialidad`: ID único de la especialidad
- `especialidad`: Nombre de la especialidad

### Profesional
Representa a los profesionales de la salud.

- `idprofesional`: ID único del profesional
- `nombre`: Nombre completo
- `idespecialidad`: Especialidad del profesional

### TipoAgenda
Define los diferentes tipos de agendas y sus colores.

- `idtipoagenda`: ID único del tipo
- `tipoagenda`: Nombre del tipo de agenda

## Funcionalidades

### Vista Principal (`visualizacion_general`)

La vista principal muestra una grilla de todos los boxes con:

- **Color verde**: Box disponible
- **Color según tipo**: Box ocupado (color según el tipo de agenda)
- **Información básica**: Número del box y estado

### Filtros

- **Fecha**: Seleccionar día específico
- **Pasillo**: Filtrar por pasillo específico
- **Especialidad**: Filtrar por especialidad médica

### Modal de Detalles

Al hacer clic en un box se muestra un modal con:

- Información del box (número, pasillo, capacidad)
- Estado actual (disponible/ocupado)
- Si está ocupado: profesional, especialidad, horario

## Tecnologías Utilizadas

- **Backend**: Django 4.x
- **Frontend**: HTML5, CSS3, JavaScript ES6+
- **Estilos**: Bootstrap 5
- **Base de datos**: SQLite
- **Iconos**: Bootstrap Icons

## Instalación y Configuración

### Requisitos Previos

- Python 3.8+
- pip
- Django 4.x

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone [url-del-repositorio]
   cd ProyectoHospital
   ```

2. **Crear entorno virtual**
   ```bash
   python -m venv venv
   source venv/bin/activate  # En Windows: venv\Scripts\activate
   ```

3. **Instalar dependencias**
   ```bash
   pip install django
   ```

4. **Configurar base de datos**
   ```bash
   python manage.py migrate
   ```

5. **Crear superusuario (opcional)**
   ```bash
   python manage.py createsuperuser
   ```

6. **Ejecutar servidor de desarrollo**
   ```bash
   python manage.py runserver
   ```

7. **Acceder a la aplicación**
   - Navegador: `http://127.0.0.1:8000/`
   - Admin: `http://127.0.0.1:8000/admin/`

## Uso

### Visualización General

1. Acceder a la URL principal
2. Seleccionar filtros si es necesario (fecha, pasillo, especialidad)
3. Ver el estado de los boxes en la grilla
4. Hacer clic en cualquier box para ver detalles

### Navegación

- **Flechas de fecha**: Navegar entre días
- **Selector de fecha**: Ir a una fecha específica
- **Filtros**: Aplicar filtros específicos

### Códigos de Color

- **Verde**: Box disponible
- **Otros colores**: Box ocupado (según tipo de agenda)

## Desarrollo

### Estructura del Código

El código está organizado siguiendo las mejores prácticas de Django:

- **Modelos**: Definidos en `models.py` con documentación completa
- **Vistas**: Separadas por funcionalidad con docstrings
- **Templates**: Modularizados y reutilizables
- **Estáticos**: Organizados por tipo (CSS, JS, imágenes)

### Funciones Principales

#### Python (views.py)

- `visualizacion_general()`: Vista principal de la aplicación
- `obtener_detalle_box()`: API AJAX para detalles de boxes
- `_crear_estado_actual_boxes()`: Lógica de estado de boxes

#### JavaScript (visualizacionGeneral.js)

- `mostrarDetalle()`: Muestra modal con detalles
- `aplicarFiltros()`: Aplica filtros seleccionados
- `cambiarFecha()`: Navegación entre fechas

### Personalización

Para personalizar el sistema:

1. **Colores**: Modificar CSS en `visualizacionGeneral.css`
2. **Tipos de agenda**: Agregar en la base de datos
3. **Filtros**: Modificar templates y views según necesidades
4. **Intervalos**: Cambiar `UPDATE_INTERVAL` en JavaScript

## Soporte

Para soporte técnico o reportar problemas:

1. Revisar logs de Django
2. Verificar configuración de base de datos
3. Comprobar permisos de archivos estáticos

## Licencia

Este proyecto está desarrollado para uso interno del hospital.

---

**Versión**: 1.0  
**Última actualización**: Julio 2025  
**Autor**: Hospital System
