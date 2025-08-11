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
        timeLineIntervalId: null,
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

        // Usar el mismo formato que la visualización general
        const url = `${this.urls.detalleBox}?box_id=${boxData.box}&fecha=${boxData.fecha}`;

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

        // Generar el contenido HTML usando la misma función que visualización general
        return this._generarContenidoModal(data, boxData.fecha);
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
     * Genera el contenido HTML del modal con la información del box (igual que visualización general)
     * @param {Object} data - Datos del box y agenda
     * @param {string} fecha - Fecha actual
     * @returns {string} HTML del contenido del modal
     * @private
     */
    _generarContenidoModal(data, fecha) {
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
        try {
            // Limpiar marcadores anteriores
            document.querySelectorAll('.hora-actual').forEach(el => {
                el.classList.remove('hora-actual');
            });
            
            // Remover línea anterior si existe
            const lineaAnterior = document.getElementById('linea-hora-actual');
            if (lineaAnterior) {
                lineaAnterior.remove();
            }

            // Obtener hora actual
            const now = new Date();
            const horaActual = now.getHours().toString().padStart(2, '0') + ':' + 
                             now.getMinutes().toString().padStart(2, '0');
            
            // Buscar la tabla de boxes
            const tabla = document.querySelector('.table-boxes');
            if (!tabla) {
                this.log('Tabla de boxes no encontrada');
                return;
            }

            // Buscar todas las filas de horario
            const filasHorario = tabla.querySelectorAll('.fila-horario');
            if (filasHorario.length === 0) {
                this.log('No se encontraron filas de horario');
                return;
            }

            // Encontrar la posición de inserción para la línea
            let filaAnterior = null;
            let filaSiguiente = null;
            let posicionExacta = false;

            for (let i = 0; i < filasHorario.length; i++) {
                const fila = filasHorario[i];
                const horaFila = fila.dataset.hora;
                
                if (horaFila === horaActual) {
                    // Hora exacta encontrada
                    fila.classList.add('hora-actual');
                    posicionExacta = true;
                    this._crearLineaHoraActual(fila, 0);
                    break;
                } else if (horaFila < horaActual) {
                    filaAnterior = fila;
                } else if (horaFila > horaActual && !filaSiguiente) {
                    filaSiguiente = fila;
                    break;
                }
            }

            // Si no hay hora exacta, calcular posición entre dos horas
            if (!posicionExacta && filaAnterior && filaSiguiente) {
                const porcentaje = this._calcularPorcentajeEntreHoras(
                    filaAnterior.dataset.hora, 
                    filaSiguiente.dataset.hora, 
                    horaActual
                );
                this._crearLineaHoraActual(filaAnterior, porcentaje);
            } else if (!posicionExacta && filaAnterior) {
                // Hora actual está después de la última hora mostrada
                this._crearLineaHoraActual(filaAnterior, 100);
            }

            this.log(`Hora actual resaltada: ${horaActual}`);

        } catch (error) {
            this.error('Error al resaltar hora actual:', error);
        }
    },

    /**
     * Crea la línea roja de hora actual
     * @param {HTMLElement} filaReferencia - Fila de referencia
     * @param {number} porcentaje - Porcentaje de offset (0-100)
     * @private
     */
    _crearLineaHoraActual(filaReferencia, porcentaje) {
        const contenedorTabla = document.querySelector('.contenedor-tabla');
        if (!contenedorTabla) return;

        // Crear la línea
        const linea = document.createElement('div');
        linea.id = 'linea-hora-actual';
        linea.style.position = 'absolute';
        linea.style.left = '0';
        linea.style.right = '0';
        linea.style.height = '3px';
        linea.style.backgroundColor = 'var(--color-hora-actual, #dc3545)';
        linea.style.zIndex = '20';
        linea.style.boxShadow = '0 0 10px rgba(220, 53, 69, 0.5)';
        linea.style.pointerEvents = 'none';

        // Calcular posición
        const rectFila = filaReferencia.getBoundingClientRect();
        const rectContenedor = contenedorTabla.getBoundingClientRect();
        
        const alturaFila = rectFila.height;
        const offsetTop = rectFila.top - rectContenedor.top + contenedorTabla.scrollTop;
        const posicionFinal = offsetTop + (alturaFila * porcentaje / 100);

        linea.style.top = `${posicionFinal}px`;

        // Insertar la línea
        contenedorTabla.style.position = 'relative';
        contenedorTabla.appendChild(linea);

        this.log(`Línea de hora actual creada en posición: ${posicionFinal}px`);
    },

    /**
     * Calcula el porcentaje entre dos horas donde se encuentra la hora actual
     * @param {string} horaAnterior - Hora anterior (HH:MM)
     * @param {string} horaSiguiente - Hora siguiente (HH:MM)
     * @param {string} horaActual - Hora actual (HH:MM)
     * @returns {number} Porcentaje (0-100)
     * @private
     */
    _calcularPorcentajeEntreHoras(horaAnterior, horaSiguiente, horaActual) {
        const parseHora = (hora) => {
            const [h, m] = hora.split(':').map(Number);
            return h * 60 + m; // Convertir a minutos
        };

        const minutosAnterior = parseHora(horaAnterior);
        const minutosSiguiente = parseHora(horaSiguiente);
        const minutosActual = parseHora(horaActual);

        const totalMinutos = minutosSiguiente - minutosAnterior;
        const minutosTranscurridos = minutosActual - minutosAnterior;

        return (minutosTranscurridos / totalMinutos) * 100;
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
        if (this.state.timeLineIntervalId) {
            clearInterval(this.state.timeLineIntervalId);
        }

        // Actualización general (contadores, etc.)
        this.state.intervalId = setInterval(() => {
            this._performAutoUpdate();
        }, this.config.UPDATE_INTERVAL);

        // Actualización más frecuente para la línea de hora (cada minuto)
        this.state.timeLineIntervalId = setInterval(() => {
            this._highlightCurrentTime();
        }, 60000); // 60 segundos

        this.log(`Actualización automática iniciada cada ${this.config.UPDATE_INTERVAL}ms`);
        this.log('Actualización de línea de hora cada 60 segundos');
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
        this._highlightCurrentTime(); // Actualizar línea de hora actual
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
        
        if (this.state.timeLineIntervalId) {
            clearInterval(this.state.timeLineIntervalId);
            this.state.timeLineIntervalId = null;
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
// CONFIGURACIÓN ADICIONAL DE MODALES Y HORA ACTUAL
// ============================================================================
document.addEventListener('DOMContentLoaded', function() {
    // Configurar eventos de cierre del modal
    const modal = document.getElementById('detalleModal');
    if (modal) {
        // Limpiar backdrop al cerrar modal
        modal.addEventListener('hidden.bs.modal', function () {
            // Limpiar cualquier backdrop que pueda quedar
            document.querySelectorAll('.modal-backdrop').forEach(backdrop => {
                backdrop.remove();
            });
            // Restaurar el scroll del body
            document.body.classList.remove('modal-open');
            document.body.style.overflow = '';
            document.body.style.paddingRight = '';
        });
        
        // Manejar click en backdrop
        modal.addEventListener('click', function(event) {
            if (event.target === modal) {
                cerrarModal();
            }
        });
        
        // Manejar tecla Escape
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape' && modal.classList.contains('show')) {
                cerrarModal();
            }
        });
    }
    
    // Ejecutar línea de hora actual después de un breve delay para asegurar que el DOM esté completamente cargado
    setTimeout(() => {
        if (window.PasilloVisualizador) {
            window.PasilloVisualizador._highlightCurrentTime();
        }
    }, 500);
});

