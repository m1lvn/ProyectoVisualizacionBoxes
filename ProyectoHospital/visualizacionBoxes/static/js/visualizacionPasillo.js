/**
 * ============================================================================
 * VISUALIZACIÓN PASILLO - JAVASCRIPT LIMPIO Y ORGANIZADO
 * ============================================================================
 * 
 * Sistema de visualización de boxes por pasillo para hospital.
 * Incluye gestión de eventos, modales, filtros y actualización automática.
 * 
 * @author Sistema Hospital
 * @version 2.0.0
 * @since 2024
 */

'use strict';

// ============================================================================
// NAMESPACE PRINCIPAL
// ============================================================================
const PasilloVisualizador = {
    
    // ========================================================================
    // CONFIGURACIÓN Y CONSTANTES
    // ========================================================================
    config: {
        DEBUG: false,
        UPDATE_INTERVAL: 30000, // 30 segundos
        LOCALE: "es-ES",
        SELECTOR_MODAL: '#detalleModal',
        SELECTOR_TIME_SLOT: '.time-slot',
        SELECTOR_MODAL_CONTENT: '#modalContent',
        CSS_CLASSES: {
            loading: 'loading',
            error: 'error',
            success: 'success',
            disabled: 'disabled'
        }
    },

    // URLs de la aplicación
    urls: {
        detalleBox: null,
        buscarMedicos: null
    },

    // Estado interno de la aplicación
    state: {
        initialized: false,
        intervalId: null,
        currentDate: null,
        currentTime: null,
        modalInstance: null,
        lastClickedBox: null
    },

    // Elementos DOM cacheados
    dom: {
        modal: null,
        modalContent: null,
        timeSlots: null,
        counters: {
            libres: null,
            ocupados: null
        }
    },

    // ========================================================================
    // INICIALIZACIÓN
    // ========================================================================

    /**
     * Inicializa toda la funcionalidad del visualizador
     */
    init() {
        if (this.state.initialized) {
            this.log('Ya inicializado, saltando...');
            return;
        }

        // Esperar a que el DOM esté listo
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this._initializeApp());
        } else {
            this._initializeApp();
        }
    },

    /**
     * Inicialización interna de la aplicación
     * @private
     */
    _initializeApp() {
        try {
            this._loadConfiguration();
            this._cacheElements();
            this._setupEventListeners();
            this._initializeVisualization();
            this._startAutoUpdate();
            
            this.state.initialized = true;
            this.log('✅ Visualizador de pasillos inicializado correctamente');
            
        } catch (error) {
            this.error('❌ Error al inicializar:', error);
        }
    },

    /**
     * Carga la configuración desde variables globales
     * @private
     */
    _loadConfiguration() {
        // URLs desde Django
        this.urls.detalleBox = window.detalleBoxUrl || null;
        this.urls.buscarMedicos = window.medicosUrls?.buscar_medicos || null;

        // Configuración del pasillo
        if (window.pasilloConfig) {
            Object.assign(this.config, {
                DEBUG: window.pasilloConfig.DEBUG || false,
                UPDATE_INTERVAL: window.pasilloConfig.ACTUALIZAR_CADA || 30000
            });

            // Estado inicial
            Object.assign(this.state, {
                currentDate: window.pasilloConfig.FECHA_ACTUAL,
                currentTime: window.pasilloConfig.HORA_ACTUAL
            });
        }

        this.log('Configuración cargada:', this.config);
    },

    /**
     * Cachea elementos DOM para mejor rendimiento
     * @private
     */
    _cacheElements() {
        this.dom.modal = document.querySelector(this.config.SELECTOR_MODAL);
        this.dom.modalContent = document.querySelector(this.config.SELECTOR_MODAL_CONTENT);
        this.dom.timeSlots = document.querySelectorAll(this.config.SELECTOR_TIME_SLOT);
        
        // Contadores de estado
        this.dom.counters.libres = document.querySelector('#boxes-libres span');
        this.dom.counters.ocupados = document.querySelector('#boxes-ocupados span');

        this.log('Elementos DOM cacheados:', {
            modal: !!this.dom.modal,
            timeSlots: this.dom.timeSlots.length,
            counters: !!this.dom.counters.libres
        });
    },

    /**
     * Configura todos los event listeners
     * @private
     */
    _setupEventListeners() {
        // Clicks en boxes
        this._setupBoxClickEvents();
        
        // Eventos del modal
        this._setupModalEvents();
        
        // Eventos de teclado
        this._setupKeyboardEvents();
        
        // Eventos de ventana
        this._setupWindowEvents();

        this.log('Event listeners configurados');
    },

    // ========================================================================
    // EVENTOS
    // ========================================================================

    /**
     * Configura eventos de click en boxes
     * @private
     */
    _setupBoxClickEvents() {
        this.dom.timeSlots.forEach(timeSlot => {
            timeSlot.addEventListener('click', (event) => {
                this._handleBoxClick(event.currentTarget);
            });

            // Hover effects
            timeSlot.addEventListener('mouseenter', (event) => {
                this._handleBoxHover(event.currentTarget, true);
            });

            timeSlot.addEventListener('mouseleave', (event) => {
                this._handleBoxHover(event.currentTarget, false);
            });
        });
    },

    /**
     * Configura eventos del modal
     * @private
     */
    _setupModalEvents() {
        if (!this.dom.modal) return;

        // Inicializar modal de Bootstrap
        this.state.modalInstance = new bootstrap.Modal(this.dom.modal);

        // Eventos del modal
        this.dom.modal.addEventListener('show.bs.modal', () => {
            this.log('Modal abriéndose...');
        });

        this.dom.modal.addEventListener('hidden.bs.modal', () => {
            this._resetModal();
        });
    },

    /**
     * Configura eventos de teclado
     * @private
     */
    _setupKeyboardEvents() {
        document.addEventListener('keydown', (event) => {
            // Cerrar modal con ESC
            if (event.key === 'Escape' && this.state.modalInstance) {
                this.state.modalInstance.hide();
            }
        });
    },

    /**
     * Configura eventos de ventana
     * @private
     */
    _setupWindowEvents() {
        // Limpiar intervalos al cerrar
        window.addEventListener('beforeunload', () => {
            this._cleanup();
        });

        // Actualizar cuando se regresa a la pestaña
        document.addEventListener('visibilitychange', () => {
            if (!document.hidden) {
                this._updateCounters();
            }
        });
    },

    // ========================================================================
    // MANEJO DE BOXES
    // ========================================================================

    /**
     * Maneja el click en un box
     * @param {HTMLElement} boxElement - Elemento del box clickeado
     * @private
     */
    _handleBoxClick(boxElement) {
        try {
            // Extraer datos del box
            const boxData = this._extractBoxData(boxElement);
            
            if (!boxData) {
                this.error('No se pudieron extraer los datos del box');
                return;
            }

            this.state.lastClickedBox = boxData;
            this.log('Box clickeado:', boxData);

            // Mostrar modal con detalles
            this._showBoxDetails(boxData);

        } catch (error) {
            this.error('Error al manejar click del box:', error);
        }
    },

    /**
     * Maneja el hover de un box
     * @param {HTMLElement} boxElement - Elemento del box
     * @param {boolean} isEntering - Si está entrando o saliendo
     * @private
     */
    _handleBoxHover(boxElement, isEntering) {
        if (isEntering) {
            // Agregar efectos visuales adicionales si es necesario
            boxElement.style.zIndex = '10';
        } else {
            boxElement.style.zIndex = '';
        }
    },

    /**
     * Extrae los datos de un box desde sus atributos data-*
     * @param {HTMLElement} boxElement - Elemento del box
     * @returns {Object|null} Datos del box
     * @private
     */
    _extractBoxData(boxElement) {
        if (!boxElement || !boxElement.dataset) return null;

        return {
            pasillo: boxElement.dataset.pasillo,
            box: boxElement.dataset.box,
            hora: boxElement.dataset.hora,
            estado: boxElement.dataset.estado,
            fecha: this.state.currentDate
        };
    },

    // ========================================================================
    // MODAL
    // ========================================================================

    /**
     * Muestra los detalles de un box en el modal
     * @param {Object} boxData - Datos del box
     * @private
     */
    async _showBoxDetails(boxData) {
        if (!this.state.modalInstance) {
            this.error('Modal no inicializado');
            return;
        }

        try {
            // Mostrar loading
            this._showModalLoading();
            
            // Mostrar modal
            this.state.modalInstance.show();

            // Cargar contenido
            const content = await this._loadBoxDetails(boxData);
            
            // Mostrar contenido
            this._displayModalContent(content);

        } catch (error) {
            this.error('Error al mostrar detalles del box:', error);
            this._showModalError('Error al cargar los detalles del box');
        }
    },

    /**
     * Carga los detalles del box desde el servidor
     * @param {Object} boxData - Datos del box
     * @returns {Promise<string>} HTML del contenido
     * @private
     */
    async _loadBoxDetails(boxData) {
        if (!this.urls.detalleBox) {
            throw new Error('URL de detalle no configurada');
        }

        const url = new URL(this.urls.detalleBox, window.location.origin);
        Object.keys(boxData).forEach(key => {
            url.searchParams.append(key, boxData[key]);
        });

        const response = await fetch(url, {
            method: 'GET',
            headers: {
                'X-Requested-With': 'XMLHttpRequest',
                'Accept': 'text/html,application/json'
            }
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        return await response.text();
    },

    /**
     * Muestra estado de carga en el modal
     * @private
     */
    _showModalLoading() {
        if (!this.dom.modalContent) return;

        this.dom.modalContent.innerHTML = `
            <div class="text-center py-4">
                <div class="spinner-border text-primary" role="status">
                    <span class="visually-hidden">Cargando...</span>
                </div>
                <p class="mt-2 text-muted">Cargando detalles del box...</p>
            </div>
        `;
    },

    /**
     * Muestra error en el modal
     * @param {string} message - Mensaje de error
     * @private
     */
    _showModalError(message) {
        if (!this.dom.modalContent) return;

        this.dom.modalContent.innerHTML = `
            <div class="alert alert-danger" role="alert">
                <i class="fas fa-exclamation-triangle me-2"></i>
                ${message}
            </div>
        `;
    },

    /**
     * Muestra el contenido en el modal
     * @param {string} content - HTML del contenido
     * @private
     */
    _displayModalContent(content) {
        if (!this.dom.modalContent) return;

        this.dom.modalContent.innerHTML = content;
        
        // Trigger event para scripts adicionales
        this.dom.modalContent.dispatchEvent(new CustomEvent('contentLoaded', {
            detail: { content }
        }));
    },

    /**
     * Resetea el modal a su estado inicial
     * @private
     */
    _resetModal() {
        if (!this.dom.modalContent) return;

        this.dom.modalContent.innerHTML = `
            <div class="text-center">
                <div class="spinner-border text-primary" role="status">
                    <span class="visually-hidden">Cargando...</span>
                </div>
            </div>
        `;

        this.state.lastClickedBox = null;
    },

    // ========================================================================
    // ACTUALIZACIÓN Y CONTADORES
    // ========================================================================

    /**
     * Inicializa la visualización
     * @private
     */
    _initializeVisualization() {
        this._updateCounters();
        this._highlightCurrentTime();
    },

    /**
     * Actualiza los contadores de boxes
     * @private
     */
    _updateCounters() {
        try {
            const states = this._countBoxStates();
            
            // Actualizar UI
            if (this.dom.counters.libres) {
                this.dom.counters.libres.textContent = states.libre || 0;
            }
            
            if (this.dom.counters.ocupados) {
                this.dom.counters.ocupados.textContent = states.ocupado || 0;
            }

            // Actualizar timestamp
            this._updateTimestamp();

            this.log('Contadores actualizados:', states);

        } catch (error) {
            this.error('Error al actualizar contadores:', error);
        }
    },

    /**
     * Cuenta los estados de todos los boxes
     * @returns {Object} Conteo por estado
     * @private
     */
    _countBoxStates() {
        const states = {};

        this.dom.timeSlots.forEach(slot => {
            // Determinar estado basado en clases CSS
            const estado = this._getBoxStateFromClasses(slot);
            states[estado] = (states[estado] || 0) + 1;
        });

        return states;
    },

    /**
     * Determina el estado de un box basado en sus clases CSS
     * @param {HTMLElement} boxElement - Elemento del box
     * @returns {string} Estado del box
     * @private
     */
    _getBoxStateFromClasses(boxElement) {
        const classList = boxElement.classList;
        
        if (classList.contains('ocupado')) return 'ocupado';
        if (classList.contains('libre')) return 'libre';
        if (classList.contains('inhabilitado')) return 'inhabilitado';
        if (classList.contains('mantencion')) return 'mantencion';
        if (classList.contains('limpieza')) return 'limpieza';
        
        return 'libre'; // default
    },

    /**
     * Resalta la hora actual en la matriz
     * @private
     */
    _highlightCurrentTime() {
        if (!this.state.currentTime) return;

        // Buscar fila de la hora actual
        const currentTimeRow = document.querySelector(`[data-hora="${this.state.currentTime}"]`);
        if (currentTimeRow) {
            currentTimeRow.classList.add('hora-actual');
        }
    },

    /**
     * Actualiza el timestamp de última actualización
     * @private
     */
    _updateTimestamp() {
        const timestampElement = document.querySelector('#ultima-actualizacion');
        if (timestampElement) {
            const now = new Date();
            timestampElement.textContent = now.toLocaleTimeString('es-ES', {
                hour: '2-digit',
                minute: '2-digit'
            });
        }
    },

    // ========================================================================
    // ACTUALIZACIÓN AUTOMÁTICA
    // ========================================================================

    /**
     * Inicia la actualización automática
     * @private
     */
    _startAutoUpdate() {
        if (this.state.intervalId) {
            clearInterval(this.state.intervalId);
        }

        this.state.intervalId = setInterval(() => {
            this._performAutoUpdate();
        }, this.config.UPDATE_INTERVAL);

        this.log(`Actualización automática iniciada cada ${this.config.UPDATE_INTERVAL}ms`);
    },

    /**
     * Realiza una actualización automática
     * @private
     */
    _performAutoUpdate() {
        // Solo actualizar si la página está visible
        if (document.hidden) return;

        this.log('Realizando actualización automática...');
        this._updateCounters();
    },

    // ========================================================================
    // UTILIDADES
    // ========================================================================

    /**
     * Limpia recursos antes de cerrar
     * @private
     */
    _cleanup() {
        if (this.state.intervalId) {
            clearInterval(this.state.intervalId);
            this.state.intervalId = null;
        }

        this.log('Recursos limpiados');
    },

    /**
     * Log de desarrollo
     * @param {...any} args - Argumentos a loggear
     */
    log(...args) {
        if (this.config.DEBUG) {
            console.log('[PasilloVisualizador]', ...args);
        }
    },

    /**
     * Log de errores
     * @param {...any} args - Argumentos a loggear
     */
    error(...args) {
        console.error('[PasilloVisualizador ERROR]', ...args);
    },

    // ========================================================================
    // API PÚBLICA
    // ========================================================================

    /**
     * Recarga la visualización completa
     * @public
     */
    reload() {
        this.log('Recargando visualización...');
        window.location.reload();
    },

    /**
     * Actualiza solo los contadores
     * @public
     */
    updateCounters() {
        this._updateCounters();
    },

    /**
     * Abre modal de un box específico
     * @param {string} boxId - ID del box
     * @param {string} hora - Hora del slot
     * @public
     */
    openBoxModal(boxId, hora) {
        const boxElement = document.querySelector(`[data-box="${boxId}"][data-hora="${hora}"]`);
        if (boxElement) {
            this._handleBoxClick(boxElement);
        }
    }
};

// ============================================================================
// INICIALIZACIÓN AUTOMÁTICA
// ============================================================================
PasilloVisualizador.init();

// ============================================================================
// EXPOSICIÓN GLOBAL PARA DEBUGGING
// ============================================================================
if (window.pasilloConfig?.DEBUG) {
    window.PasilloVisualizador = PasilloVisualizador;
}
