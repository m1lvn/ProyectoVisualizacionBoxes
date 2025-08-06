// ============================================================================
// VISUALIZACIÓN DE PASILLOS - SISTEMA HOSPITALARIO
// ============================================================================

/**
 * Configuración global de la aplicación de pasillos
 */
const CONFIG_PASILLO = {
    DEBUG: false,           // Debug deshabilitado en producción
    BOXES_POR_PAGINA: 8,    // Boxes por página para paginación
    UPDATE_INTERVAL: 30000, // Actualización automática cada 30 segundos
    DATE_FORMAT: "Y-m-d",
    LOCALE: "es"
};

// ============================================================================
// FUNCIONES DE FILTROS Y BÚSQUEDA
// ============================================================================

/**
 * Aplica todos los filtros seleccionados y navega a la página
 */
function aplicarFiltrosPasillo() {
    const filtros = _obtenerFiltrosActivosPasillo();
    const url = _construirUrlConFiltrosPasillo(filtros);
    window.location.href = url;
}

/**
 * Busca por nombre de médico
 */
function buscarPorMedicoPasillo() {
    const nombreMedico = document.getElementById('nombreMedico')?.value.trim();
    
    if (!nombreMedico) {
        _mostrarErrorPasillo('Por favor, ingrese un nombre de médico válido');
        return;
    }
    
    const filtros = _obtenerFiltrosActivosPasillo();
    filtros.medico = nombreMedico;
    filtros.page = '1'; // Reset página en nueva búsqueda
    
    const url = _construirUrlConFiltrosPasillo(filtros);
    window.location.href = url;
}

/**
 * Busca por código de box
 */
function buscarPorBoxPasillo() {
    const codigoBox = document.getElementById('codigoBox')?.value.trim();
    
    if (!codigoBox) {
        _mostrarErrorPasillo('Por favor, ingrese un código de box válido');
        return;
    }
    
    const filtros = _obtenerFiltrosActivosPasillo();
    filtros.box = codigoBox;
    filtros.page = '1'; // Reset página en nueva búsqueda
    
    const url = _construirUrlConFiltrosPasillo(filtros);
    window.location.href = url;
}

/**
 * Limpia la búsqueda de médico
 */
function limpiarBusquedaMedicoPasillo() {
    const url = new URL(window.location);
    url.searchParams.delete('medico');
    url.searchParams.set('page', '1');
    
    // Limpiar campo de input
    const inputMedico = document.getElementById('nombreMedico');
    if (inputMedico) {
        inputMedico.value = '';
    }
    
    // Ocultar dropdown de sugerencias
    _ocultarDropdownMedicosPasillo();
    
    window.location.href = url.toString();
}

/**
 * Limpia la búsqueda de box
 */
function limpiarBusquedaBoxPasillo() {
    const url = new URL(window.location);
    url.searchParams.delete('box');
    url.searchParams.set('page', '1');
    
    // Limpiar campo de input
    const inputBox = document.getElementById('codigoBox');
    if (inputBox) {
        inputBox.value = '';
    }
    
    window.location.href = url.toString();
}

// ============================================================================
// FUNCIONES DE PAGINACIÓN
// ============================================================================

/**
 * Navega a la página anterior
 */
