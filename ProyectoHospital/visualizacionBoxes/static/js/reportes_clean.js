// ============================================================================
// MÓDULO DE REPORTES - SISTEMA HOSPITALARIO
// ============================================================================

/**
 * Configuración global del módulo de reportes
 */
const CONFIG_REPORTES = {
    DEBUG: false,           // Debug deshabilitado en producción
    DATE_FORMAT: "d/m/Y",   // Formato de fechas para el usuario
    DATE_API_FORMAT: "Y-m-d", // Formato de fechas para la API
    MAX_PREVIEW_RECORDS: 15, // Máximo de registros en vista previa
    LOCALE: "es"
};

// ============================================================================
// INICIALIZACIÓN
// ============================================================================

/**
 * Inicializa el módulo de reportes cuando el DOM esté listo
 */
document.addEventListener('DOMContentLoaded', function () {
    // Inicializar componentes
    inicializarSelectoresFecha();
    inicializarEventos();
    inicializarValoresPorDefecto();
    
    if (CONFIG_REPORTES.DEBUG) {
        console.log('🏥 Módulo de Reportes inicializado');
    }
});

// ============================================================================
// FUNCIONES DE INICIALIZACIÓN
// ============================================================================

/**
 * Inicializa los selectores de fecha con flatpickr
 */
function inicializarSelectoresFecha() {
    // Configurar flatpickr para fechas en español
    flatpickr.localize(flatpickr.l10ns.es);
    
    // Selector de fecha inicio (30 días atrás por defecto)
    flatpickr("#fechainicio", {
        dateFormat: CONFIG_REPORTES.DATE_FORMAT,
        maxDate: "today",
        locale: CONFIG_REPORTES.LOCALE,
        altInput: true,
        altFormat: CONFIG_REPORTES.DATE_FORMAT,
        placeholder: "01/02/2025",
        defaultDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) // 30 días atrás
    });

    // Selector de fecha fin (hoy por defecto)
    flatpickr("#fechafin", {
        dateFormat: CONFIG_REPORTES.DATE_FORMAT, 
        maxDate: "today",
        locale: CONFIG_REPORTES.LOCALE,
        altInput: true,
        altFormat: CONFIG_REPORTES.DATE_FORMAT,
        placeholder: "01/04/2025",
        defaultDate: new Date() // Hoy
    });
}

/**
 * Inicializa todos los eventos del módulo
 */
function inicializarEventos() {
    const btnPreview = document.getElementById('btn-preview');
    const btnDownload = document.getElementById('btn-download');
    
    // Event listeners principales
    btnPreview?.addEventListener('click', generarVistaPrevia);
    btnDownload?.addEventListener('click', descargarReporte);
    
    // Validación de fechas
    document.getElementById('fechafin')?.addEventListener('change', validarFechas);
    document.getElementById('fechainicio')?.addEventListener('change', validarFechas);
}

/**
 * Inicializa valores por defecto en el formulario
 */
function inicializarValoresPorDefecto() {
    const pasilloSelect = document.getElementById('pasillo');
    
    // Establecer fechas por defecto (último mes)
    const hoy = new Date();
    const hace30Dias = new Date();
    hace30Dias.setDate(hoy.getDate() - 30);

    if (document.getElementById('fechainicio').value === '') {
        document.getElementById('fechainicio').value = formatearFecha(hace30Dias);
    }
    if (document.getElementById('fechafin').value === '') {
        document.getElementById('fechafin').value = formatearFecha(hoy);
    }

    // Establecer valores por defecto para selectores
    if (pasilloSelect && pasilloSelect.value === '') {
        pasilloSelect.value = 'General';
    }
}

// ============================================================================
// FUNCIONES PRINCIPALES DE REPORTES
// ============================================================================

/**
 * Genera vista previa de los datos del reporte
 */
