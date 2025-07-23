/**
 * Módulo de Reportes - JavaScript
 * Maneja la funcionalidad de generación de reportes de boxes hospitalarios
 */

document.addEventListener('DOMContentLoaded', function () {
    // Configurar flatpickr para fechas en español
    flatpickr.localize(flatpickr.l10ns.es);
    
    // Configurar selectores de fecha con formato DD/MM/YYYY
    flatpickr("#fechainicio", {
        dateFormat: "d/m/Y",
        maxDate: "today",
        locale: "es",
        altInput: true,
        altFormat: "d/m/Y",
        placeholder: "01/02/2025",
        defaultDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) // 30 días atrás
    });

    flatpickr("#fechafin", {
        dateFormat: "d/m/Y", 
        maxDate: "today",
        locale: "es",
        altInput: true,
        altFormat: "d/m/Y",
        placeholder: "01/04/2025",
        defaultDate: new Date() // Hoy
    });

    // Elementos del DOM
    const btnPreview = document.getElementById('btn-preview');
    const btnDownload = document.getElementById('btn-download');
    const previewContainer = document.getElementById('preview-container');
    const form = document.querySelector('form');
    const pasilloSelect = document.getElementById('pasillo');
    const formatoSelect = document.getElementById('formato');

    // Inicializar valores por defecto
    inicializarValoresPorDefecto();

    // Event Listeners
    btnPreview?.addEventListener('click', generarVistaPrevia);
    btnDownload?.addEventListener('click', descargarReporte);
    document.getElementById('fechafin')?.addEventListener('change', validarFechas);
    document.getElementById('fechainicio')?.addEventListener('change', validarFechas);

    /**
     * Inicializa valores por defecto en el formulario
     */
    function inicializarValoresPorDefecto() {
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

    /**
     * Genera vista previa de los datos del reporte
     */
    function generarVistaPrevia() {
        if (!validarFormulario()) {
            return;
        }

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
            previewContainer.innerHTML = '<div class="alert alert-danger-custom">Error al cargar la vista previa</div>';
            btnDownload.disabled = true;
            mostrarNotificacion('Error al cargar la vista previa', 'error');
        })
        .finally(() => {
            ocultarCargando(btnPreview, '<i class="bi bi-eye"></i> Generar Vista Previa');
        });
    }

    /**
     * Descarga el reporte en el formato seleccionado
     */
    function descargarReporte() {
        if (!validarFormulario()) {
            return;
        }

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
        
        // Crear formulario para descarga
        const downloadForm = document.createElement('form');
        downloadForm.method = 'POST';
        downloadForm.action = window.reportesUrls.reportes;
        
        for (let [key, value] of formData.entries()) {
            const input = document.createElement('input');
            input.type = 'hidden';
            input.name = key;
            input.value = value;
            downloadForm.appendChild(input);
        }
        
        document.body.appendChild(downloadForm);
        downloadForm.submit();
        document.body.removeChild(downloadForm);

        // Simular tiempo de descarga
        setTimeout(() => {
            ocultarCargando(btnDownload, '<i class="bi bi-download"></i> Descargar Reporte');
            mostrarNotificacion('Descarga iniciada', 'success');
        }, 1500);
    }

    /**
     * Valida las fechas del formulario
     */
    function validarFechas() {
        const fechaInicio = document.getElementById('fechainicio').value;
        const fechaFin = document.getElementById('fechafin').value;
        
        if (fechaInicio && fechaFin) {
            const inicio = new Date(convertirFechaParaBackend(fechaInicio));
            const fin = new Date(convertirFechaParaBackend(fechaFin));
            
            if (fin < inicio) {
                mostrarNotificacion('La fecha de fin no puede ser anterior a la fecha de inicio', 'error');
                document.getElementById('fechafin').value = '';
                return false;
            }

            // Validar que no sea un rango muy largo (más de 1 año)
            const diffTime = Math.abs(fin - inicio);
            const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
            
            if (diffDays > 365) {
                mostrarNotificacion('El rango de fechas no puede ser mayor a 1 año', 'warning');
                return false;
            }
        }
        return true;
    }

    /**
     * Valida que todos los campos requeridos estén completos
     */
    function validarFormulario() {
        const fechaInicio = document.getElementById('fechainicio').value;
        const fechaFin = document.getElementById('fechafin').value;
        
        if (!fechaInicio || !fechaFin) {
            mostrarNotificacion('Por favor selecciona las fechas de inicio y fin', 'error');
            return false;
        }

        return validarFechas();
    }

    /**
     * Muestra estado de carga en un botón
     */
    function mostrarCargando(boton, texto) {
        boton.disabled = true;
        boton.innerHTML = `<span class="spinner-border spinner-border-sm me-2" role="status"></span>${texto}`;
        boton.classList.add('loading');
    }

    /**
     * Oculta estado de carga en un botón
     */
    function ocultarCargando(boton, textoOriginal) {
        boton.disabled = false;
        boton.innerHTML = textoOriginal;
        boton.classList.remove('loading');
    }

    /**
     * Muestra notificaciones al usuario
     */
    function mostrarNotificacion(mensaje, tipo) {
        // Crear elemento de notificación
        const notificacion = document.createElement('div');
        notificacion.className = `alert alert-${tipo === 'error' ? 'danger' : tipo}-custom notification fade-in`;
        notificacion.innerHTML = `
            <i class="bi bi-${tipo === 'success' ? 'check-circle' : tipo === 'error' ? 'x-circle' : 'exclamation-triangle'}"></i>
            ${mensaje}
            <button type="button" class="btn-close" onclick="this.parentElement.remove()"></button>
        `;

        // Agregar al container de notificaciones o crear uno
        let container = document.getElementById('notifications-container');
        if (!container) {
            container = document.createElement('div');
            container.id = 'notifications-container';
            container.className = 'position-fixed top-0 end-0 p-3';
            container.style.zIndex = '9999';
            document.body.appendChild(container);
        }

        container.appendChild(notificacion);

        // Auto-remover después de 5 segundos
        setTimeout(() => {
            if (notificacion.parentElement) {
                notificacion.remove();
            }
        }, 5000);
    }

    /**
     * Formatea fecha para mostrar en DD/MM/YYYY
     */
    function formatearFecha(fecha) {
        const dia = fecha.getDate().toString().padStart(2, '0');
        const mes = (fecha.getMonth() + 1).toString().padStart(2, '0');
        const año = fecha.getFullYear();
        return `${dia}/${mes}/${año}`;
    }

    /**
     * Convierte fecha de DD/MM/YYYY a YYYY-MM-DD para el backend
     */
    function convertirFechaParaBackend(fechaString) {
        if (fechaString.includes('/')) {
            const [dia, mes, año] = fechaString.split('/');
            return `${año}-${mes.padStart(2, '0')}-${dia.padStart(2, '0')}`;
        }
        return fechaString;
    }

    /**
     * Actualiza la vista previa cuando cambian los filtros
     */
    function actualizarVistaPreviewAutomatica() {
        // Solo si ya se ha generado una vista previa antes
        if (previewContainer.innerHTML.includes('table-preview')) {
            setTimeout(generarVistaPrevia, 500);
        }
    }

    // Event listeners para actualización automática
    pasilloSelect?.addEventListener('change', actualizarVistaPreviewAutomatica);
    document.getElementById('tipo_reporte')?.addEventListener('change', actualizarVistaPreviewAutomatica);
});

// Configuración global para URLs
window.reportesUrls = window.reportesUrls || {};