function paginaAnteriorPasillo() {
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
function paginaSiguientePasillo() {
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
// FUNCIONES DE GESTIÓN DE FILTROS
// ============================================================================

/**
 * Remueve un filtro específico
 * @param {string} tipoFiltro - Tipo de filtro a remover
 */
function removerFiltroPasillo(tipoFiltro) {
    const url = new URL(window.location);
    
    switch(tipoFiltro) {
        case 'pasillo':
            url.searchParams.delete('pasillo');
            break;
        case 'jornada':
            url.searchParams.delete('jornada');
            break;
        case 'fecha':
            url.searchParams.delete('fecha');
            break;
        case 'medico':
            url.searchParams.delete('medico');
            // Limpiar campo de input
            const inputMedico = document.getElementById('nombreMedico');
            if (inputMedico) inputMedico.value = '';
            break;
        case 'box':
            url.searchParams.delete('box');
            // Limpiar campo de input
            const inputBox = document.getElementById('codigoBox');
            if (inputBox) inputBox.value = '';
            break;
    }
    
    url.searchParams.set('page', '1');
    window.location.href = url.toString();
}

/**
 * Limpia todos los filtros
 */
function limpiarTodosFiltrosPasillo() {
    // Limpiar campos de input
    const inputMedico = document.getElementById('nombreMedico');
    const inputBox = document.getElementById('codigoBox');
    
    if (inputMedico) inputMedico.value = '';
    if (inputBox) inputBox.value = '';
    
    window.location.href = window.location.pathname;
}

// ============================================================================
// FUNCIONES AUXILIARES PRIVADAS
// ============================================================================

/**
 * Obtiene los filtros activos del formulario
 * @returns {Object} Objeto con los filtros activos
 * @private
 */
function _obtenerFiltrosActivosPasillo() {
    const pasillo = document.getElementById('pasillo')?.value || '';
    const fecha = document.getElementById('fecha')?.value || '';
    const jornada = document.getElementById('jornada')?.value || '';
    const medico = document.getElementById('nombreMedico')?.value.trim() || '';
    const box = document.getElementById('codigoBox')?.value.trim() || '';
    
    return { pasillo, fecha, jornada, medico, box };
}

/**
 * Construye la URL con los filtros aplicados
 * @param {Object} filtros - Filtros a aplicar
 * @returns {string} URL con parámetros de filtro
 * @private
 */
function _construirUrlConFiltrosPasillo(filtros) {
    const params = new URLSearchParams();
    
    if (filtros.pasillo) params.set('pasillo', filtros.pasillo);
    if (filtros.fecha) params.set('fecha', filtros.fecha);
    if (filtros.jornada) params.set('jornada', filtros.jornada);
    if (filtros.medico) params.set('medico', filtros.medico);
    if (filtros.box) params.set('box', filtros.box);
    if (filtros.page) params.set('page', filtros.page);
    
    const queryString = params.toString();
    return window.location.pathname + (queryString ? '?' + queryString : '');
}

/**
 * Muestra un mensaje de error al usuario
 * @param {string} mensaje - Mensaje de error a mostrar
 * @private
 */
function _mostrarErrorPasillo(mensaje) {
    if (CONFIG_PASILLO.DEBUG) {
        console.error(mensaje);
    }
    alert('Error: ' + mensaje);
}

// ============================================================================
// INICIALIZACIÓN Y REGISTRO DE FUNCIONES
// ============================================================================

/**
 * Registra las funciones globalmente para uso en templates
 */
function registrarFuncionesGlobales() {
    window.aplicarFiltrosPasillo = aplicarFiltrosPasillo;
    window.buscarPorMedicoPasillo = buscarPorMedicoPasillo;
    window.buscarPorBoxPasillo = buscarPorBoxPasillo;
    window.limpiarBusquedaMedicoPasillo = limpiarBusquedaMedicoPasillo;
    window.limpiarBusquedaBoxPasillo = limpiarBusquedaBoxPasillo;
    window.paginaAnteriorPasillo = paginaAnteriorPasillo;
    window.paginaSiguientePasillo = paginaSiguientePasillo;
    window.removerFiltroPasillo = removerFiltroPasillo;
    window.limpiarTodosFiltrosPasillo = limpiarTodosFiltrosPasillo;
}

/**
 * Inicializa la aplicación cuando el DOM esté listo
 */
document.addEventListener('DOMContentLoaded', function() {
    // Registrar funciones globalmente
    registrarFuncionesGlobales();
    
    // Inicializar línea de hora actual
    inicializarLineaHoraActual();
    
    // Configurar eventos de teclado
    configurarEventosEnterPasillo();
    
    // Configurar autocompletado de médicos
    configurarAutocompletadoMedicosPasillo();
    
    if (CONFIG_PASILLO.DEBUG) {
        console.log('🏥 Visualización de Pasillo inicializada');
    }
});

// Registrar funciones inmediatamente para compatibilidad
registrarFuncionesGlobales();

/**
 * Configura eventos de teclado para los campos de búsqueda
 */
function configurarEventosEnterPasillo() {
    const nombreMedicoInput = document.getElementById('nombreMedico');
    const codigoBoxInput = document.getElementById('codigoBox');
    
    if (nombreMedicoInput) {
        nombreMedicoInput.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                buscarPorMedicoPasillo();
            }
        });
    }
    
    if (codigoBoxInput) {
        codigoBoxInput.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                buscarPorBoxPasillo();
            }
        });
    }
}

// ============================================================================
// FUNCIONES DE LÍNEA DE HORA ACTUAL
// ============================================================================
/**
 * Inicializa y gestiona la línea roja que indica la hora actual en la matriz de boxes.
 */