// ============================================================================
// EXPOSICIÓN GLOBAL PARA DEBUGGING Y TEMPLATES
// ============================================================================
// Exponer siempre PasilloVisualizador para acceso a funciones internas
window.PasilloVisualizador = PasilloVisualizador;

// Exponer funciones necesarias para los templates
window.mostrarDetalle = mostrarDetalle;
window.cerrarModal = cerrarModal;
window.aplicarFiltrosPasillo = aplicarFiltrosPasillo;
window.actualizarLineaHoraActual = actualizarLineaHoraActual;

// ============================================================================
// FUNCIONES GLOBALES PARA FILTROS (REQUERIDAS POR TEMPLATES)
// ============================================================================

/**
 * Función global para mostrar detalle del box (compatible con templates)
 * @param {string} boxId - ID del box
 * @param {boolean} disponible - Estado del box
 */
function mostrarDetalle(boxId, disponible) {
    // Usar la misma lógica que visualización general
    const fecha = document.querySelector('meta[name="fecha"]')?.content || 
                  new Date().toISOString().split('T')[0];
    const detalleUrl = window.detalleBoxUrl || '/detalle-box/';
    const url = `${detalleUrl}?box_id=${boxId}&fecha=${fecha}`;
    
    // Obtener elementos del modal
    const modal = document.getElementById('detalleModal');
    const modalContent = document.getElementById('modalContent');
    
    if (!modal || !modalContent) {
        console.error('Modal no encontrado');
        return;
    }
    
    // Mostrar loader en modal
    modalContent.innerHTML = `
        <div class="text-center py-4">
            <div class="spinner-border text-primary" role="status">
                <span class="visually-hidden">Cargando...</span>
            </div>
            <p class="mt-2 text-muted">Cargando detalles del box...</p>
        </div>
    `;
    
    // Crear instancia del modal y configurar eventos de cierre
    let modalInstance;
    try {
        if (typeof bootstrap !== 'undefined' && bootstrap.Modal) {
            modalInstance = bootstrap.Modal.getOrCreateInstance(modal);
            
            // Configurar eventos de cierre del modal
            modal.addEventListener('hidden.bs.modal', function () {
                // Limpiar backdrop manualmente si queda
                const backdrop = document.querySelector('.modal-backdrop');
                if (backdrop) {
                    backdrop.remove();
                }
                // Restaurar el scroll del body
                document.body.classList.remove('modal-open');
                document.body.style.overflow = '';
                document.body.style.paddingRight = '';
            });
            
            modalInstance.show();
        } else {
            // Fallback si Bootstrap no está disponible
            modal.style.display = 'block';
            modal.classList.add('show');
            document.body.classList.add('modal-open');
        }
    } catch (error) {
        console.error('Error al mostrar modal:', error);
        return;
    }
    
    // Cargar datos
    fetch(url)
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            return response.json();
        })
        .then(data => {
            if (data.error) {
                throw new Error('Error al cargar detalles: ' + data.error);
            }
            
            const contenido = _generarContenidoModalGlobal(data, fecha);
            modalContent.innerHTML = contenido;
        })
        .catch(error => {
            console.error('Error en la petición:', error);
            modalContent.innerHTML = `
                <div class="alert alert-danger">
                    <h6><i class="bi bi-exclamation-triangle"></i> Error</h6>
                    <p>No se pudieron cargar los detalles del box.</p>
                    <small>${error.message}</small>
                </div>
            `;
        });
}

