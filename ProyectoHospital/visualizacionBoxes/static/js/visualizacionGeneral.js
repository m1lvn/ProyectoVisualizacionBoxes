// ============================================================================
// VISUALIZACIÓN GENERAL DE BOXES - VERSIÓN FINAL ORGANIZADA
// ============================================================================

/**
 * Configuración global de la aplicación
 */
const CONFIG_GENERAL = {
    UPDATE_INTERVAL: 30000, // Actualización automática cada 30 segundos
    BOXES_POR_PAGINA: 48,   // 8 columnas x 6 filas
    DEBUG: false,           // Desactivar debug en producción
    DATE_FORMAT: "Y-m-d",
    LOCALE: "es"
};

// ============================================================================
// FUNCIONES PRINCIPALES
// ============================================================================

/**
 * Muestra el modal con detalles de un box específico
 * @param {string} boxId - ID del box a consultar
 * @param {boolean} disponible - Estado actual del box
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
 * Aplica los filtros seleccionados y recarga la página
 */
function aplicarFiltros() {
    const filtros = _obtenerFiltrosActivos();
    const url = _construirUrlConFiltros(filtros);
    window.location.href = url;
}

/**
 * Cambia la fecha seleccionada en el número de días especificado
 * @param {number} dias - Número de días a sumar (positivo) o restar (negativo)
 */
function cambiarFecha(dias) {
    const fechaActual = _obtenerFechaInput();
    const nuevaFecha = _calcularNuevaFecha(fechaActual, dias);
    
    _actualizarFechaInput(nuevaFecha);
    aplicarFiltros();
}

/**
 * Actualiza automáticamente el estado de los boxes
 */
function actualizarEstadoBoxes() {
    location.reload();
}

// ============================================================================
// FUNCIONES AUXILIARES PRIVADAS
// ============================================================================

/**
 * Obtiene la fecha actual en formato ISO
 * @returns {string} Fecha en formato 'YYYY-MM-DD'
 * @private
 */
function _obtenerFechaActual() {
    return document.querySelector('meta[name="fecha"]')?.content || 
           new Date().toISOString().split('T')[0];
}

/**
 * Construye la URL para obtener detalles de un box
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
 * Obtiene los filtros activos del formulario
 * @returns {Object} Objeto con los filtros activos
 * @private
 */
function _obtenerFiltrosActivos() {
    const fecha = document.getElementById('fecha')?.value || '';
    const pasillo = document.getElementById('pasillo')?.value || '';
    const codigoMedico = document.getElementById('codigoMedico')?.value || '';
    const codigoBox = document.getElementById('codigoBox')?.value || '';
    
    return { fecha, pasillo, medico: codigoMedico, box: codigoBox };
}

/**
 * Construye la URL con los filtros aplicados
 * @param {Object} filtros - Filtros a aplicar
 * @returns {string} URL con parámetros de filtro
 * @private
 */
function _construirUrlConFiltros(filtros) {
    const params = new URLSearchParams();
    
    if (filtros.fecha) params.set('fecha', filtros.fecha);
    if (filtros.pasillo) params.set('pasillo', filtros.pasillo);
    if (filtros.medico) params.set('medico', filtros.medico);
    if (filtros.box) params.set('box', filtros.box);
    
    const queryString = params.toString();
    return window.location.pathname + (queryString ? '?' + queryString : '');
}

/**
 * Obtiene la fecha actual del input de fecha
 * @returns {Date} Fecha actual del input
 * @private
 */
function _obtenerFechaInput() {
    const fechaInput = document.getElementById('fecha');
    return fechaInput ? new Date(fechaInput.value) : new Date();
}

/**
 * Calcula una nueva fecha sumando días a la fecha actual
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
 * Actualiza el input de fecha con una nueva fecha
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
 * Muestra un loader mientras se cargan los datos
 * @private
 */
function _mostrarLoader() {
    if (CONFIG_GENERAL.DEBUG) {
        console.log('Cargando...');
    }
}

/**
 * Oculta el loader
 * @private
 */
function _ocultarLoader() {
    if (CONFIG_GENERAL.DEBUG) {
        console.log('Carga completada');
    }
}

/**
 * Muestra un mensaje de error al usuario
 * @param {string} mensaje - Mensaje de error a mostrar
 * @private
 */
function _mostrarError(mensaje) {
    console.error(mensaje);
    alert('Error: ' + mensaje);
}

/**
 * Genera el contenido HTML del modal con la información del box
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
 * Muestra el modal con el contenido proporcionado
 * @param {string} contenido - HTML del contenido del modal
 * @private
 */
