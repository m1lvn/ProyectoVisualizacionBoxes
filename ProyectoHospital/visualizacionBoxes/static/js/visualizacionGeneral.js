/**
 * Visualización General de Boxes - JavaScript
 * 
 * Este archivo contiene las funcionalidades JavaScript para la visualización
 * general de boxes del hospital, incluyendo modales, filtros y navegación.
 * 
 * @author Hospital System
 * @version 1.0
 */

// ==================== CONFIGURACIÓN GLOBAL ====================

const CONFIG = {
    // Intervalo de actualización automática (30 segundos)
    UPDATE_INTERVAL: 30000,
    
    // Configuración del datepicker
    DATE_FORMAT: "Y-m-d",
    LOCALE: "es"
};

// ==================== FUNCIONES PRINCIPALES ====================

/**
 * Muestra el modal con detalles de un box específico.
 * 
 * @param {string} boxId - ID del box a consultar
 * @param {boolean} disponible - Estado actual del box (true = disponible)
 */
function mostrarDetalle(boxId, disponible) {
    const fecha = _obtenerFechaActual();
    const url = _construirUrlDetalle(boxId, fecha);
    
    _mostrarLoader();
    
    fetch(url)
        .then(response => response.json())
        .then(data => {
            _ocultarLoader();
            
            if (data.error) {
                _mostrarError('Error al cargar detalles: ' + data.error);
                return;
            }
            
            const contenido = _generarContenidoModal(data, fecha);
            _mostrarModal(contenido);
        })
        .catch(error => {
            _ocultarLoader();
            console.error('Error en la petición:', error);
            _mostrarError('Error de conexión al obtener los detalles del box');
        });
}

/**
 * Aplica los filtros seleccionados y recarga la página.
 */
function aplicarFiltros() {
    const filtros = _obtenerFiltrosActivos();
    const url = _construirUrlConFiltros(filtros);
    
    window.location.href = url;
}

/**
 * Cambia la fecha seleccionada en el número de días especificado.
 * 
 * @param {number} dias - Número de días a sumar (positivo) o restar (negativo)
 */
function cambiarFecha(dias) {
    const fechaActual = _obtenerFechaInput();
    const nuevaFecha = _calcularNuevaFecha(fechaActual, dias);
    
    _actualizarFechaInput(nuevaFecha);
    aplicarFiltros();
}

/**
 * Actualiza automáticamente el estado de los boxes recargando la página.
 */
function actualizarEstadoBoxes() {
    location.reload();
}

// ==================== FUNCIONES AUXILIARES ====================

/**
 * Obtiene la fecha actual en formato ISO.
 * 
 * @returns {string} Fecha en formato 'YYYY-MM-DD'
 * @private
 */
function _obtenerFechaActual() {
    return document.querySelector('meta[name="fecha"]')?.content || 
           new Date().toISOString().split('T')[0];
}

/**
 * Construye la URL para obtener detalles de un box.
 * 
 * @param {string} boxId - ID del box
 * @param {string} fecha - Fecha en formato ISO
 * @returns {string} URL completa
 * @private
 */
function _construirUrlDetalle(boxId, fecha) {
    const detalleUrl = window.detalleBoxUrl || '/detalle-box/';
    return `${detalleUrl}?box_id=${boxId}&fecha=${fecha}`;
}

/**
 * Genera el contenido HTML del modal con la información del box.
 * 
 * @param {Object} data - Datos del box y agenda
 * @param {string} fecha - Fecha actual
 * @returns {string} HTML del contenido del modal
 * @private
 */
function _generarContenidoModal(data, fecha) {
    let contenido = `
        <div class="row">
            <div class="col-12">
                <h6><strong>Box ${data.box.id}</strong></h6>
                <p><strong>Pasillo:</strong> ${data.box.pasillo}</p>
                <p><strong>Capacidad:</strong> ${data.box.capacidad || 'No especificada'}</p>
                <p><strong>Fecha:</strong> ${fecha}</p>
                <p><strong>Estado actual:</strong> ${new Date().toLocaleTimeString()}</p>
                <hr>
    `;
    
    if (data.disponible) {
        contenido += `
            <div class="alert alert-success">
                <h6><i class="bi bi-check-circle"></i> Box Disponible</h6>
                <p>Este box está libre en este momento.</p>
            </div>
        `;
    } else {
        contenido += `
            <div class="alert alert-warning">
                <h6><i class="bi bi-clock"></i> Box Ocupado</h6>
                <p><strong>Profesional:</strong> ${data.agenda.profesional}</p>
                <p><strong>Especialidad:</strong> ${data.agenda.especialidad}</p>
                <p><strong>Tipo de Agenda:</strong> ${data.agenda.tipo_agenda}</p>
                <p><strong>Horario:</strong> ${data.agenda.hora_inicio} - ${data.agenda.hora_fin}</p>
            </div>
        `;
    }
    
    contenido += `</div></div>`;
    return contenido;
}