/**
 * Función auxiliar para generar contenido del modal (versión global)
 * @param {Object} data - Datos del box y agenda
 * @param {string} fecha - Fecha actual
 * @returns {string} HTML del contenido del modal
 * @private
 */
function _generarContenidoModalGlobal(data, fecha) {
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
 * Función para cerrar el modal manualmente
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
            // Fallback manual
            modal.style.display = 'none';
            modal.classList.remove('show');
            document.body.classList.remove('modal-open');
        }
        
        // Limpiar backdrop manualmente
        const backdrop = document.querySelector('.modal-backdrop');
        if (backdrop) {
            backdrop.remove();
        }
        
        // Restaurar el scroll del body
        document.body.style.overflow = '';
        document.body.style.paddingRight = '';
        
    } catch (error) {
        console.error('Error al cerrar modal:', error);
        // Forzar limpieza manual
        modal.style.display = 'none';
        modal.classList.remove('show');
        document.body.classList.remove('modal-open');
        document.body.style.overflow = '';
        document.body.style.paddingRight = '';
        
        // Limpiar todos los backdrops
        document.querySelectorAll('.modal-backdrop').forEach(backdrop => {
            backdrop.remove();
        });
    }
}

/**
 * Función global para actualizar la línea de hora actual manualmente
 */