function inicializarLineaHoraActual() {
    const grilla = document.querySelector('.contenedor-tabla');
    if (!grilla) { return; }
    const tableResponsive = grilla.querySelector('.table-responsive');
    if (!tableResponsive) { return; }
    const tabla = tableResponsive.querySelector('.table-boxes');
    if (!tabla) { return; }

    // Asegura que la tabla tenga position: relative
    tabla.style.position = 'relative';

    let linea = tabla.querySelector('#linea-hora-actual');
    if (!linea) {
        linea = crearLineaHoraActual();
        tabla.appendChild(linea);
    }

    function obtenerMinutosActuales(horaInicio) {
        const ahora = new Date();
        return (ahora.getHours() - horaInicio) * 60 + ahora.getMinutes();
    }

    function obtenerAlturaFila(tabla) {
        const filas = tabla.querySelectorAll('tbody tr');
        if (filas.length === 0) return 0;
        return filas[0].offsetHeight;
    }

    function calcularPosicionLinea({horaInicio, horaFin, tabla, grillaHeight}) {
        const ahora = new Date();
        const horaActual = ahora.getHours();
        const minutosActual = ahora.getMinutes();
        // Filtra solo filas visibles
        const filas = Array.from(tabla.querySelectorAll('tbody tr')).filter(fila => fila.offsetParent !== null);
        let horasFilas = filas.map(fila => {
            const celdaHora = fila.querySelector('.celda-hora');
            if (!celdaHora) return null;
            let texto = '';
            const strong = celdaHora.querySelector('strong');
            if (strong) {
                texto = strong.textContent.trim();
            } else {
                texto = celdaHora.textContent.trim();
            }
            const match = texto.match(/(\d{1,2}):(\d{2})/);
            if (!match) return null;
            const h = Number(match[1]);
            const m = Number(match[2]);
            return h + m / 60;
        });
        const horaDecimal = horaActual + minutosActual / 60;
        let idx = -1;
        for (let i = 0; i < horasFilas.length; i++) {
            if (horasFilas[i] !== null && horasFilas[i] <= horaDecimal) {
                idx = i;
            }
        }
        let top = 0;
        if (idx === -1) {
            top = 0;
        } else {
            // Interpolación dentro del bloque horario
            const filaActual = filas[idx];
            const alturaFila = filaActual.offsetHeight;
            // ¿Cuántos minutos han pasado desde el inicio del bloque?
            const minutosEnBloque = (horaDecimal - horasFilas[idx]) * 60;
            // ¿Cuántos minutos dura el bloque?
            let minutosBloque = 30;
            if (idx + 1 < horasFilas.length) {
                minutosBloque = (horasFilas[idx + 1] - horasFilas[idx]) * 60;
            }
            // Calcula el desplazamiento proporcional
            const desplazamiento = Math.max(0, Math.min(alturaFila, (minutosEnBloque / minutosBloque) * alturaFila));
            top = filaActual.offsetTop + desplazamiento;
        }
        top = Math.max(0, Math.min(tabla.offsetHeight - 2, top));
        return top;
    }

    function actualizarLinea() {
        const horaInicio = 8; // Ajusta según tu sistema
        const horaFin = 20;  // Ajusta según tu sistema
        const top = calcularPosicionLinea({horaInicio, horaFin, tabla, grillaHeight: tabla.offsetHeight});
        linea.style.top = top + 'px';
    }

    actualizarLinea();
    setInterval(actualizarLinea, 60000);
}

/**
 * Crea el elemento visual de la línea roja de hora actual.
 */
function crearLineaHoraActual() {
    const linea = document.createElement('div');
    linea.id = 'linea-hora-actual';
    linea.style.position = 'absolute';
    linea.style.left = '0';
    linea.style.right = '0';
    linea.style.height = '2px';
    linea.style.background = 'red';
    linea.style.zIndex = '10';
    return linea;
}

// ============================================================================
// FUNCIONES DE AUTOCOMPLETADO DE MÉDICOS - PASILLO
// ============================================================================

/**
 * Configura el autocompletado para búsqueda de médicos en pasillo
 */
function configurarAutocompletadoMedicosPasillo() {
    const input = document.getElementById('nombreMedico');
    if (!input) return;
    
    let timeoutId;
    
    input.addEventListener('input', function(e) {
        clearTimeout(timeoutId);
        const termino = e.target.value.trim();
        
        if (termino.length < 2) {
            _ocultarDropdownMedicosPasillo();
            return;
        }
        
        // Debounce de 300ms para evitar muchas peticiones
        timeoutId = setTimeout(() => {
            _buscarMedicosPasillo(termino);
        }, 300);
    });
    
    // Ocultar dropdown al perder foco
    input.addEventListener('blur', function() {
        setTimeout(_ocultarDropdownMedicosPasillo, 200);
    });
    
    // Manejar navegación con teclado
    input.addEventListener('keydown', function(e) {
        _manejarTecladoDropdownPasillo(e);
    });
}

