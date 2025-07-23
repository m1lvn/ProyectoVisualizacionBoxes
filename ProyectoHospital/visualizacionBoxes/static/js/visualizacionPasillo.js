console.log('visualizacionPasillo.js cargado');
// ============================================================================
// VISUALIZACIÓN DE PASILLOS HOSPITALARIOS - CÓDIGO LIMPIO Y ORGANIZADO
// ============================================================================

/**
 * Configuración global
 */
const CONFIG_PASILLO = {
    DEBUG: false
};

// ============================================================================
// FUNCIONES DE FILTROS
// ============================================================================

/**
 * Aplica todos los filtros seleccionados
 */
function aplicarFiltrosPasillo() {
    const params = new URLSearchParams();
    // Obtener valores de filtros
    const pasillo = document.getElementById('pasillo')?.value;
    const fecha = document.getElementById('fecha')?.value;
    const jornada = document.getElementById('jornada')?.value;
    const codigoMedico = document.getElementById('codigoMedico')?.value.trim();
    const codigoBox = document.getElementById('codigoBox')?.value.trim();

    if (pasillo) params.set('pasillo', pasillo);
    if (fecha) params.set('fecha', fecha);
    if (jornada) params.set('jornada', jornada);
    if (codigoMedico) params.set('medico', codigoMedico);
    if (codigoBox) params.set('box', codigoBox);
    params.set('page', '1');
    window.location.href = window.location.pathname + '?' + params.toString();
}

/**
 * Busca por código de médico
 */
function buscarPorMedicoPasillo() {
    const codigoMedico = document.getElementById('codigoMedico')?.value.trim();
    if (!codigoMedico) {
        alert('Por favor, ingrese un código de médico válido');
        return;
    }
    // Tomar todos los filtros activos
    const pasillo = document.getElementById('pasillo')?.value;
    const fecha = document.getElementById('fecha')?.value;
    const jornada = document.getElementById('jornada')?.value;
    const codigoBox = document.getElementById('codigoBox')?.value.trim();
    const params = new URLSearchParams();
    if (pasillo) params.set('pasillo', pasillo);
    if (fecha) params.set('fecha', fecha);
    if (jornada) params.set('jornada', jornada);
    params.set('medico', codigoMedico);
    if (codigoBox) params.set('box', codigoBox);
    params.set('page', '1');
    window.location.href = window.location.pathname + '?' + params.toString();
}

/**
 * Busca por código de box
 */
function buscarPorBoxPasillo() {
    const codigoBox = document.getElementById('codigoBox')?.value.trim();
    if (!codigoBox) {
        alert('Por favor, ingrese un código de box válido');
        return;
    }
    // Tomar todos los filtros activos
    const pasillo = document.getElementById('pasillo')?.value;
    const fecha = document.getElementById('fecha')?.value;
    const jornada = document.getElementById('jornada')?.value;
    const codigoMedico = document.getElementById('codigoMedico')?.value.trim();
    const params = new URLSearchParams();
    if (pasillo) params.set('pasillo', pasillo);
    if (fecha) params.set('fecha', fecha);
    if (jornada) params.set('jornada', jornada);
    if (codigoMedico) params.set('medico', codigoMedico);
    params.set('box', codigoBox);
    params.set('page', '1');
    window.location.href = window.location.pathname + '?' + params.toString();
}

/**
 * Limpia la búsqueda de médico
 */
function limpiarBusquedaMedicoPasillo() {
    const url = new URL(window.location);
    url.searchParams.delete('medico');
    url.searchParams.set('page', '1');
    
    window.location.href = url.toString();
}

/**
 * Limpia la búsqueda de box
 */
function limpiarBusquedaBoxPasillo() {
    const url = new URL(window.location);
    url.searchParams.delete('box');
    url.searchParams.set('page', '1');
    
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
 */
function removerFiltroPasillo(tipoFiltro) {
    const params = new URLSearchParams(window.location.search);
    
    switch(tipoFiltro) {
        case 'pasillo':
            params.delete('pasillo');
            break;
        case 'jornada':
            params.delete('jornada');
            break;
        case 'fecha':
            params.delete('fecha');
            break;
        case 'medico':
            params.delete('medico');
            break;
        case 'box':
            params.delete('box');
            break;
    }
    
    params.set('page', '1');
    window.location.href = window.location.pathname + '?' + params.toString();
}

/**
 * Limpia todos los filtros
 */
function limpiarTodosFiltrosPasillo() {
    window.location.href = window.location.pathname;
}

// ============================================================================
// INICIALIZACIÓN
// ============================================================================

/**
 * Registra las funciones globalmente
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
 * Inicializa la aplicación
 */
document.addEventListener('DOMContentLoaded', function() {
    registrarFuncionesGlobales();

    // Inicializar línea roja de hora actual
    inicializarLineaHoraActual();

    if (CONFIG_PASILLO.DEBUG) {
        console.log('🏥 Sistema de filtros de pasillo cargado');
    }
});

// Registrar funciones inmediatamente también
registrarFuncionesGlobales();


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
