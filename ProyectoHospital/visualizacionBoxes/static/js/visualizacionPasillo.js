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
    
    // Agregar parámetros no vacíos
    if (pasillo) params.set('pasillo', pasillo);
    if (fecha) params.set('fecha', fecha);
    if (jornada) params.set('jornada', jornada);
    
    // Mantener filtros de búsqueda actuales
    const urlActual = new URL(window.location);
    const medico = urlActual.searchParams.get('medico');
    const box = urlActual.searchParams.get('box');
    
    if (medico) params.set('medico', medico);
    if (box) params.set('box', box);
    
    // Resetear a página 1
    params.set('page', '1');
    
    // Navegar a la nueva URL
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
    
    const url = new URL(window.location);
    url.searchParams.set('medico', codigoMedico);
    url.searchParams.set('page', '1');
    
    window.location.href = url.toString();
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
    
    const url = new URL(window.location);
    url.searchParams.set('box', codigoBox);
    url.searchParams.set('page', '1');
    
    window.location.href = url.toString();
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
    
    if (CONFIG_PASILLO.DEBUG) {
        console.log('🏥 Sistema de filtros de pasillo cargado');
    }
});

// Registrar funciones inmediatamente también
registrarFuncionesGlobales();
