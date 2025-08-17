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
        console.log('Configurando eventos para', this.dom.timeSlots.length, 'time slots');
        
        this.dom.timeSlots.forEach(timeSlot => {
            timeSlot.addEventListener('click', (event) => {
                event.preventDefault();
                event.stopPropagation();
                console.log('Click detectado en time-slot:', timeSlot.dataset);
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

            console.log('Box clickeado con datos:', boxData);
            this.state.lastClickedBox = boxData;

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

        // Incluir la hora específica del bloque clickeado
        const url = `${this.urls.detalleBox}?box_id=${boxData.box}&fecha=${boxData.fecha}&hora=${boxData.hora}`;
        
        console.log('Cargando detalles con URL:', url);
        console.log('Datos del box:', boxData);

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

        console.log('Respuesta del servidor:', data);

        // Generar el contenido HTML incluyendo la hora específica
        return this._generarContenidoModal(data, boxData.fecha, boxData.hora);
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
     * Genera el contenido HTML del modal con la información del box
     * @param {Object} data - Datos del box y agenda
     * @param {string} fecha - Fecha actual
     * @param {string} hora - Hora específica del bloque
     * @returns {string} HTML del contenido del modal
     * @private
     */
    _generarContenidoModal(data, fecha, hora = null) {
        let contenido = `
            <div class="row">
                <div class="col-12">
                    <h6><strong>Box ${data.box.id}</strong></h6>
                    <p><strong>Pasillo:</strong> ${data.box.pasillo}</p>
                    <p><strong>Capacidad:</strong> ${data.box.capacidad || 'No especificada'}</p>
                    <p><strong>Fecha:</strong> ${fecha}</p>
                    ${hora ? `<p><strong>Hora consultada:</strong> ${hora}</p>` : `<p><strong>Estado actual:</strong> ${new Date().toLocaleTimeString()}</p>`}
                    <hr>
        `;
        
        if (data.disponible) {
            contenido += `
                <div class="alert alert-success">
                    <h6><i class="bi bi-check-circle"></i> Box Disponible</h6>
                    <p>Este box está libre en ${hora ? 'la hora consultada' : 'este momento'}.</p>
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

// Exponer funciones necesarias para los templates (sin duplicados)
window.cerrarModal = cerrarModal;
window.aplicarFiltrosPasillo = aplicarFiltrosPasillo;
window.actualizarLineaHoraActual = actualizarLineaHoraActual;

// ============================================================================
// FUNCIONES GLOBALES PARA FILTROS (REQUERIDAS POR TEMPLATES)
// ============================================================================

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
 * Busca boxes por nombre de profesional
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
 * Limpia la búsqueda de profesional
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

// ============================================================================
// MÓDULO DE AGENDAMIENTO
// ============================================================================
const AgendamientoPanel = {
    
    // Configuración del panel
    config: {
        urls: {
            crearAgenda: '/crear-agenda/',
        },
        selectors: {
            panel: '#panel-agendamiento',
            form: '#form-agendamiento',
            boxSelect: '#agendamiento-box',
            fechaInput: '#agendamiento-fecha',
            horaInicioInput: '#agendamiento-hora-inicio',
            horaFinInput: '#agendamiento-hora-fin',
            profesionalSelect: '#agendamiento-profesional',
            tipoAgendaSelect: '#agendamiento-tipo-agenda',
            observacionesTextarea: '#agendamiento-observaciones',
            submitBtn: '#btn-crear-agenda',
            cancelBtn: '#btn-cancelar-agenda',
            profesionalSearch: '#profesional-search'
        }
    },
    
    /**
     * Inicializa el panel de agendamiento
     */
    init() {
        this.bindEvents();
        this.setupProfesionalSearch();
        this.setupFormValidation();
        console.log('Panel de agendamiento inicializado');
    },
    
    /**
     * Vincula los eventos del panel
     */
    bindEvents() {
        // Click en boxes para seleccionar
        $(document).on('click', '.time-slot', (e) => {
            const element = $(e.currentTarget);
            if (element.hasClass('ocupado')) return;
            
            this.seleccionarBox(element);
        });
        
        // Submit del formulario
        $(this.config.selectors.form).on('submit', (e) => {
            e.preventDefault();
            this.crearAgenda();
        });
        
        // Botón cancelar
        $(this.config.selectors.cancelBtn).on('click', () => {
            this.limpiarFormulario();
        });
        
        // Validación en tiempo real
        $(this.config.selectors.horaInicioInput + ', ' + this.config.selectors.horaFinInput).on('change', () => {
            this.validarHorarios();
        });
    },
    
    /**
     * Selecciona un box desde la tabla
     */
    seleccionarBox(element) {
        const boxId = element.data('box-id');
        const codigoBox = element.data('codigo-box');
        
        if (boxId && codigoBox) {
            $(this.config.selectors.boxSelect).val(boxId);
            
            // Mostrar información del box seleccionado
            this.mostrarInfoBoxSeleccionado(codigoBox);
            
            // Scroll al panel
            this.scrollToPanel();
        }
    },
    
    /**
     * Muestra información del box seleccionado
     */
    mostrarInfoBoxSeleccionado(codigoBox) {
        const infoHtml = `
            <div class="alert alert-info">
                <i class="fas fa-info-circle"></i>
                Box seleccionado: <strong>${codigoBox}</strong>
            </div>
        `;
        
        // Insertar antes del formulario
        $(this.config.selectors.form).prepend(infoHtml);
        
        // Remover después de 5 segundos
        setTimeout(() => {
            $(this.config.selectors.form + ' .alert').fadeOut();
        }, 5000);
    },
    
    /**
     * Scroll al panel de agendamiento
     */
    scrollToPanel() {
        $('html, body').animate({
            scrollTop: $(this.config.selectors.panel).offset().top - 100
        }, 500);
    },
    
    /**
     * Configura la búsqueda de profesionales
     */
    setupProfesionalSearch() {
        const searchInput = $(this.config.selectors.profesionalSearch);
        const selectElement = $(this.config.selectors.profesionalSelect);
        
        searchInput.on('input', function() {
            const searchTerm = $(this).val().toLowerCase();
            
            selectElement.find('option').each(function() {
                const optionText = $(this).text().toLowerCase();
                const shouldShow = optionText.includes(searchTerm) || $(this).val() === '';
                
                $(this).toggle(shouldShow);
            });
        });
    },
    
    /**
     * Configura validación del formulario
     */
    setupFormValidation() {
        // Establecer fecha mínima como hoy
        const today = new Date().toISOString().split('T')[0];
        $(this.config.selectors.fechaInput).attr('min', today);
    },
    
    /**
     * Valida los horarios ingresados
     */
    validarHorarios() {
        const horaInicio = $(this.config.selectors.horaInicioInput).val();
        const horaFin = $(this.config.selectors.horaFinInput).val();
        
        if (horaInicio && horaFin) {
            if (horaFin <= horaInicio) {
                this.mostrarError('La hora de fin debe ser posterior a la hora de inicio');
                return false;
            }
        }
        
        return true;
    },
    
    /**
     * Crea una nueva agenda
     */
    async crearAgenda() {
        if (!this.validarFormulario()) return;
        
        const formData = this.obtenerDatosFormulario();
        const submitBtn = $('#btn-confirmar-reserva'); // Usar el ID correcto del botón
        
        // Mostrar loading
        submitBtn.prop('disabled', true).html('<i class="fas fa-spinner fa-spin"></i> Creando...');
        
        try {
            const response = await fetch('/crear-agenda/', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'X-CSRFToken': this.getCsrfToken()
                },
                body: new URLSearchParams(formData)
            });
            
            const result = await response.json();
            
            if (result.success) {
                this.mostrarExito('Agenda creada exitosamente');
                this.limpiarFormulario();
                // Recargar la página para mostrar la nueva agenda
                setTimeout(() => window.location.reload(), 1500);
            } else {
                this.mostrarError(result.error || 'Error al crear la agenda');
            }
            
        } catch (error) {
            console.error('Error al crear agenda:', error);
            this.mostrarError('Error de conexión');
        } finally {
            submitBtn.prop('disabled', false).html('<i class="fas fa-check me-2"></i>Confirmar reserva');
        }
    },
    
    /**
     * Obtiene los datos del formulario
     */
    obtenerDatosFormulario() {
        return {
            box: $('#select-box').val(),
            fecha: $('#input-fecha').val(),
            hora_inicio: $('#input-hora-inicio').val(),
            hora_fin: $('#input-hora-fin').val(),
            profesional: $('#select-profesional').val() || '',
            tipo_agenda: $('#select-tipo-agenda').val()
        };
    },
    
    /**
     * Valida el formulario antes del envío
     */
    validarFormulario() {
        const datos = this.obtenerDatosFormulario();
        
        // Validar campos requeridos (según tus especificaciones)
        const camposRequeridos = ['box', 'fecha', 'hora_inicio', 'hora_fin', 'tipo_agenda'];
        
        for (let campo of camposRequeridos) {
            if (!datos[campo]) {
                const nombres = {
                    'box': 'Box',
                    'fecha': 'Fecha',
                    'hora_inicio': 'Hora de inicio',
                    'hora_fin': 'Hora de fin',
                    'tipo_agenda': 'Tipo de agenda'
                };
                this.mostrarError(`El campo ${nombres[campo]} es requerido`);
                return false;
            }
        }
        
        // Validar horarios
        if (!this.validarHorarios()) return false;
        
        return true;
    },
    
    /**
     * Limpia el formulario
     */
    limpiarFormulario() {
        $('#form-agendamiento')[0].reset();
        $('#form-agendamiento .alert').remove();
        // Restablecer fecha actual
        const today = new Date().toISOString().split('T')[0];
        $('#input-fecha').val(today);
    },
    
    /**
     * Muestra mensaje de error
     */
    mostrarError(mensaje) {
        this.mostrarMensaje(mensaje, 'danger');
    },
    
    /**
     * Obtiene los datos del formulario
     */
    obtenerDatosFormulario() {
        return {
            box: $(this.config.selectors.boxSelect).val(),
            fecha: $(this.config.selectors.fechaInput).val(),
            hora_inicio: $(this.config.selectors.horaInicioInput).val(),
            hora_fin: $(this.config.selectors.horaFinInput).val(),
            profesional: $(this.config.selectors.profesionalSelect).val(),
            tipo_agenda: $(this.config.selectors.tipoAgendaSelect).val(),
            observaciones: $(this.config.selectors.observacionesTextarea).val()
        };
    },
    
    /**
     * Valida el formulario antes del envío
     */
    validarFormulario() {
        const datos = this.obtenerDatosFormulario();
        
        // Validar campos requeridos
        const camposRequeridos = ['box', 'fecha', 'hora_inicio', 'hora_fin', 'profesional', 'tipo_agenda'];
        
        for (let campo of camposRequeridos) {
            if (!datos[campo]) {
                this.mostrarError(`El campo ${campo.replace('_', ' ')} es requerido`);
                return false;
            }
        }
        
        // Validar horarios
        if (!this.validarHorarios()) return false;
        
        return true;
    },
    
    /**
     * Limpia el formulario
     */
    limpiarFormulario() {
        $(this.config.selectors.form)[0].reset();
        $(this.config.selectors.form + ' .alert').remove();
    },
    
    /**
     * Muestra mensaje de error
     */
    mostrarError(mensaje) {
        this.mostrarMensaje(mensaje, 'danger');
    },
    
    /**
     * Muestra mensaje de éxito
     */
    mostrarExito(mensaje) {
        this.mostrarMensaje(mensaje, 'success');
    },
    
    /**
     * Muestra un mensaje en el panel
     */
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
    
    /**
     * Obtiene el token CSRF
     */
    getCsrfToken() {
        return document.querySelector('[name=csrfmiddlewaretoken]').value;
    }
};

// Inicializar el panel de agendamiento cuando esté listo el DOM
$(document).ready(function() {
    AgendamientoPanel.init();
});