/**
 * Busca médicos por nombre mediante AJAX para pasillo
 * @param {string} termino - Término de búsqueda
 * @private
 */
function _buscarMedicosPasillo(termino) {
    if (!window.medicosUrls || !window.medicosUrls.buscar_medicos) {
        console.error('URL de búsqueda de médicos no configurada');
        return;
    }
    
    const url = `${window.medicosUrls.buscar_medicos}?q=${encodeURIComponent(termino)}`;
    
    fetch(url)
        .then(response => response.json())
        .then(data => {
            _mostrarDropdownMedicosPasillo(data.medicos);
        })
        .catch(error => {
            console.error('Error al buscar médicos:', error);
            _ocultarDropdownMedicosPasillo();
        });
}

/**
 * Muestra el dropdown con las sugerencias de médicos para pasillo
 * @param {Array} medicos - Lista de médicos encontrados
 * @private
 */
function _mostrarDropdownMedicosPasillo(medicos) {
    const dropdown = document.getElementById('medicosDropdownPasillo');
    if (!dropdown || !medicos.length) {
        _ocultarDropdownMedicosPasillo();
        return;
    }
    
    dropdown.innerHTML = '';
    
    medicos.forEach((medico, index) => {
        const option = document.createElement('div');
        option.className = 'medico-option';
        option.dataset.index = index;
        option.innerHTML = `
            <div class="medico-nombre">${medico.nombre}</div>
            <div class="medico-especialidad">${medico.especialidad}</div>
        `;
        
        option.addEventListener('click', () => {
            _seleccionarMedicoPasillo(medico.nombre);
        });
        
        dropdown.appendChild(option);
    });
    
    dropdown.style.display = 'block';
}

/**
 * Oculta el dropdown de médicos para pasillo
 * @private
 */
function _ocultarDropdownMedicosPasillo() {
    const dropdown = document.getElementById('medicosDropdownPasillo');
    if (dropdown) {
        dropdown.style.display = 'none';
        dropdown.innerHTML = '';
    }
}

/**
 * Selecciona un médico del dropdown para pasillo
 * @param {string} nombreMedico - Nombre del médico seleccionado
 * @private
 */
function _seleccionarMedicoPasillo(nombreMedico) {
    const input = document.getElementById('nombreMedico');
    if (input) {
        input.value = nombreMedico;
        _ocultarDropdownMedicosPasillo();
        buscarPorMedicoPasillo();
    }
}

/**
 * Maneja la navegación del dropdown con teclado para pasillo
 * @param {KeyboardEvent} e - Evento de teclado
 * @private
 */
function _manejarTecladoDropdownPasillo(e) {
    const dropdown = document.getElementById('medicosDropdownPasillo');
    if (!dropdown || dropdown.style.display === 'none') return;
    
    const opciones = dropdown.querySelectorAll('.medico-option');
    const actual = dropdown.querySelector('.medico-option.selected');
    let indice = actual ? parseInt(actual.dataset.index) : -1;
    
    switch (e.key) {
        case 'ArrowDown':
            e.preventDefault();
            indice = Math.min(indice + 1, opciones.length - 1);
            _resaltarOpcionPasillo(opciones, indice);
            break;
            
        case 'ArrowUp':
            e.preventDefault();
            indice = Math.max(indice - 1, 0);
            _resaltarOpcionPasillo(opciones, indice);
            break;
            
        case 'Enter':
            e.preventDefault();
            if (actual) {
                const nombre = actual.querySelector('.medico-nombre').textContent;
                _seleccionarMedicoPasillo(nombre);
            }
            break;
            
        case 'Escape':
            _ocultarDropdownMedicosPasillo();
            break;
    }
}

/**
 * Resalta una opción específica del dropdown para pasillo
 * @param {NodeList} opciones - Lista de opciones
 * @param {number} indice - Índice a resaltar
 * @private
 */
function _resaltarOpcionPasillo(opciones, indice) {
    opciones.forEach((opcion, i) => {
        if (i === indice) {
            opcion.classList.add('selected');
        } else {
            opcion.classList.remove('selected');
        }
    });
}