function generarVistaPrevia() {
    if (!validarFormulario()) {
        return;
    }

    // Obtener elementos del DOM
    const btnPreview = document.getElementById('btn-preview');
    const previewContainer = document.getElementById('preview-container');
    const form = document.querySelector('form');

    // Mostrar estado de carga
    mostrarCargando(btnPreview, 'Generando...');
    previewContainer.innerHTML = '<div class="text-center"><div class="spinner-border text-primary" role="status"></div><p class="mt-2">Cargando datos...</p></div>';

    const formData = new FormData(form);
    formData.append('action', 'preview');
    
    // Convertir fechas al formato esperado por el backend
    const fechaInicio = document.getElementById('fechainicio').value;
    const fechaFin = document.getElementById('fechafin').value;
    
    if (fechaInicio) {
        formData.set('fechainicio', convertirFechaParaBackend(fechaInicio));
    }
    if (fechaFin) {
        formData.set('fechafin', convertirFechaParaBackend(fechaFin));
    }
    
    fetch(window.reportesUrls.reportes, {
        method: 'POST',
        body: formData,
        headers: {
            'X-CSRFToken': document.querySelector('[name=csrfmiddlewaretoken]').value
        }
    })
    .then(response => response.json())
    .then(data => {
        const btnDownload = document.getElementById('btn-download');
        
        if (data.success) {
            previewContainer.innerHTML = data.html;
            previewContainer.parentElement.classList.add('slide-up');
            btnDownload.disabled = false;
            mostrarNotificacion('Vista previa generada correctamente', 'success');
        } else {
            previewContainer.innerHTML = `<div class="alert alert-warning-custom">${data.message}</div>`;
            btnDownload.disabled = true;
            mostrarNotificacion(data.message, 'warning');
        }
    })
    .catch(error => {
        console.error('Error:', error);
        previewContainer.innerHTML = '<div class="alert alert-danger-custom">Error al generar la vista previa</div>';
        mostrarNotificacion('Error al generar la vista previa', 'error');
    })
    .finally(() => {
        restaurarBoton(btnPreview, '<i class="bi bi-eye"></i> Vista Previa');
    });
}

/**
 * Descarga el reporte en el formato seleccionado
 */
function descargarReporte() {
    if (!validarFormulario()) {
        return;
    }

    const btnDownload = document.getElementById('btn-download');
    const form = document.querySelector('form');

    mostrarCargando(btnDownload, 'Descargando...');

    const formData = new FormData(form);
    formData.append('action', 'download');
    
    // Convertir fechas al formato esperado por el backend
    const fechaInicio = document.getElementById('fechainicio').value;
    const fechaFin = document.getElementById('fechafin').value;
    
    if (fechaInicio) {
        formData.set('fechainicio', convertirFechaParaBackend(fechaInicio));
    }
    if (fechaFin) {
        formData.set('fechafin', convertirFechaParaBackend(fechaFin));
    }

    fetch(window.reportesUrls.reportes, {
        method: 'POST',
        body: formData,
        headers: {
            'X-CSRFToken': document.querySelector('[name=csrfmiddlewaretoken]').value
        }
    })
    .then(response => {
        if (response.ok) {
            return response.blob();
        }
        throw new Error('Error en la descarga');
    })
    .then(blob => {
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        
        // Generar nombre de archivo con fecha y formato
        const formato = document.getElementById('formato').value;
        const tipoReporte = document.getElementById('tipo_reporte').value;
        const fechaDesc = formatearFechaParaArchivo(new Date());
        const filename = `reporte_${tipoReporte}_${fechaDesc}.${formato}`;
        
        a.style.display = 'none';
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
        
        mostrarNotificacion('Reporte descargado correctamente', 'success');
    })
    .catch(error => {
        console.error('Error:', error);
        mostrarNotificacion('Error al descargar el reporte', 'error');
    })
    .finally(() => {
        restaurarBoton(btnDownload, '<i class="bi bi-download"></i> Descargar');
    });
}

// ============================================================================
// FUNCIONES DE VALIDACIÓN
// ============================================================================

/**
 * Valida el formulario antes de generar reporte
 * @returns {boolean} True si es válido, false en caso contrario
 */
function validarFormulario() {
    const fechaInicio = document.getElementById('fechainicio').value;
    const fechaFin = document.getElementById('fechafin').value;
    
    if (!fechaInicio || !fechaFin) {
        mostrarNotificacion('Por favor, seleccione las fechas de inicio y fin', 'warning');
        return false;
    }
    
    return validarFechas();
}

/**
 * Valida que las fechas sean correctas
 * @returns {boolean} True si son válidas, false en caso contrario
 */
