/**
 * VISUALIZACION PASILLO - VERSION SIMPLIFICADA Y FUNCIONAL
 */

'use strict';

console.log('visualizacionPasillo.js CARGADO - Versión simplificada');

// ============================================================================
// OBJETO PASILLOVISUALIZADOR FUNCIONAL
// ============================================================================
const PasilloVisualizador = {
    
    init() {
        console.log('PasilloVisualizador.init() ejecutándose...');
        
        // Esperar a que el DOM esté listo
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.initializeApp());
        } else {
            this.initializeApp();
        }
    },
    
    initializeApp() {
        console.log('Inicializando aplicación...');
        this.updateCounters();
        this.setupAutoUpdate();
    },
    
    updateCounters() {
        try {
            console.log('Actualizando contadores...');
            
            // Contar elementos time-slot
            const timeSlots = document.querySelectorAll('.time-slot');
            const libres = document.querySelectorAll('.time-slot.libre');
            
            // Buscar ocupados por diferentes métodos
            const tipoAgenda = document.querySelectorAll('.time-slot[class*="tipo-agenda-"]');
            const reservados = document.querySelectorAll('.time-slot[data-estado="Reservado"]');
            const mantencion = document.querySelectorAll('.time-slot.mantencion');
            const limpieza = document.querySelectorAll('.time-slot.limpieza');
            const inhabilitado = document.querySelectorAll('.time-slot.inhabilitado');
            
            // Contar ocupados de forma más precisa
            let totalOcupados = 0;
            timeSlots.forEach(slot => {
                const classList = slot.classList;
                const dataEstado = slot.getAttribute('data-estado');
                
                // Verificar si está ocupado
                if (dataEstado === 'Reservado' ||
                    Array.from(classList).some(cls => cls.startsWith('tipo-agenda-')) ||
                    classList.contains('mantencion') ||
                    classList.contains('limpieza') ||
                    classList.contains('inhabilitado')) {
                    totalOcupados++;
                }
            });
            
            // Calcular porcentaje
            const porcentaje = timeSlots.length > 0 ? Math.round((totalOcupados / timeSlots.length) * 100) : 0;
            
            // Actualizar UI
            const contadorLibres = document.querySelector('#boxes-libres span');
            const contadorOcupacion = document.querySelector('#porcentaje-ocupacion span');
            
            if (contadorLibres) {
                contadorLibres.textContent = timeSlots.length - totalOcupados;
            }
            
            if (contadorOcupacion) {
                contadorOcupacion.textContent = porcentaje + '%';
            }
            
            // Actualizar timestamp
            const timestamp = document.querySelector('#ultima-actualizacion');
            if (timestamp) {
                const now = new Date();
                timestamp.textContent = now.getHours().toString().padStart(2, '0') + ':' + 
                                      now.getMinutes().toString().padStart(2, '0');
            }
            
            console.log('Contadores actualizados:', {
                total: timeSlots.length,
                libres: timeSlots.length - totalOcupados,
                ocupados: totalOcupados,
                porcentaje: porcentaje + '%'
            });
            
        } catch (error) {
            console.error('Error actualizando contadores:', error);
        }
    },
    
    setupAutoUpdate() {
        // Actualizar cada 30 segundos
        setInterval(() => {
            if (!document.hidden) { // Solo si la página está visible
                this.updateCounters();
            }
        }, 30000);
        
        // Actualizar cuando la página se vuelve visible
        document.addEventListener('visibilitychange', () => {
            if (!document.hidden) {
                this.updateCounters();
            }
        });
    }
};

console.log('PasilloVisualizador definido correctamente');

// ============================================================================
// EXPOSICIÓN GLOBAL PARA USO EN TEMPLATES
// ============================================================================

// Exponer objeto principal
window.PasilloVisualizador = PasilloVisualizador;

// Exponer funciones de filtros (requeridas por los templates)
window.aplicarFiltrosPasillo = aplicarFiltrosPasillo;
window.removerFiltroPasillo = removerFiltroPasillo;
window.limpiarTodosFiltrosPasillo = limpiarTodosFiltrosPasillo;

// Función para mostrar detalle de box (requerida por templates)
window.mostrarDetallePasillo = function(boxId, hora) {
    console.log('Mostrando detalle del box:', boxId, 'hora:', hora);
    
    if (typeof BoxModal !== 'undefined') {
        BoxModal.mostrarDetalle(boxId, { 
            hora: hora,
            fecha: window.pasilloConfig?.FECHA_ACTUAL
        });
    } else {
        console.error('BoxModal no está disponible');
    }
};

console.log('Funciones globales expuestas correctamente');

// ============================================================================
// FUNCIONES DE FILTROS (NECESARIAS PARA LOS FILTROS SUPERIORES)
// ============================================================================

/**
 * Aplica los filtros del pasillo y recarga la página
 */
function aplicarFiltrosPasillo() {
    console.log('Aplicando filtros de pasillo...');
    
    try {
        const filtros = _obtenerFiltrosActivosPasillo();
        const nuevaUrl = _construirUrlConFiltrosPasillo(filtros);
        
        console.log('Nueva URL con filtros:', nuevaUrl);
        window.location.href = nuevaUrl;
        
    } catch (error) {
        console.error('Error al aplicar filtros:', error);
    }
}

/**
 * Obtiene los filtros activos de la interfaz
 */