function actualizarLineaHoraActual() {
    if (window.PasilloVisualizador) {
        window.PasilloVisualizador._highlightCurrentTime();
    }
}

/**
 * Aplica los filtros seleccionados y recarga la página
 */
function aplicarFiltrosPasillo() {
    const filtros = _obtenerFiltrosActivosPasillo();
    const url = _construirUrlConFiltrosPasillo(filtros);
    window.location.href = url;
}

/**
 * Busca boxes por nombre de médico
 */
function buscarPorMedicoPasillo() {
    const nombreMedico = document.getElementById('nombreMedico')?.value?.trim();
    if (nombreMedico) {
        const url = new URL(window.location);
        url.searchParams.set('medico', nombreMedico);
        url.searchParams.delete('page'); // Reset pagination
        window.location.href = url.toString();
    }
}

/**
 * Limpia la búsqueda de médico
 */
function limpiarBusquedaMedicoPasillo() {
    const url = new URL(window.location);
    url.searchParams.delete('medico');
    url.searchParams.delete('page');
    window.location.href = url.toString();
}

/**
 * Busca boxes por código de box
 */
function buscarPorBoxPasillo() {
    const codigoBox = document.getElementById('codigoBox')?.value?.trim();
    if (codigoBox) {
        const url = new URL(window.location);
        url.searchParams.set('box', codigoBox);
        url.searchParams.delete('page'); // Reset pagination
        window.location.href = url.toString();
    }
}

/**
 * Limpia la búsqueda de box
 */
function limpiarBusquedaBoxPasillo() {
    const url = new URL(window.location);
    url.searchParams.delete('box');
    url.searchParams.delete('page');
    window.location.href = url.toString();
}

/**
 * Remueve un filtro específico
 * @param {string} tipoFiltro - Tipo de filtro a remover ('pasillo', 'medico', 'box')
 */
function removerFiltroPasillo(tipoFiltro) {
    const url = new URL(window.location);
    
    switch(tipoFiltro) {
        case 'pasillo':
            url.searchParams.delete('pasillo');
            break;
        case 'medico':
            url.searchParams.delete('medico');
            break;
        case 'box':
            url.searchParams.delete('box');
            break;
    }
    
    url.searchParams.delete('page'); // Reset pagination
    window.location.href = url.toString();
}

/**
 * Limpia todos los filtros activos excepto la fecha
 */
function limpiarTodosFiltrosPasillo() {
    const url = new URL(window.location);
    const fecha = url.searchParams.get('fecha'); // Preservar la fecha
    
    // Limpiar todos los parámetros excepto fecha
    url.search = '';
    if (fecha) {
        url.searchParams.set('fecha', fecha);
    }
    
    window.location.href = url.toString();
}

// ============================================================================
// FUNCIONES AUXILIARES PARA FILTROS
// ============================================================================

/**
 * Obtiene los filtros activos del formulario
 * @returns {Object} Objeto con los filtros activos
 * @private
 */
function _obtenerFiltrosActivosPasillo() {
    const fecha = document.getElementById('fecha')?.value || '';
    const pasillo = document.getElementById('pasillo')?.value || '';
    const jornada = document.getElementById('jornada')?.value || '';
    const nombreMedico = document.getElementById('nombreMedico')?.value || '';
    const codigoBox = document.getElementById('codigoBox')?.value || '';
    
    return { fecha, pasillo, jornada, medico: nombreMedico, box: codigoBox };
}

/**
 * Construye la URL con los filtros aplicados
 * @param {Object} filtros - Objeto con los filtros
 * @returns {string} URL construida
 * @private
 */
function _construirUrlConFiltrosPasillo(filtros) {
    const url = new URL(window.location.origin + window.location.pathname);
    
    // Agregar filtros no vacíos
    Object.keys(filtros).forEach(key => {
        if (filtros[key]) {
            url.searchParams.set(key, filtros[key]);
        }
    });
    
    return url.toString();
}