function validarFechas() {
    const fechaInicio = document.getElementById('fechainicio').value;
    const fechaFin = document.getElementById('fechafin').value;
    
    if (!fechaInicio || !fechaFin) {
        return true; // Validación se hace en validarFormulario
    }
    
    const inicio = parsearFecha(fechaInicio);
    const fin = parsearFecha(fechaFin);
    
    if (inicio > fin) {
        mostrarNotificacion('La fecha de inicio debe ser anterior a la fecha de fin', 'warning');
        return false;
    }
    
    // Validar que no sea un rango muy amplio (más de 1 año)
    const diffTime = Math.abs(fin - inicio);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    if (diffDays > 365) {
        mostrarNotificacion('El rango de fechas no puede ser superior a un año', 'warning');
        return false;
    }
    
    return true;
}

// ============================================================================
// FUNCIONES AUXILIARES PRIVADAS
// ============================================================================

/**
 * Convierte fecha del formato usuario al formato backend
 * @param {string} fecha - Fecha en formato DD/MM/YYYY
 * @returns {string} Fecha en formato YYYY-MM-DD
 * @private
 */
function convertirFechaParaBackend(fecha) {
    if (!fecha) return '';
    
    const partes = fecha.split('/');
    if (partes.length !== 3) return fecha; // Si no tiene formato DD/MM/YYYY, devolver tal como está
    
    const [dia, mes, año] = partes;
    return `${año}-${mes.padStart(2, '0')}-${dia.padStart(2, '0')}`;
}

/**
 * Formatea una fecha para mostrar al usuario
 * @param {Date} fecha - Objeto Date
 * @returns {string} Fecha formateada DD/MM/YYYY
 * @private
 */
function formatearFecha(fecha) {
    const dia = fecha.getDate().toString().padStart(2, '0');
    const mes = (fecha.getMonth() + 1).toString().padStart(2, '0');
    const año = fecha.getFullYear();
    return `${dia}/${mes}/${año}`;
}

/**
 * Formatea una fecha para nombre de archivo
 * @param {Date} fecha - Objeto Date
 * @returns {string} Fecha formateada YYYYMMDD
 * @private
 */
function formatearFechaParaArchivo(fecha) {
    const año = fecha.getFullYear();
    const mes = (fecha.getMonth() + 1).toString().padStart(2, '0');
    const dia = fecha.getDate().toString().padStart(2, '0');
    return `${año}${mes}${dia}`;
}

/**
 * Parsea una fecha en formato DD/MM/YYYY a objeto Date
 * @param {string} fechaStr - Fecha como string
 * @returns {Date} Objeto Date
 * @private
 */
function parsearFecha(fechaStr) {
    const partes = fechaStr.split('/');
    if (partes.length !== 3) return new Date(fechaStr);
    
    const [dia, mes, año] = partes;
    return new Date(parseInt(año), parseInt(mes) - 1, parseInt(dia));
}

/**
 * Muestra el estado de carga en un botón
 * @param {HTMLElement} boton - Elemento botón
 * @param {string} texto - Texto a mostrar
 * @private
 */
function mostrarCargando(boton, texto) {
    if (boton) {
        boton.disabled = true;
        boton.innerHTML = `<span class="spinner-border spinner-border-sm me-2" role="status"></span>${texto}`;
    }
}

/**
 * Restaura el estado normal de un botón
 * @param {HTMLElement} boton - Elemento botón
 * @param {string} textoOriginal - Texto original del botón
 * @private
 */
function restaurarBoton(boton, textoOriginal) {
    if (boton) {
        boton.disabled = false;
        boton.innerHTML = textoOriginal;
    }
}

/**
 * Muestra una notificación al usuario
 * @param {string} mensaje - Mensaje a mostrar
 * @param {string} tipo - Tipo de notificación: success, warning, error
 * @private
 */
function mostrarNotificacion(mensaje, tipo = 'info') {
    // Crear elemento de notificación
    const notificacion = document.createElement('div');
    notificacion.className = `alert alert-${tipo === 'error' ? 'danger' : tipo} alert-dismissible fade show position-fixed`;
    notificacion.style.cssText = 'top: 20px; right: 20px; z-index: 9999; max-width: 400px;';
    
    notificacion.innerHTML = `
        ${mensaje}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    document.body.appendChild(notificacion);
    
    // Auto-eliminar después de 5 segundos
    setTimeout(() => {
        if (notificacion.parentNode) {
            notificacion.parentNode.removeChild(notificacion);
        }
    }, 5000);
}
