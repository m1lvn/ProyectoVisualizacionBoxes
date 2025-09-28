/**
 * ============================================================================
 * SISTEMA UNIFICADO DE MODAL PARA DETALLES DE BOX
 * ============================================================================
 * 
 * Funciones compartidas entre visualización general y visualización pasillo
 * para mostrar detalles de boxes de manera consistente.
 * 
 * @author Sistema Hospital
 * @version 1.0.0
 */

'use strict';

// ============================================================================
// CONFIGURACIÓN GLOBAL
// ============================================================================
const BoxModal = {
    config: {
        DEBUG: false,
        modalId: 'detalleModal',
        modalContentId: 'modalContent'
    },

    // ============================================================================
    // FUNCIÓN PRINCIPAL UNIFICADA
    // ============================================================================

    /**
     * Muestra el modal con detalles de un box
     * @param {string} boxId - ID del box a consultar
     * @param {Object} options - Opciones de configuración
     * @param {boolean} options.disponible - Estado actual del box (opcional)
     * @param {string} options.fecha - Fecha específica (opcional, por defecto: fecha actual)
     * @param {string} options.hora - Hora específica (opcional, por defecto: hora actual)
     * @param {HTMLElement} options.element - Elemento que disparó el evento (opcional)
     */
    async mostrarDetalle(boxId, options = {}) {
        try {
            // Extraer hora del elemento si no se proporciona y está disponible
            if (!options.hora && options.element) {
                const timeSlot = options.element.closest('.time-slot');
                if (timeSlot && timeSlot.dataset.hora) {
                    options.hora = timeSlot.dataset.hora;
                }
            }

            // Valores por defecto
            const fecha = options.fecha || this._obtenerFecha();
            const hora = options.hora; // Puede ser null para hora actual

            // Construir URL
            const url = this._construirUrl(boxId, fecha, hora);
            
            if (this.config.DEBUG) {
                console.log('🔍 Mostrando detalle:', { boxId, fecha, hora, url });
            }

            // Mostrar modal con loader
            this._mostrarLoader();

            // Realizar petición
            const data = await this._realizarPeticion(url);

            // Generar y mostrar contenido
            const contenido = this._generarContenido(data, fecha, hora);
            this._mostrarContenido(contenido);

        } catch (error) {
            console.error('❌ Error al mostrar detalle:', error);
            this._mostrarError(error.message);
        }
    },

    // ============================================================================
    // FUNCIONES AUXILIARES PRIVADAS
    // ============================================================================

    /**
     * Obtiene la fecha actual desde meta tag o fecha actual
     * @returns {string} Fecha en formato YYYY-MM-DD
     * @private
     */
    _obtenerFecha() {
        return document.querySelector('meta[name="fecha"]')?.content || 
               new Date().toISOString().split('T')[0];
    },

    /**
     * Construye la URL para la petición
     * @param {string} boxId - ID del box
     * @param {string} fecha - Fecha
     * @param {string|null} hora - Hora específica (opcional)
     * @returns {string} URL completa
     * @private
     */
    _construirUrl(boxId, fecha, hora) {
        const baseUrl = window.detalleBoxUrl || '/detalle-box/';
        let url = `${baseUrl}?box_id=${boxId}&fecha=${fecha}`;
        
        if (hora) {
            url += `&hora=${hora}`;
        }
        
        return url;
    },

    /**
     * Realiza la petición AJAX al servidor
     * @param {string} url - URL de la petición
     * @returns {Promise<Object>} Datos de respuesta
     * @private
     */
    async _realizarPeticion(url) {
        const response = await fetch(url, {
            method: 'GET',
            headers: {
                'X-Requested-With': 'XMLHttpRequest',
                'Accept': 'application/json'
            }
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const data = await response.json();
        
        if (data.error) {
            throw new Error(data.error);
        }

        return data;
    },

    /**
     * Genera el contenido HTML del modal
     * @param {Object} data - Datos del box y agenda
     * @param {string} fecha - Fecha consultada
     * @param {string|null} hora - Hora específica consultada (opcional)
     * @returns {string} HTML del contenido
     * @private
     */
    _generarContenido(data, fecha, hora) {
        const tiempoMostrar = hora 
            ? `<p><strong>Hora consultada:</strong> ${hora}</p>`
            : `<p><strong>Estado actual:</strong> ${new Date().toLocaleTimeString()}</p>`;

        let contenido = `
            <div class="row">
                <div class="col-12">
                    <h6><strong>Box ${data.box.id}</strong></h6>
                    <p><strong>Pasillo:</strong> ${data.box.pasillo}</p>
                    <p><strong>Capacidad:</strong> ${data.box.capacidad || 'No especificada'}</p>
                    <p><strong>Fecha:</strong> ${fecha}</p>
                    ${tiempoMostrar}
                    <hr>
        `;
        
        if (data.disponible) {
            const estadoTexto = hora ? 'estaba libre en la hora consultada' : 'está libre en este momento';
            contenido += `
                <div class="alert alert-success">
                    <h6><i class="bi bi-check-circle"></i> Box Disponible</h6>
                    <p>Este box ${estadoTexto}.</p>
                </div>
            `;
        } else {
            // DEBUG: Ver qué datos estamos recibiendo
            console.log('DEBUG - data.agenda:', data.agenda);
            
            const profesional = data.agenda?.profesional || 'No especificado';
            const especialidad = data.agenda?.especialidad || 'No especificada';
            const tipoAgenda = data.agenda?.tipo_agenda || 'No especificado';
            const horaInicio = data.agenda?.hora_inicio || '';
            const horaFin = data.agenda?.hora_fin || '';
            const observaciones = data.agenda?.observaciones || 'Sin observaciones';
            
            contenido += `
                <div class="alert alert-warning">
                    <h6><i class="bi bi-clock"></i> Box Ocupado</h6>
                    <p><strong>Profesional:</strong> ${profesional}</p>
                    <p><strong>Especialidad:</strong> ${especialidad}</p>
                    <p><strong>Tipo de Agenda:</strong> ${tipoAgenda}</p>
                    <p><strong>Horario:</strong> ${horaInicio} - ${horaFin}</p>
                    <p><strong>Observaciones:</strong> ${observaciones}</p>
                </div>
            `;
        }
        
        contenido += `</div></div>`;
        return contenido;
    },

    /**
     * Muestra el loader en el modal
     * @private
     */
    _mostrarLoader() {
        const modal = this._obtenerModal();
        const modalContent = this._obtenerContenido();
        
        if (!modal || !modalContent) {
            console.error('Modal no encontrado');
            return;
        }

        // Mostrar loader
        modalContent.innerHTML = `
            <div class="text-center py-4">
                <div class="spinner-border text-primary" role="status">
                    <span class="visually-hidden">Cargando...</span>
                </div>
                <p class="mt-2 text-muted">Cargando detalles del box...</p>
            </div>
        `;

        // Mostrar modal
        this._mostrarModal(modal);
    },

    /**
     * Muestra el contenido final en el modal
     * @param {string} contenido - HTML del contenido
     * @private
     */
    _mostrarContenido(contenido) {
        const modalContent = this._obtenerContenido();
        if (modalContent) {
            modalContent.innerHTML = contenido;
        }
    },

    /**
     * Muestra un error en el modal
     * @param {string} mensaje - Mensaje de error
     * @private
     */
    _mostrarError(mensaje) {
        const modalContent = this._obtenerContenido();
        if (modalContent) {
            modalContent.innerHTML = `
                <div class="alert alert-danger">
                    <h6><i class="bi bi-exclamation-triangle"></i> Error</h6>
                    <p>No se pudieron cargar los detalles del box.</p>
                    <small>${mensaje}</small>
                </div>
            `;
        }
    },

    /**
     * Obtiene el elemento modal
     * @returns {HTMLElement|null} Elemento modal
     * @private
     */
    _obtenerModal() {
        return document.getElementById(this.config.modalId);
    },

    /**
     * Obtiene el contenido del modal
     * @returns {HTMLElement|null} Elemento del contenido
     * @private
     */
    _obtenerContenido() {
        return document.getElementById(this.config.modalContentId);
    },

    /**
     * Muestra el modal usando Bootstrap
     * @param {HTMLElement} modal - Elemento modal
     * @private
     */
    _mostrarModal(modal) {
        try {
            if (typeof bootstrap !== 'undefined' && bootstrap.Modal) {
                const modalInstance = bootstrap.Modal.getOrCreateInstance(modal);
                modalInstance.show();
            } else {
                // Fallback manual
                modal.style.display = 'block';
                modal.classList.add('show');
                document.body.classList.add('modal-open');
            }
        } catch (error) {
            console.error('Error al mostrar modal:', error);
        }
    }
};

// ============================================================================
// FUNCIONES GLOBALES DE COMPATIBILIDAD
// ============================================================================

/**
 * Función global para compatibilidad con templates existentes
 * @param {string} boxId - ID del box
 * @param {boolean} disponible - Estado del box (no usado pero mantenido por compatibilidad)
 * @param {Object} options - Opciones adicionales
 */
function mostrarDetalle(boxId, disponible = null, options = {}) {
    // Si se llama desde un evento, capturar el elemento
    if (typeof event !== 'undefined' && event.target) {
        options.element = event.target;
    }
    
    BoxModal.mostrarDetalle(boxId, options);
}

/**
 * Función específica para visualización pasillo con hora
 * @param {string} boxId - ID del box
 * @param {string} hora - Hora específica
 * @param {string} fecha - Fecha específica (opcional)
 */
function mostrarDetallePasillo(boxId, hora, fecha = null) {
    BoxModal.mostrarDetalle(boxId, { hora, fecha });
}

/**
 * Cerrar modal manualmente
 */
function cerrarModal() {
    const modal = document.getElementById('detalleModal');
    if (!modal) return;
    
    try {
        if (typeof bootstrap !== 'undefined' && bootstrap.Modal) {
            const modalInstance = bootstrap.Modal.getInstance(modal);
            if (modalInstance) {
                modalInstance.hide();
            }
        } else {
            modal.style.display = 'none';
            modal.classList.remove('show');
            document.body.classList.remove('modal-open');
        }
    } catch (error) {
        console.error('Error al cerrar modal:', error);
    }
}

// Exponer globalmente
window.BoxModal = BoxModal;
window.mostrarDetalle = mostrarDetalle;
window.mostrarDetallePasillo = mostrarDetallePasillo;
window.cerrarModal = cerrarModal;
