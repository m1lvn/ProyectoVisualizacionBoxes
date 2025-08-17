"""
Modelos para la aplicación de visualización de boxes del hospital.

Este módulo contiene los modelos de Django que representan las entidades
principales del sistema hospitalario: boxes, agendas, profesionales, etc.
"""

from django.db import models
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError


class Pasillo(models.Model):
    """
    Modelo que representa un pasillo del hospital.
    
    Los pasillos son ubicaciones físicas donde se encuentran los boxes.
    """
    idpasillo = models.AutoField(db_column='idPasillo', primary_key=True)
    pasillo = models.CharField(max_length=100, help_text="Nombre del pasillo")

    class Meta:
        managed = False
        db_table = 'pasillo'
        verbose_name = "Pasillo"
        verbose_name_plural = "Pasillos"

    def __str__(self):
        return self.pasillo


class Especialidad(models.Model):
    """
    Modelo que representa una especialidad médica.
    
    Las especialidades son las diferentes áreas médicas que pueden
    atender los profesionales de la salud.
    """
    idespecialidad = models.AutoField(db_column='idEspecialidad', primary_key=True)
    especialidad = models.CharField(max_length=100, help_text="Nombre de la especialidad")

    class Meta:
        managed = False
        db_table = 'especialidad'
        verbose_name = "Especialidad"
        verbose_name_plural = "Especialidades"

    def __str__(self):
        return self.especialidad


class Profesional(models.Model):
    """
    Modelo que representa un profesional de la salud.
    
    Cada profesional tiene una especialidad asignada y puede tener
    agendas programadas en diferentes boxes.
    """
    idprofesional = models.AutoField(db_column='idProfesional', primary_key=True)
    idespecialidad = models.ForeignKey(
        Especialidad, 
        models.DO_NOTHING, 
        db_column='idEspecialidad',
        help_text="Especialidad del profesional"
    )
    nombre = models.CharField(max_length=100, help_text="Nombre completo del profesional")

    class Meta:
        managed = False
        db_table = 'profesional'
        verbose_name = "Profesional"
        verbose_name_plural = "Profesionales"

    def __str__(self):
        return f"{self.nombre} - {self.idespecialidad.especialidad}"


class Tipoagenda(models.Model):
    """
    Modelo que representa los diferentes tipos de agenda.
    
    Los tipos de agenda definen el propósito de la reserva del box
    (consulta, cirugía, urgencia, etc.) y determinan el color de
    visualización en la interfaz.
    """
    idtipoagenda = models.AutoField(db_column='idTipoAgenda', primary_key=True)
    tipoagenda = models.CharField(
        db_column='tipoAgenda', 
        max_length=100,
        help_text="Tipo de agenda (ej: Consulta, Cirugía, Urgencia)"
    )

    class Meta:
        managed = False
        db_table = 'tipoagenda'
        verbose_name = "Tipo de Agenda"
        verbose_name_plural = "Tipos de Agenda"

    def __str__(self):
        return self.tipoagenda


class Box(models.Model):
    """
    Modelo que representa un box del hospital.
    
    Los boxes son espacios físicos donde se realizan atenciones médicas.
    Cada box pertenece a un pasillo específico y tiene una capacidad definida.
    """
    idbox = models.AutoField(db_column='idBox', primary_key=True)
    idpasillo = models.ForeignKey(
        Pasillo, 
        models.DO_NOTHING, 
        db_column='idPasillo',
        help_text="Pasillo donde se ubica el box"
    )
    capacidad = models.IntegerField(
        blank=True, 
        null=True,
        help_text="Capacidad máxima del box"
    )

    class Meta:
        managed = False
        db_table = 'box'
        verbose_name = "Box"
        verbose_name_plural = "Boxes"

    def __str__(self):
        return f"Box {self.idbox} - {self.idpasillo.pasillo}"

    @property
    def codigobox(self):
        """
        Devuelve el código del box formateado.
        
        Returns:
            str: Código del box (ej: "BOX-001")
        """
        return f"BOX-{self.idbox:03d}"

    @property
    def esta_disponible_ahora(self):
        """
        Verifica si el box está disponible en el momento actual.
        
        Returns:
            bool: True si está disponible, False si está ocupado
        """
        from datetime import datetime
        
        now = datetime.now()
        agenda_activa = self.agenda_set.filter(
            fecha=now.date(),
            horainicio__lte=now.time(),
            horafin__gt=now.time()
        ).exists()
        
        return not agenda_activa


