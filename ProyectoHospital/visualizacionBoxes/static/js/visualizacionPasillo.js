// ============================================================================
// VISUALIZACIÓN DE PASILLOS - SISTEMA HOSPITALARIO
// ============================================================================

/**
 * Configuración global y funcionalidad principal para la visualización de pasillos
 */
const PasilloVisualizador = {
    // ========================================================================
    // CONFIGURACIÓN
    // ========================================================================
    config: {
        DEBUG: false,
        UPDATE_INTERVAL: 30000, // 30 segundos
        BOXES_POR_PAGINA: 8,
        LOCALE: "es"
    },

    // URLs de la aplicación
    urls: {
        detalleBox: null,
        buscarMedicos: null
    },

    // Estado interno
    estado: {
        inicializado: false,
        intervalId: null,
        fechaActual: null,
        horaActual: null
    },

    // ========================================================================
    // INICIALIZACIÓN
    // ========================================================================

    /**
     * Inicializa toda la funcionalidad del visualizador
     */
    init() {
        if (this.estado.inicializado) return;

        document.addEventListener('DOMContentLoaded', () => {
            this.configurarUrls();
            this.configurarEventos();
            this.inicializarVisualizacion();
            this.iniciarActualizacionAutomatica();
            
            this.estado.inicializado = true;
            this.log('Visualizador de pasillos inicializado');
        });
    },

    /**
     * Configura las URLs desde las variables globales
     */
    configurarUrls() {
        this.urls.detalleBox = window.detalleBoxUrl;
        if (window.medicosUrls) {
            this.urls.buscarMedicos = window.medicosUrls.buscar_medicos;
        }
    },

    /**
     * Configura todos los eventos necesarios
     */
    configurarEventos() {
        this.configurarEventosCeldas();
        this.configurarEventosModal();
    },

    /**
     * Inicializa elementos visuales
     */
    inicializarVisualizacion() {
        this.obtenerConfiguracion();
        this.marcarHoraActual();
        this.inicializarLineaHoraActual();
        this.actualizarContadores();
    },

    /**
     * Obtiene configuración desde variables globales
     */
    obtenerConfiguracion() {
        if (window.pasilloConfig) {
            this.estado.horaActual = window.pasilloConfig.HORA_ACTUAL;
            this.estado.fechaActual = window.pasilloConfig.FECHA_ACTUAL;
        }
        
        // Fallback a meta tag
        if (!this.estado.fechaActual) {
            const metaFecha = document.querySelector('meta[name="fecha"]');
            this.estado.fechaActual = metaFecha?.content || new Date().toISOString().split('T')[0];
        }
    },

    // ========================================================================
    // GESTIÓN DE EVENTOS
    // ========================================================================

    /**
     * Configura eventos de click en las celdas de la tabla
     */
    configurarEventosCeldas() {
        document.querySelectorAll('.time-slot').forEach(celda => {
            celda.addEventListener('click', (event) => {
                const { box, hora, pasillo } = celda.dataset;
                const disponible = this.determinarDisponibilidad(celda);
                
                this.mostrarDetalleBox(box, disponible, hora, pasillo);
            });
        });
    },

    /**
     * Configura eventos del modal
     */
    configurarEventosModal() {
        const modal = document.getElementById('detalleModal');
        if (modal) {
            modal.addEventListener('hidden.bs.modal', () => {
                this.limpiarModal();
            });
        }
    },

    /**
     * Determina si un box está disponible basado en las clases CSS
     */
    determinarDisponibilidad(celda) {
        const clasesOcupado = ['ocupado', 'inhabilitado', 'mantencion', 'limpieza'];
        return !clasesOcupado.some(clase => celda.classList.contains(clase));
    },

    // ========================================================================
    // FUNCIONALIDAD DE DETALLE DE BOXES
    // ========================================================================

    /**
     * Muestra el modal con detalles de un box específico (versión unificada)
     */
    async mostrarDetalleBox(boxId, disponible, hora = null, pasillo = null) {
        if (!this.urls.detalleBox) {
            this.mostrarError('URL de detalle no configurada');
            return;
        }

        try {
            this.mostrarLoader();
            
            const url = this.construirUrlDetalle(boxId);
            const response = await fetch(url);
            const data = await response.json();
            
            this.ocultarLoader();
            
            if (data.error) {
                this.mostrarError('Error al cargar detalles: ' + data.error);
                return;
            }
            
            // Usar la función unificada idéntica a visualizacionGeneral
            const contenido = this.generarContenidoModalUnificado(data);
            this.mostrarModal(contenido);
            
        } catch (error) {
            this.ocultarLoader();
            this.log('Error en petición de detalle:', error);
            this.mostrarError('Error de conexión al obtener los detalles del box');
        }
    },

    /**
     * Construye la URL para obtener detalles de un box
     */
    construirUrlDetalle(boxId) {
        const fecha = this.estado.fechaActual;
        return `${this.urls.detalleBox}?box_id=${boxId}&fecha=${fecha}`;
    },

    /**
     * Genera el contenido HTML del modal (versión unificada igual a visualizacionGeneral)
     */
    generarContenidoModalUnificado(data) {
        const fecha = this.estado.fechaActual;
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

    // ========================================================================
    // GESTIÓN DEL MODAL
    // ========================================================================

    /**
     * Muestra el modal con el contenido proporcionado
     */
    mostrarModal(contenido) {
        let modal = document.getElementById('detalleModal');
        
        if (!modal) {
            modal = this.crearModal();
            document.body.appendChild(modal);
        }
        
        const modalBody = modal.querySelector('.modal-body');
        if (modalBody) {
            modalBody.innerHTML = contenido;
        }
        
        // Mostrar modal usando Bootstrap
        if (typeof bootstrap !== 'undefined' && bootstrap.Modal) {
            const modalInstance = new bootstrap.Modal(modal);
            modalInstance.show();
        } else {
            // Fallback manual
            modal.style.display = 'block';
            modal.classList.add('show');
            document.body.classList.add('modal-open');
        }
    },

    /**
     * Crea el elemento modal dinámicamente si no existe (versión unificada)
     */
    crearModal() {
        const modal = document.createElement('div');
        modal.id = 'detalleModal';
        modal.className = 'modal fade';
        modal.innerHTML = `
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">Detalle del Box</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <!-- Contenido dinámico -->
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cerrar</button>
                    </div>
                </div>
            </div>
        `;
        return modal;
    },

    /**
     * Limpia el contenido del modal
     */
    limpiarModal() {
        const modal = document.getElementById('detalleModal');
        if (modal) {
            const modalBody = modal.querySelector('.modal-body');
            if (modalBody) {
                modalBody.innerHTML = '';
            }
        }
    },
    // ========================================================================
    // GESTIÓN DE LOADERS Y MENSAJES
    // ========================================================================

    /**
     * Muestra un indicador de carga
     */
    mostrarLoader() {
        this.log('Cargando detalle del box...');
        
        // Mostrar spinner en el modal si existe
        const modalBody = document.querySelector('#detalleModal .modal-body');
        if (modalBody) {
            modalBody.innerHTML = `
                <div class="text-center py-4">
                    <div class="spinner-border text-primary" role="status">
                        <span class="visually-hidden">Cargando...</span>
                    </div>
                    <div class="mt-2">
                        <small class="text-muted">Cargando información del box...</small>
                    </div>
                </div>
            `;
        }
    },

    /**
     * Oculta el indicador de carga
     */
    ocultarLoader() {
        this.log('Carga del detalle completada');
    },

    /**
     * Muestra un mensaje de error al usuario
     */
    mostrarError(mensaje) {
        this.log('Error: ' + mensaje);
        
        // Mostrar error en el modal si está abierto
        const modalBody = document.querySelector('#detalleModal .modal-body');
        if (modalBody && document.getElementById('detalleModal').classList.contains('show')) {
            modalBody.innerHTML = `
                <div class="alert alert-danger">
                    <div class="d-flex align-items-center">
                        <i class="fas fa-exclamation-triangle fa-2x text-danger me-3"></i>
                        <div>
                            <h6 class="mb-1">Error al cargar información</h6>
                            <p class="mb-0">${mensaje}</p>
                        </div>
                    </div>
                </div>
            `;
            return;
        }
        
        // Mostrar con SweetAlert si está disponible, sino usar alert
        if (typeof Swal !== 'undefined') {
            Swal.fire({
                icon: 'error',
                title: 'Error',
                text: mensaje,
                confirmButtonText: 'Entendido'
            });
        } else {
            alert('Error: ' + mensaje);
        }
    },

    // ========================================================================
    // VISUALIZACIÓN Y ESTADO
    // ========================================================================

    /**
     * Marca la hora actual en la tabla
     */
    marcarHoraActual() {
        if (!this.estado.horaActual) return;

        // Remover marcas previas
        document.querySelectorAll('.fila-horario.hora-actual').forEach(fila => {
            fila.classList.remove('hora-actual');
        });
        
        // Marcar nueva hora actual
        document.querySelectorAll('.fila-horario').forEach(fila => {
            if (fila.dataset.hora === this.estado.horaActual) {
                fila.classList.add('hora-actual');
                // Scroll suave a la hora actual
                fila.scrollIntoView({ 
                    behavior: 'smooth', 
                    block: 'center' 
                });
            }
        });
    },

    /**
     * Actualiza los contadores de boxes libres y ocupados
     */
    actualizarContadores() {
        const horaActual = this.estado.horaActual;
        if (!horaActual) {
            // Si no hay hora actual, contar todos los boxes visibles
            this.contarTodosLosBoxes();
            return;
        }

        // Contar boxes en la hora actual
        const celdasHoraActual = document.querySelectorAll(`.fila-horario[data-hora="${horaActual}"] .time-slot`);
        
        let libres = 0;
        let ocupados = 0;
        
        celdasHoraActual.forEach(celda => {
            if (this.determinarDisponibilidad(celda)) {
                libres++;
            } else {
                ocupados++;
            }
        });
        
        this.actualizarContadoresUI(libres, ocupados);
    },

    /**
     * Cuenta todos los boxes cuando no hay hora específica
     */
    contarTodosLosBoxes() {
        const todasLasCeldas = document.querySelectorAll('.time-slot');
        let libres = 0;
        let ocupados = 0;
        
        todasLasCeldas.forEach(celda => {
            if (this.determinarDisponibilidad(celda)) {
                libres++;
            } else {
                ocupados++;
            }
        });
        
        // Promedio por hora
        const totalHoras = document.querySelectorAll('.fila-horario').length;
        if (totalHoras > 0) {
            libres = Math.round(libres / totalHoras);
            ocupados = Math.round(ocupados / totalHoras);
        }
        
        this.actualizarContadoresUI(libres, ocupados);
    },

    /**
     * Actualiza los elementos UI de contadores
     */
    actualizarContadoresUI(libres, ocupados) {
        const contadorLibres = document.getElementById('boxes-libres');
        const contadorOcupados = document.getElementById('boxes-ocupados');
        
        if (contadorLibres) {
            const spanLibres = contadorLibres.querySelector('span') || contadorLibres;
            spanLibres.textContent = libres;
        }
        if (contadorOcupados) {
            const spanOcupados = contadorOcupados.querySelector('span') || contadorOcupados;
            spanOcupados.textContent = ocupados;
        }
        
        // Actualizar hora de última actualización
        const ultimaActualizacion = document.getElementById('ultima-actualizacion');
        if (ultimaActualizacion) {
            ultimaActualizacion.textContent = new Date().toLocaleTimeString('es-ES', {
                hour: '2-digit',
                minute: '2-digit'
            });
        }
    },

    /**
     * Inicializa la línea indicadora de hora actual
     */
    inicializarLineaHoraActual() {
        const grilla = document.querySelector('.contenedor-tabla');
        if (!grilla) return;
        
        const tabla = grilla.querySelector('.table-boxes');
        if (!tabla) return;

        tabla.style.position = 'relative';

        let linea = tabla.querySelector('#linea-hora-actual');
        if (!linea) {
            linea = this.crearLineaHoraActual();
            tabla.appendChild(linea);
        }

        const actualizarLinea = () => {
            const top = this.calcularPosicionLinea(tabla);
            if (top >= 0) {
                linea.style.top = top + 'px';
                linea.style.display = 'block';
            } else {
                linea.style.display = 'none';
            }
        };

        actualizarLinea();
        
        // Actualizar cada minuto
        setInterval(actualizarLinea, 60000);
    },

    /**
     * Crea el elemento visual de la línea roja de hora actual
     */
    crearLineaHoraActual() {
        const linea = document.createElement('div');
        linea.id = 'linea-hora-actual';
        linea.style.cssText = `
            position: absolute;
            left: 0;
            right: 0;
            height: 2px;
            background: #dc3545;
            z-index: 10;
            box-shadow: 0 0 3px rgba(220, 53, 69, 0.5);
            display: none;
        `;
        return linea;
    },

    /**
     * Calcula la posición de la línea de hora actual
     */
    calcularPosicionLinea(tabla) {
        const ahora = new Date();
        const horaActual = ahora.getHours();
        const minutosActual = ahora.getMinutes();
        
        const filas = Array.from(tabla.querySelectorAll('tbody tr')).filter(fila => 
            fila.offsetParent !== null
        );
        
        if (filas.length === 0) return -1;
        
        const horasFilas = filas.map(fila => {
            const celdaHora = fila.querySelector('.celda-hora');
            if (!celdaHora) return null;
            
            const texto = celdaHora.textContent.trim();
            const match = texto.match(/(\d{1,2}):(\d{2})/);
            if (!match) return null;
            
            const h = parseInt(match[1], 10);
            const m = parseInt(match[2], 10);
            return h + m / 60;
        });
        
        const horaDecimal = horaActual + minutosActual / 60;
        let idx = -1;
        
        // Encontrar la fila de hora más cercana
        for (let i = 0; i < horasFilas.length; i++) {
            if (horasFilas[i] !== null && horasFilas[i] <= horaDecimal) {
                idx = i;
            }
        }
        
        if (idx === -1) return -1;
        
        const filaActual = filas[idx];
        const alturaFila = filaActual.offsetHeight;
        const minutosEnBloque = (horaDecimal - horasFilas[idx]) * 60;
        
        let minutosBloque = 30; // Por defecto 30 minutos
        if (idx + 1 < horasFilas.length && horasFilas[idx + 1] !== null) {
            minutosBloque = (horasFilas[idx + 1] - horasFilas[idx]) * 60;
        }
        
        const desplazamiento = Math.max(0, Math.min(alturaFila, 
            (minutosEnBloque / minutosBloque) * alturaFila
        ));
        
        const top = filaActual.offsetTop + desplazamiento;
        return Math.max(0, Math.min(tabla.offsetHeight - 2, top));
    },

    // ========================================================================
    // ACTUALIZACIÓN AUTOMÁTICA
    // ========================================================================

    /**
     * Inicia la actualización automática de la visualización
     */
    iniciarActualizacionAutomatica() {
        // Actualizar cada 30 segundos
        this.estado.intervalId = setInterval(() => {
            this.actualizarVisualizacion();
        }, this.config.UPDATE_INTERVAL);
    },

    /**
     * Actualiza la visualización sin recargar la página
     */
    actualizarVisualizacion() {
        this.estado.horaActual = new Date().toTimeString().substr(0, 5);
        this.marcarHoraActual();
        this.actualizarContadores();
        
        this.log('Visualización actualizada automáticamente');
    },

    /**
     * Detiene la actualización automática
     */
    detenerActualizacionAutomatica() {
        if (this.estado.intervalId) {
            clearInterval(this.estado.intervalId);
            this.estado.intervalId = null;
        }
    },

    // ========================================================================
    // UTILIDADES
    // ========================================================================

    /**
     * Función de logging condicional
     */
    log(...args) {
        if (this.config.DEBUG) {
            console.log('[PasilloVisualizador]', ...args);
        }
    },

    /**
     * Limpia recursos al salir
     */
    destruir() {
        this.detenerActualizacionAutomatica();
        this.limpiarModal();
        this.estado.inicializado = false;
        this.log('Visualizador destruido');
    }
};

// ============================================================================
// INICIALIZACIÓN Y EXPORTACIÓN GLOBAL
// ============================================================================

// Inicializar automáticamente
PasilloVisualizador.init();

// Exportar funciones para compatibilidad con código existente
window.mostrarDetalle = (boxId, disponible) => {
    PasilloVisualizador.mostrarDetalleBox(boxId, disponible);
};

// Exportar el objeto principal
window.PasilloVisualizador = PasilloVisualizador;

// Limpieza al cerrar la página
window.addEventListener('beforeunload', () => {
    PasilloVisualizador.destruir();
});

// ============================================================================
// FUNCIONES DE FILTROS SUPERIORES
// ============================================================================

// Función global para aplicar los filtros superiores
window.aplicarFiltrosPasillo = function() {
  var pasillo = document.getElementById('pasillo').value;
  var jornada = document.getElementById('jornada').value;
  var fecha = document.getElementById('fecha').value;
  var nombreMedico = document.getElementById('nombreMedico') ? document.getElementById('nombreMedico').value : '';

  var params = [];
  if (pasillo) params.push('pasillo=' + encodeURIComponent(pasillo));
  if (jornada) params.push('jornada=' + encodeURIComponent(jornada));
  if (fecha) params.push('fecha=' + encodeURIComponent(fecha));
  if (nombreMedico) params.push('medico=' + encodeURIComponent(nombreMedico));

  var queryString = params.length ? ('?' + params.join('&')) : '';
  window.location.href = window.location.pathname + queryString;
};

// Función para buscar por médico
window.buscarPorMedicoPasillo = function() {
  const nombreMedico = document.getElementById('nombreMedico').value.trim();
  if (nombreMedico) {
    aplicarFiltrosPasillo();
  }
};

// Función para buscar por código de box
window.buscarPorBoxPasillo = function() {
  const codigoBox = document.getElementById('codigoBox').value.trim();
  if (codigoBox) {
    // Agregar parámetro de código box a la URL
    var pasillo = document.getElementById('pasillo').value;
    var jornada = document.getElementById('jornada').value;
    var fecha = document.getElementById('fecha').value;
    var nombreMedico = document.getElementById('nombreMedico') ? document.getElementById('nombreMedico').value : '';

    var params = [];
    if (pasillo) params.push('pasillo=' + encodeURIComponent(pasillo));
    if (jornada) params.push('jornada=' + encodeURIComponent(jornada));
    if (fecha) params.push('fecha=' + encodeURIComponent(fecha));
    if (nombreMedico) params.push('medico=' + encodeURIComponent(nombreMedico));
    if (codigoBox) params.push('box=' + encodeURIComponent(codigoBox));

    var queryString = params.length ? ('?' + params.join('&')) : '';
    window.location.href = window.location.pathname + queryString;
  }
};

// Función para limpiar todos los filtros
window.limpiarTodosFiltrosPasillo = function() {
  // Mantener solo la fecha actual
  const fecha = document.getElementById('fecha').value;
  var queryString = fecha ? ('?fecha=' + encodeURIComponent(fecha)) : '';
  window.location.href = window.location.pathname + queryString;
};

// Función para limpiar búsqueda de médico
window.limpiarBusquedaMedicoPasillo = function() {
  document.getElementById('nombreMedico').value = '';
  aplicarFiltrosPasillo();
};

// Función para limpiar búsqueda de box
window.limpiarBusquedaBoxPasillo = function() {
  document.getElementById('codigoBox').value = '';
  aplicarFiltrosPasillo();
};

// Función para remover un filtro específico
window.removerFiltroPasillo = function(tipo) {
  switch(tipo) {
    case 'pasillo':
      document.getElementById('pasillo').value = '';
      break;
    case 'medico':
      document.getElementById('nombreMedico').value = '';
      break;
    case 'box':
      document.getElementById('codigoBox').value = '';
      break;
  }
  aplicarFiltrosPasillo();
};
