// ============================================================================
// VISUALIZACIÓN GENERAL DE BOXES - SISTEMA HOSPITALARIO
// ============================================================================

/**
 * Configuración global de la aplicación
 */
const CONFIG_GENERAL = {
    UPDATE_INTERVAL: 30000, // Actualización automática cada 30 segundos
    BOXES_POR_PAGINA: 40,   // Boxes por página para paginación
    DEBUG: false,           // Debug deshabilitado en producción
    DATE_FORMAT: "dd/mm/yyyy",
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
    const nombreProfesional = document.getElementById('nombreProfesional')?.value || '';
    const codigoBox = document.getElementById('codigoBox')?.value || '';
    
    return { fecha, pasillo, medico: nombreProfesional, box: codigoBox };
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
    
    // Preservar página actual si no es una búsqueda nueva
    const currentPage = new URLSearchParams(window.location.search).get('page');
    if (currentPage && !filtros.resetPage) {
        params.set('page', currentPage);
    }
    
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

/**
 * Navega a la página anterior
 */
function paginaAnterior() {
    const params = new URLSearchParams(window.location.search);
    const paginaActual = parseInt(params.get('page') || '1');
    
    if (paginaActual > 1) {
        params.set('page', paginaActual - 1);
        window.location.href = window.location.pathname + '?' + params.toString();
    }
}

/**
 * Navega a la página siguiente
 */
function paginaSiguiente() {
    const params = new URLSearchParams(window.location.search);
    const paginaActual = parseInt(params.get('page') || '1');
    
    // Obtener total de páginas del DOM
    const infoPagina = document.querySelector('.info-pagina span');
    if (infoPagina) {
        const match = infoPagina.textContent.match(/Página (\d+) de (\d+)/);
        if (match) {
            const totalPaginas = parseInt(match[2]);
            if (paginaActual < totalPaginas) {
                params.set('page', paginaActual + 1);
                window.location.href = window.location.pathname + '?' + params.toString();
            }
            return;
        }
    }
    
    // Fallback: intentar navegar
    params.set('page', paginaActual + 1);
    window.location.href = window.location.pathname + '?' + params.toString();
}

// ============================================================================
// FUNCIONES DE BÚSQUEDA Y FILTROS
// ============================================================================

/**
 * Busca por nombre de profesional con autocompletado
 */
function buscarPorProfesional() {
    const nombreProfesional = document.getElementById('nombreProfesional')?.value.trim();
    
    if (!nombreProfesional) {
        _mostrarError('Por favor, ingrese un nombre de profesional válido');
        return;
    }
    
    _mostrarLoader();
    
    const url = new URL(window.location);
    url.searchParams.set('medico', nombreProfesional);
    window.location.href = url.toString();
}

/**
 * Busca por código de box (versión mejorada)
 */
function buscarPorBoxMejorado() {
    const codigoBox = document.getElementById('codigoBox')?.value.trim();
    
    if (!codigoBox) {
        _mostrarError('Por favor, ingrese un código de box válido');
        return;
    }
    
    const url = new URL(window.location);
    url.searchParams.set('box', codigoBox);
    url.searchParams.delete('page'); // Reset pagination on new search
    window.location.href = url.toString();
}

/**
 * Busca por código de box
 */
function buscarPorBox() {
    buscarPorBoxMejorado();
}

/**
 * Limpia la búsqueda de profesional
 */
function limpiarBusquedaProfesional() {
    const url = new URL(window.location);
    url.searchParams.delete('medico');
    document.getElementById('nombreProfesional').value = '';
    _ocultarDropdownProfesionales();
    window.location.href = url.toString();
}

/**
 * Limpia la búsqueda de box
 */
function limpiarBusquedaBox() {
    const url = new URL(window.location);
    url.searchParams.delete('box');
    document.getElementById('codigoBox').value = '';
    window.location.href = url.toString();
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
            document.getElementById('nombreProfesional').value = '';
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
    window.buscarPorProfesional = buscarPorProfesional;
    window.buscarPorBox = buscarPorBox;
    window.buscarPorBoxMejorado = buscarPorBoxMejorado;
    window.limpiarBusquedaProfesional = limpiarBusquedaProfesional;
    window.limpiarBusquedaBox = limpiarBusquedaBox;
    window.removerFiltro = removerFiltro;
    window.limpiarTodosFiltros = limpiarTodosFiltros;
    
    // Inicializar funcionalidades
    configurarEventosEnter();
    
    // Configurar actualización automática si está habilitada
    if (CONFIG_GENERAL.UPDATE_INTERVAL > 0) {
        setInterval(actualizarEstadoBoxes, CONFIG_GENERAL.UPDATE_INTERVAL);
    }
    
    // Configurar autocompletado de profesionales
    configurarAutocompletadoProfesionales();
    
    console.log('🏥 Visualización General de Boxes inicializada');
});


/**
 * Configura eventos de teclado para los campos de búsqueda
 */