class Agenda(models.Model):
    """
    Modelo que representa una agenda programada en un box.
    
    Las agendas definen cuándo un box estará ocupado por un profesional
    específico para realizar actividades de un tipo determinado.
    """
    idagenda = models.AutoField(db_column='idAgenda', primary_key=True)
    idtipoagenda = models.ForeignKey(
        Tipoagenda, 
        models.DO_NOTHING, 
        db_column='idTipoAgenda',
        help_text="Tipo de agenda programada"
    )
    idprofesional = models.ForeignKey(
        Profesional, 
        models.DO_NOTHING, 
        db_column='idProfesional',
        help_text="Profesional asignado"
    )
    idbox = models.ForeignKey(
        Box, 
        models.DO_NOTHING, 
        db_column='idBox',
        help_text="Box reservado"
    )
    fecha = models.DateField(help_text="Fecha de la agenda")
    horainicio = models.TimeField(
        db_column='horaInicio',
        help_text="Hora de inicio de la agenda"
    )
    horafin = models.TimeField(
        db_column='horaFin',
        help_text="Hora de fin de la agenda"
    )

    class Meta:
        managed = False
        db_table = 'agenda'
        verbose_name = "Agenda"
        verbose_name_plural = "Agendas"

    def __str__(self):
        return (f"Agenda {self.idagenda} - Box {self.idbox.idbox} - "
                f"{self.fecha} {self.horainicio}-{self.horafin}")

    @property
    def duracion_horas(self):
        """
        Calcula la duración de la agenda en horas.
        
        Returns:
            float: Duración en horas
        """
        from datetime import datetime, timedelta
        
        inicio = datetime.combine(self.fecha, self.horainicio)
        fin = datetime.combine(self.fecha, self.horafin)
        duracion = fin - inicio
        
        return duracion.total_seconds() / 3600

    def esta_activa_ahora(self):
        """
        Verifica si esta agenda está activa en el momento actual.
        
        Returns:
            bool: True si está activa, False en caso contrario
        """
        from datetime import datetime
        
        now = datetime.now()
        return (self.fecha == now.date() and 
                self.horainicio <= now.time() < self.horafin)

    def clean(self):
        """
        Validación personalizada para el modelo Agenda - SIN RESTRICCIONES DE HORARIO.
        Permite horarios 24/7.
        """
        from django.core.exceptions import ValidationError
        
        if self.horainicio and self.horafin:
            # Solo validar que hora inicio sea menor que hora fin
            if self.horainicio >= self.horafin:
                raise ValidationError({
                    'horafin': 'La hora de fin debe ser posterior a la hora de inicio.'
                })
        
        # Validar que no haya solapamiento con otras agendas del mismo box y fecha
        if self.idbox and self.fecha:
            agendas_solapadas = Agenda.objects.filter(
                idbox=self.idbox,
                fecha=self.fecha,
                horainicio__lt=self.horafin,
                horafin__gt=self.horainicio
            ).exclude(pk=self.pk)
            
            if agendas_solapadas.exists():
                raise ValidationError(
                    'Ya existe una agenda que se solapa con este horario para el mismo box.'
                )


class TipoUsuario(models.Model):
    """
    Modelo que representa los diferentes tipos de usuarios del sistema.
    
    Define los roles y permisos que pueden tener los usuarios:
    - Administrador: Acceso completo
    - Personal Médico: Acceso a funciones médicas
    - Personal Administrativo: Acceso a funciones administrativas
    - Visitante: Acceso limitado de solo lectura
    """
    nombre = models.CharField(
        max_length=50,
        unique=True,
        help_text="Nombre del tipo de usuario"
    )
    descripcion = models.TextField(
        blank=True,
        help_text="Descripción detallada del tipo de usuario"
    )
    activo = models.BooleanField(
        default=True,
        help_text="Indica si este tipo de usuario está activo"
    )
    fecha_creacion = models.DateTimeField(
        auto_now_add=True,
        help_text="Fecha de creación del tipo de usuario"
    )
    fecha_modificacion = models.DateTimeField(
        auto_now=True,
        help_text="Fecha de última modificación"
    )

    class Meta:
        db_table = 'tipo_usuario'
        verbose_name = "Tipo de Usuario"
        verbose_name_plural = "Tipos de Usuario"
        ordering = ['nombre']

    def __str__(self):
        return self.nombre