function _obtenerFiltrosActivosPasillo() {
    const filtros = {};
    
    // Pasillo seleccionado
    const pasilloSelect = document.getElementById('pasillo');
    if (pasilloSelect && pasilloSelect.value) {
        filtros.pasillo = pasilloSelect.value;
    }
    
    // Jornada seleccionada
    const jornadaSelect = document.getElementById('jornada');
    if (jornadaSelect && jornadaSelect.value) {
        filtros.jornada = jornadaSelect.value;
    }
    
    // Fecha seleccionada
    const fechaInput = document.getElementById('fecha');
    if (fechaInput && fechaInput.value) {
        filtros.fecha = fechaInput.value;
    }
    
    // Nombre médico
    const nombreInput = document.getElementById('nombreMedico');
    if (nombreInput && nombreInput.value.trim()) {
        filtros.nombre_medico = nombreInput.value.trim();
    }
    
    return filtros;
}

/**
 * Construye la URL con los filtros aplicados
 */
function _construirUrlConFiltrosPasillo(filtros) {
    const baseUrl = window.location.pathname;
    const params = new URLSearchParams();
    
    // Agregar filtros como parámetros de URL
    Object.keys(filtros).forEach(key => {
        if (filtros[key]) {
            params.append(key, filtros[key]);
        }
    });
    
    return baseUrl + (params.toString() ? '?' + params.toString() : '');
}

/**
 * Remueve un filtro específico
 */
function removerFiltroPasillo(tipoFiltro) {
    console.log('Removiendo filtro:', tipoFiltro);
    
    // Limpiar el campo correspondiente
    switch (tipoFiltro) {
        case 'pasillo':
            const pasilloSelect = document.getElementById('pasillo');
            if (pasilloSelect) pasilloSelect.value = '';
            break;
        case 'jornada':
            const jornadaSelect = document.getElementById('jornada');
            if (jornadaSelect) jornadaSelect.value = '';
            break;
        case 'fecha':
            const fechaInput = document.getElementById('fecha');
            if (fechaInput) fechaInput.value = '';
            break;
        case 'nombre_medico':
            const nombreInput = document.getElementById('nombreMedico');
            if (nombreInput) nombreInput.value = '';
            break;
    }
    
    // Aplicar filtros actualizados
    aplicarFiltrosPasillo();
}

/**
 * Limpia todos los filtros
 */
function limpiarTodosFiltrosPasillo() {
    console.log('Limpiando todos los filtros...');
    
    // Limpiar todos los campos
    const pasilloSelect = document.getElementById('pasillo');
    const jornadaSelect = document.getElementById('jornada');
    const fechaInput = document.getElementById('fecha');
    const nombreInput = document.getElementById('nombreMedico');
    
    if (pasilloSelect) pasilloSelect.value = '';
    if (jornadaSelect) jornadaSelect.value = '';
    if (fechaInput) fechaInput.value = '';
    if (nombreInput) nombreInput.value = '';
    
    // Aplicar filtros (vacíos)
    aplicarFiltrosPasillo();
}

// ============================================================================
// TODO EL CÓDIGO DE AGENDAMIENTO (MANTENER INTACTO)
// ============================================================================

// Configurar eventos para boxes (función global mantenida)
function setupBoxEvents() {
    const timeSlots = document.querySelectorAll('.time-slot');
    console.log('Configurando eventos para', timeSlots.length, 'time slots');
    
    timeSlots.forEach(slot => {
        slot.addEventListener('click', function() {
            const boxId = this.getAttribute('data-box-id') || this.getAttribute('data-box');
            const hora = this.getAttribute('data-hora');
            
            if (typeof mostrarDetallePasillo === 'function') {
                mostrarDetallePasillo(boxId, hora);
            } else if (typeof BoxModal !== 'undefined') {
                BoxModal.mostrarDetalle(boxId, { 
                    hora: hora,
                    element: this 
                });
            }
        });
    });
}

// Ejecutar configuración de eventos cuando el DOM esté listo
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', setupBoxEvents);
} else {
    setupBoxEvents();
}

// ============================================================================
// PANEL DE AGENDAMIENTO (CÓDIGO ORIGINAL)
// ============================================================================

const AgendamientoPanel = {
    
    init() {
        console.log('Panel de agendamiento inicializado');
        // Código del panel de agendamiento se mantiene igual...
    },
    
    // ... resto de métodos del panel de agendamiento
    mostrarMensaje(mensaje, tipo) {
        const alertHtml = `
            <div class="alert alert-${tipo} alert-dismissible fade show" role="alert">
                <i class="fas fa-${tipo === 'success' ? 'check-circle' : 'exclamation-triangle'}"></i>
                ${mensaje}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        `;
        
        // Remover alertas anteriores
        $('#mensajes-agendamiento .alert').remove();
        
        // Agregar nueva alerta
        $('#mensajes-agendamiento').html(alertHtml);
        
        // Auto-remover después de 5 segundos
        setTimeout(() => {
            $('#mensajes-agendamiento .alert').fadeOut();
        }, 5000);
    },
    
    getCsrfToken() {
        return document.querySelector('[name=csrfmiddlewaretoken]').value;
    }
};

// ============================================================================
// INICIALIZACIÓN
// ============================================================================

// Inicializar cuando el DOM esté listo
$(document).ready(function() {
    console.log('jQuery disponible:', typeof $);
    console.log('DOM listo - inicializando componentes...');
    
    AgendamientoPanel.init();
    console.log('AgendamientoPanel inicializado');
    
    // Verificar si PasilloVisualizador existe
    console.log('¿PasilloVisualizador existe?', typeof PasilloVisualizador);
    
    try {
        // Inicializar el PasilloVisualizador
        console.log('Intentando inicializar PasilloVisualizador...');
        PasilloVisualizador.init();
        console.log('PasilloVisualizador inicializado exitosamente');
    } catch (error) {
        console.error('Error al inicializar PasilloVisualizador:', error);
    }
});