function configurarEventosEnter() {
    const nombreProfesionalInput = document.getElementById('nombreProfesional');
    const codigoBoxInput = document.getElementById('codigoBox');
    
    if (nombreProfesionalInput) {
        nombreProfesionalInput.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                buscarPorProfesional();
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

// ============================================================================
// FUNCIONES DE AUTOCOMPLETADO DE PROFESIONALES
// ============================================================================

/**
 * Configura el autocompletado para búsqueda de profesionales
 */
function configurarAutocompletadoProfesionales() {
    const input = document.getElementById('nombreProfesional');
    if (!input) return;
    
    let timeoutId;
    
    input.addEventListener('input', function(e) {
        clearTimeout(timeoutId);
        const termino = e.target.value.trim();
        
        if (termino.length < 2) {
            _ocultarDropdownProfesionales();
            return;
        }
        
        // Debounce de 300ms para evitar muchas peticiones
        timeoutId = setTimeout(() => {
            _buscarProfesionales(termino);
        }, 300);
    });
    
    // Ocultar dropdown al perder foco
    input.addEventListener('blur', function() {
        setTimeout(_ocultarDropdownProfesionales, 200);
    });
    
    // Manejar navegación con teclado
    input.addEventListener('keydown', function(e) {
        _manejarTecladoDropdown(e);
    });
}

/**
 * Busca profesionales por nombre mediante AJAX
 * @param {string} termino - Término de búsqueda
 * @private
 */
function _buscarProfesionales(termino) {
    if (!window.profesionalesUrls || !window.profesionalesUrls.buscar_medicos) {
        console.error('URL de búsqueda de profesionales no configurada');
        return;
    }
    
    const url = `${window.profesionalesUrls.buscar_medicos}?q=${encodeURIComponent(termino)}`;
    
    fetch(url)
        .then(response => response.json())
        .then(data => {
            _mostrarDropdownProfesionales(data.medicos);
        })
        .catch(error => {
            console.error('Error al buscar profesionales:', error);
            _ocultarDropdownProfesionales();
        });
}

/**
 * Muestra el dropdown con las sugerencias de profesionales
 * @param {Array} profesionales - Lista de profesionales encontrados
 * @private
 */
function _mostrarDropdownProfesionales(profesionales) {
    const dropdown = document.getElementById('profesionalesDropdown');
    if (!dropdown || !profesionales.length) {
        _ocultarDropdownProfesionales();
        return;
    }
    
    dropdown.innerHTML = '';
    
    profesionales.forEach((profesional, index) => {
        const option = document.createElement('div');
        option.className = 'profesional-option';
        option.dataset.index = index;
        option.innerHTML = `
            <div class="profesional-nombre">${profesional.nombre}</div>
            <div class="profesional-especialidad">${profesional.especialidad}</div>
        `;
        
        option.addEventListener('click', () => {
            _seleccionarProfesional(profesional.nombre);
        });
        
        dropdown.appendChild(option);
    });
    
    dropdown.style.display = 'block';
}

/**
 * Oculta el dropdown de profesionales
 * @private
 */
function _ocultarDropdownProfesionales() {
    const dropdown = document.getElementById('profesionalesDropdown');
    if (dropdown) {
        dropdown.style.display = 'none';
        dropdown.innerHTML = '';
    }
}

/**
 * Selecciona un profesional del dropdown
 * @param {string} nombreProfesional - Nombre del profesional seleccionado
 * @private
 */
function _seleccionarProfesional(nombreProfesional) {
    const input = document.getElementById('nombreProfesional');
    if (input) {
        input.value = nombreProfesional;
        _ocultarDropdownProfesionales();
        buscarPorProfesional();
    }
}

/**
 * Maneja la navegación del dropdown con teclado
 * @param {KeyboardEvent} e - Evento de teclado
 * @private
 */
function _manejarTecladoDropdown(e) {
    const dropdown = document.getElementById('medicosDropdown');
    if (!dropdown || dropdown.style.display === 'none') return;
    
    const opciones = dropdown.querySelectorAll('.medico-option');
    const actual = dropdown.querySelector('.medico-option.selected');
    let indice = actual ? parseInt(actual.dataset.index) : -1;
    
    switch (e.key) {
        case 'ArrowDown':
            e.preventDefault();
            indice = Math.min(indice + 1, opciones.length - 1);
            _resaltarOpcion(opciones, indice);
            break;
            
        case 'ArrowUp':
            e.preventDefault();
            indice = Math.max(indice - 1, 0);
            _resaltarOpcion(opciones, indice);
            break;
            
        case 'Enter':
            e.preventDefault();
            if (actual) {
                const nombre = actual.querySelector('.medico-nombre').textContent;
                _seleccionarMedico(nombre);
            }
            break;
            
        case 'Escape':
            _ocultarDropdownMedicos();
            break;
    }
}

/**
 * Resalta una opción específica del dropdown
 * @param {NodeList} opciones - Lista de opciones
 * @param {number} indice - Índice a resaltar
 * @private
 */
function _resaltarOpcion(opciones, indice) {
    opciones.forEach((opcion, i) => {
        if (i === indice) {
            opcion.classList.add('selected');
        } else {
            opcion.classList.remove('selected');
        }
    });
}