function _mostrarModal(contenido) {
    let modal = document.getElementById('detalleModal');
    
    if (!modal) {
        modal = _crearModal();
        document.body.appendChild(modal);
    }
    
    const modalBody = modal.querySelector('.modal-body');
    if (modalBody) {
        modalBody.innerHTML = contenido;
    }
    
    // Mostrar modal (Bootstrap)
    if (typeof bootstrap !== 'undefined' && bootstrap.Modal) {
        const modalInstance = new bootstrap.Modal(modal);
        modalInstance.show();
    } else {
        modal.style.display = 'block';
        modal.classList.add('show');
    }
}

/**
 * Crea el elemento modal dinámicamente
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

// ============================================================================
// FUNCIONES DE PAGINACIÓN
// ============================================================================

// Variables globales para paginación
let paginaActual = 1;
let totalPaginas = 1;

/**
 * Calcula el número total de páginas basado en los boxes disponibles
 */
function calcularPaginas() {
    const totalBoxes = document.querySelectorAll('.box-item').length;
    totalPaginas = Math.ceil(totalBoxes / CONFIG_GENERAL.BOXES_POR_PAGINA);
    return totalPaginas;
}

/**
 * Muestra la página anterior de boxes
 */
function paginaAnterior() {
    if (paginaActual > 1) {
        paginaActual--;
        mostrarPagina(paginaActual);
        actualizarIndicadoresPaginacion();
    }
}

/**
 * Muestra la página siguiente de boxes
 */
function paginaSiguiente() {
    calcularPaginas();
    if (paginaActual < totalPaginas) {
        paginaActual++;
        mostrarPagina(paginaActual);
        actualizarIndicadoresPaginacion();
    }
}

/**
 * Muestra los boxes correspondientes a una página específica
 * @param {number} pagina - Número de página a mostrar
 */
function mostrarPagina(pagina) {
    const boxes = document.querySelectorAll('.box-item');
    const inicio = (pagina - 1) * CONFIG_GENERAL.BOXES_POR_PAGINA;
    const fin = inicio + CONFIG_GENERAL.BOXES_POR_PAGINA;
    
    // Mostrar/ocultar boxes según la página
    boxes.forEach((box, index) => {
        box.style.display = (index >= inicio && index < fin) ? 'flex' : 'none';
    });
    
    // Efecto de transición
    const grid = document.querySelector('.boxes-grid');
    if (grid) {
        grid.style.opacity = '0.5';
        setTimeout(() => grid.style.opacity = '1', 200);
    }
    
    actualizarInfoResultados();
}

/**
 * Actualiza los indicadores visuales de paginación
 */
function actualizarIndicadoresPaginacion() {
    const btnAnterior = document.querySelector('.btn-nav:first-child');
    const btnSiguiente = document.querySelector('.btn-nav:last-child');
    const navegacion = document.querySelector('.navegacion-paginas');
    
    if (btnAnterior) {
        btnAnterior.disabled = paginaActual <= 1;
        btnAnterior.style.opacity = paginaActual <= 1 ? '0.5' : '1';
    }
    
    if (btnSiguiente) {
        btnSiguiente.disabled = paginaActual >= totalPaginas;
        btnSiguiente.style.opacity = paginaActual >= totalPaginas ? '0.5' : '1';
    }
    
    if (navegacion) {
        navegacion.setAttribute('data-pagina', `Página ${paginaActual} de ${totalPaginas}`);
    }
}

/**
 * Actualiza la información de resultados mostrados
 */
function actualizarInfoResultados() {
    const totalBoxes = document.querySelectorAll('.box-item').length;
    const boxesPaginaActual = Math.min(CONFIG_GENERAL.BOXES_POR_PAGINA, totalBoxes - (paginaActual - 1) * CONFIG_GENERAL.BOXES_POR_PAGINA);
    
    let indicadorResultados = document.querySelector('.indicador-resultados');
    if (!indicadorResultados) {
        indicadorResultados = document.createElement('div');
        indicadorResultados.className = 'indicador-resultados';
        const contenedorMatriz = document.querySelector('.contenedor-matriz');
        if (contenedorMatriz) {
            contenedorMatriz.insertBefore(indicadorResultados, contenedorMatriz.firstChild);
        }
    }
    
    indicadorResultados.innerHTML = `
        <span class="resultados-texto">
            Mostrando ${boxesPaginaActual} de ${totalBoxes} boxes
            ${totalPaginas > 1 ? `(Página ${paginaActual} de ${totalPaginas})` : ''}
        </span>
    `;
}

