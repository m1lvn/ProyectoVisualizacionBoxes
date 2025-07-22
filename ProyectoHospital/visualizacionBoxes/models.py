"""
Modelos para la aplicación de visualización de boxes del hospital.

Este módulo contiene los modelos de Django que representan las entidades
principales del sistema hospitalario: boxes, agendas, profesionales, etc.
"""

from django.db import models


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