class PerfilUsuario(models.Model):
    """
    Modelo que extiende el modelo User de Django con información específica del hospital.
    
    Conecta a los usuarios con tipos de usuario y agrega información adicional
    necesaria para el sistema hospitalario.
    """
    usuario = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        help_text="Usuario de Django asociado"
    )
    tipo_usuario = models.ForeignKey(
        TipoUsuario,
        on_delete=models.PROTECT,
        help_text="Tipo de usuario que define sus permisos"
    )
    activo = models.BooleanField(
        default=True,
        help_text="Indica si el perfil de usuario está activo"
    )
    telefono = models.CharField(
        max_length=20,
        blank=True,
        help_text="Número de teléfono del usuario"
    )
    pasillo_asignado = models.ForeignKey(
        Pasillo,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        help_text="Pasillo asignado (solo para Personal Médico)"
    )
    fecha_creacion = models.DateTimeField(
        auto_now_add=True,
        help_text="Fecha de creación del perfil"
    )
    fecha_modificacion = models.DateTimeField(
        auto_now=True,
        help_text="Fecha de última modificación del perfil"
    )
    ultimo_acceso = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Fecha y hora del último acceso del usuario"
    )

    class Meta:
        db_table = 'perfil_usuario'
        verbose_name = "Perfil de Usuario"
        verbose_name_plural = "Perfiles de Usuario"
        ordering = ['usuario__first_name', 'usuario__last_name']

    def __str__(self):
        return f"{self.usuario.get_full_name() or self.usuario.username} ({self.tipo_usuario.nombre})"

    @property
    def nombre_completo(self):
        """Retorna el nombre completo del usuario."""
        return self.usuario.get_full_name() or self.usuario.username

    @property
    def es_administrador(self):
        """Verifica si el usuario es administrador."""
        return self.tipo_usuario.nombre.lower() == 'administrador'

    @property
    def es_personal_medico(self):
        """Verifica si el usuario es personal médico."""
        return self.tipo_usuario.nombre.lower() == 'personal medico'

    @property
    def es_personal_administrativo(self):
        """Verifica si el usuario es personal administrativo."""
        return self.tipo_usuario.nombre.lower() == 'personal administrativo'

    def tiene_permiso_lectura(self):
        """Verifica si el usuario tiene permisos de lectura."""
        return self.activo and self.tipo_usuario.activo

    # ============== NUEVOS MÉTODOS DE PERMISOS ESPECÍFICOS ==============
    
    def puede_ver_pasillo(self, pasillo_id):
        """Verificar si el usuario puede ver un pasillo específico"""
        if not self.tipo_usuario or not self.activo:
            return False
            
        tipo = self.tipo_usuario.nombre.lower()
        
        # Administrador puede ver todo
        if tipo == 'administrador':
            return True
            
        # Personal administrativo puede ver todo
        if tipo == 'personal administrativo':
            return True
            
        # Personal médico solo puede ver su pasillo asignado
        if tipo == 'personal medico':
            if not self.pasillo_asignado:
                return False
            return str(self.pasillo_asignado.idpasillo) == str(pasillo_id)
            
        return False
    
    def puede_administrar_agendas(self):
        """Verificar si puede administrar agendas"""
        if not self.tipo_usuario or not self.activo:
            return False
        tipo = self.tipo_usuario.nombre.lower()
        return tipo in ['administrador', 'personal administrativo']
    
    def puede_generar_reportes(self):
        """Verificar si puede generar reportes"""
        if not self.tipo_usuario or not self.activo:
            return False
        tipo = self.tipo_usuario.nombre.lower()
        return tipo in ['administrador', 'personal administrativo', 'personal medico']
    
    def puede_gestionar_usuarios(self):
        """Verificar si puede gestionar usuarios"""
        if not self.tipo_usuario or not self.activo:
            return False
        return self.tipo_usuario.nombre.lower() == 'administrador'
    
    def puede_configurar_sistema(self):
        """Verificar si puede configurar el sistema"""
        if not self.tipo_usuario or not self.activo:
            return False
        return self.tipo_usuario.nombre.lower() == 'administrador'
    
    def puede_ver_todos_pasillos(self):
        """Verificar si puede ver todos los pasillos"""
        if not self.tipo_usuario or not self.activo:
            return False
        tipo = self.tipo_usuario.nombre.lower()
        return tipo in ['administrador', 'personal administrativo']
    
    def get_pasillos_permitidos(self):
        """Obtener lista de pasillos que puede ver"""
        if self.puede_ver_todos_pasillos():
            return Pasillo.objects.all()
        elif self.es_personal_medico and self.pasillo_asignado:
            return Pasillo.objects.filter(idpasillo=self.pasillo_asignado.idpasillo)
        else:
            return Pasillo.objects.none()
    
    def puede_ver_visualizacion_general(self):
        """Verificar si puede acceder a visualización general"""
        return self.tiene_permiso_lectura()
    
    def puede_ver_visualizacion_pasillos(self):
        """Verificar si puede acceder a visualización de pasillos"""
        return self.tiene_permiso_lectura()
    
    def get_pasillos_filtro(self):
        """Obtener filtro de pasillos para queries"""
        if self.puede_ver_todos_pasillos():
            return {}  # Sin filtro, puede ver todo
        elif self.es_personal_medico and self.pasillo_asignado:
            return {'idpasillo': self.pasillo_asignado}
        else:
            return {'idpasillo__isnull': True}  # No puede ver nada