// ============================================================================
// FUNCIONES DE BÚSQUEDA Y FILTROS
// ============================================================================

/**
 * Busca por código médico
 */
function buscarPorMedico() {
    const codigoMedico = document.getElementById('codigoMedico')?.value.trim();
    
    if (!codigoMedico) {
        _mostrarError('Por favor, ingrese un código médico válido');
        return;
    }
    
    _mostrarLoader();
    
    const url = new URL(window.location);
    url.searchParams.set('medico', codigoMedico);
    window.location.href = url.toString();
}

/**
 * Busca por código de box
 */
function buscarPorBox() {
    const codigoBox = document.getElementById('codigoBox')?.value.trim();
    
    if (!codigoBox) {
        _mostrarError('Por favor, ingrese un código de box válido');
        return;
    }
    
    aplicarFiltros();
}

/**
 * Remueve un filtro específico
 * @param {string} tipoFiltro - Tipo de filtro a remover
 */
function removerFiltro(tipoFiltro) {
    const url = new URL(window.location);
    
    switch(tipoFiltro) {
        case 'pasillo':
            url.searchParams.delete('pasillo');
            break;
        case 'medico':
            url.searchParams.delete('medico');
            document.getElementById('codigoMedico').value = '';
            break;
        case 'box':
            url.searchParams.delete('box');
            document.getElementById('codigoBox').value = '';
            break;
    }
    
    window.location.href = url.toString();
}

/**
 * Limpia todos los filtros activos
 */
function limpiarTodosFiltros() {
    const url = new URL(window.location);
    const fecha = url.searchParams.get('fecha'); // Mantener la fecha
    
    url.search = '';
    if (fecha) {
        url.searchParams.set('fecha', fecha);
    }
    
    window.location.href = url.toString();
}

// ============================================================================
// INICIALIZACIÓN
// ============================================================================

/**
 * Inicializa la aplicación cuando el DOM esté listo
 */
document.addEventListener('DOMContentLoaded', function() {
    // Registrar funciones globalmente para uso en templates
    window.mostrarDetalle = mostrarDetalle;
    window.aplicarFiltros = aplicarFiltros;
    window.cambiarFecha = cambiarFecha;
    window.actualizarEstadoBoxes = actualizarEstadoBoxes;
    window.paginaAnterior = paginaAnterior;
    window.paginaSiguiente = paginaSiguiente;
    window.buscarPorMedico = buscarPorMedico;
    window.buscarPorBox = buscarPorBox;
    window.removerFiltro = removerFiltro;
    window.limpiarTodosFiltros = limpiarTodosFiltros;
    
    // Inicializar funcionalidades
    inicializarPaginacion();
    configurarEventosEnter();
    
    // Configurar actualización automática si está habilitada
    if (CONFIG_GENERAL.UPDATE_INTERVAL > 0) {
        setInterval(actualizarEstadoBoxes, CONFIG_GENERAL.UPDATE_INTERVAL);
    }
    
    if (CONFIG_GENERAL.DEBUG) {
        console.log('🏥 Visualización General de Boxes inicializada');
    }
});

/**
 * Inicializa la funcionalidad de paginación
 */
function inicializarPaginacion() {
    calcularPaginas();
    mostrarPagina(1);
    actualizarIndicadoresPaginacion();
    
    // Agregar estilos para animaciones
    if (!document.querySelector('#pulse-style')) {
        const style = document.createElement('style');
        style.id = 'pulse-style';
        style.textContent = `
            @keyframes pulse {
                0% { transform: scale(1); box-shadow: 0 0 0 0 rgba(13, 110, 253, 0.7); }
                50% { transform: scale(1.05); box-shadow: 0 0 0 10px rgba(13, 110, 253, 0); }
                100% { transform: scale(1); box-shadow: 0 0 0 0 rgba(13, 110, 253, 0); }
            }
        `;
        document.head.appendChild(style);
    }
}

/**
 * Configura eventos de teclado para los campos de búsqueda
 */
function configurarEventosEnter() {
    const codigoMedicoInput = document.getElementById('codigoMedico');
    const codigoBoxInput = document.getElementById('codigoBox');
    
    if (codigoMedicoInput) {
        codigoMedicoInput.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                buscarPorMedico();
            }
        });
    }
    
    if (codigoBoxInput) {
        codigoBoxInput.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                buscarPorBox();
            }
        });
    }
}