/**
 * Obtiene los filtros activos del formulario.
 * 
 * @returns {Object} Objeto con los filtros activos
 * @private
 */
function _obtenerFiltrosActivos() {
    const fecha = document.getElementById('fecha')?.value || '';
    const pasillo = document.getElementById('pasillo')?.value || '';
    const especialidad = document.getElementById('especialidad')?.value || '';
    
    return { fecha, pasillo, especialidad };
}

/**
 * Construye la URL con los filtros aplicados.
 * 
 * @param {Object} filtros - Filtros a aplicar
 * @returns {string} URL con parámetros de filtro
 * @private
 */
function _construirUrlConFiltros(filtros) {
    const params = new URLSearchParams();
    
    if (filtros.fecha) params.set('fecha', filtros.fecha);
    if (filtros.pasillo) params.set('pasillo', filtros.pasillo);
    if (filtros.especialidad) params.set('especialidad', filtros.especialidad);
    
    const queryString = params.toString();
    return window.location.pathname + (queryString ? '?' + queryString : '');
}

/**
 * Obtiene la fecha actual del input de fecha.
 * 
 * @returns {Date} Fecha actual del input
 * @private
 */
function _obtenerFechaInput() {
    const fechaInput = document.getElementById('fecha');
    return fechaInput ? new Date(fechaInput.value) : new Date();
}

/**
 * Calcula una nueva fecha sumando días a la fecha actual.
 * 
 * @param {Date} fechaActual - Fecha base
 * @param {number} dias - Días a sumar/restar
 * @returns {Date} Nueva fecha calculada
 * @private
 */
function _calcularNuevaFecha(fechaActual, dias) {
    const nuevaFecha = new Date(fechaActual);
    nuevaFecha.setDate(nuevaFecha.getDate() + dias);
    return nuevaFecha;
}

/**
 * Actualiza el input de fecha con una nueva fecha.
 * 
 * @param {Date} nuevaFecha - Nueva fecha a establecer
 * @private
 */
function _actualizarFechaInput(nuevaFecha) {
    const fechaInput = document.getElementById('fecha');
    if (fechaInput) {
        fechaInput.value = nuevaFecha.toISOString().split('T')[0];
    }
}

/**
 * Muestra un loader mientras se cargan los datos.
 * 
 * @private
 */
function _mostrarLoader() {
    // Implementar según el diseño del modal
    console.log('Cargando...');
}

/**
 * Oculta el loader.
 * 
 * @private
 */
function _ocultarLoader() {
    // Implementar según el diseño del modal
    console.log('Carga completada');
}

/**
 * Muestra un mensaje de error al usuario.
 * 
 * @param {string} mensaje - Mensaje de error a mostrar
 * @private
 */
function _mostrarError(mensaje) {
    console.error(mensaje);
    alert('Error: ' + mensaje);
}

/**
 * Muestra el modal con el contenido proporcionado.
 * 
 * @param {string} contenido - HTML del contenido del modal
 * @private
 */
function _mostrarModal(contenido) {
    // Buscar el modal en el DOM
    let modal = document.getElementById('detalleModal');
    
    if (!modal) {
        // Crear modal si no existe
        modal = _crearModal();
        document.body.appendChild(modal);
    }
    
    // Actualizar contenido del modal
    const modalBody = modal.querySelector('.modal-body');
    if (modalBody) {
        modalBody.innerHTML = contenido;
    }
    
    // Mostrar modal (Bootstrap)
    if (typeof bootstrap !== 'undefined' && bootstrap.Modal) {
        const modalInstance = new bootstrap.Modal(modal);
        modalInstance.show();
    } else {
        // Fallback para mostrar modal sin Bootstrap
        modal.style.display = 'block';
        modal.classList.add('show');
    }
}

/**
 * Crea el elemento modal dinámicamente.
 * 
 * @returns {HTMLElement} Elemento modal creado
 * @private
 */
function _crearModal() {
    const modal = document.createElement('div');
    modal.id = 'detalleModal';
    modal.className = 'modal fade';
    modal.innerHTML = `
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Detalle del Box</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <!-- Contenido dinámico -->
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cerrar</button>
                </div>
            </div>
        </div>
    `;
    return modal;
}

// ==================== INICIALIZACIÓN ====================

/**
 * Inicializa la aplicación cuando el DOM esté listo.
 */
document.addEventListener('DOMContentLoaded', function() {
    // Configurar actualización automática si está habilitada
    if (CONFIG.UPDATE_INTERVAL > 0) {
        setInterval(actualizarEstadoBoxes, CONFIG.UPDATE_INTERVAL);
    }
    
    // Agregar listeners a eventos específicos si es necesario
    console.log('Visualización General de Boxes inicializada');
});
