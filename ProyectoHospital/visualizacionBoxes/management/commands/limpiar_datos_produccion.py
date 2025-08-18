from django.core.management.base import BaseCommand
from django.contrib.auth.models import Group
from django.db import transaction
from visualizacionBoxes.models import Tipoagenda


class Command(BaseCommand):
    help = 'Limpia todos los datos de producción para cargar datos limpios'

    def handle(self, *args, **options):
        self.stdout.write('Iniciando limpieza de datos de producción...')
        
        try:
            with transaction.atomic():
                # Primero eliminar todas las agendas que referencian tipos de agenda
                from visualizacionBoxes.models import Agenda
                agendas_count = Agenda.objects.count()
                if agendas_count > 0:
                    self.stdout.write(f'Eliminando {agendas_count} registros de agenda...')
                    Agenda.objects.all().delete()
                    self.stdout.write(self.style.SUCCESS('✓ Agendas eliminadas'))
                
                # Luego eliminar los tipos de agenda
                tipos_count = Tipoagenda.objects.count()
                if tipos_count > 0:
                    self.stdout.write(f'Eliminando {tipos_count} tipos de agenda...')
                    Tipoagenda.objects.all().delete()
                    self.stdout.write(self.style.SUCCESS('✓ Tipos de agenda eliminados'))
                
                # Finalmente eliminar los grupos de usuario
                # Primero verificar si hay usuarios asignados a estos grupos
                from django.contrib.auth.models import User
                for group in Group.objects.all():
                    users_in_group = group.user_set.count()
                    if users_in_group > 0:
                        self.stdout.write(f'Removiendo {users_in_group} usuarios del grupo "{group.name}"...')
                        group.user_set.clear()
                
                grupos_count = Group.objects.count()
                if grupos_count > 0:
                    self.stdout.write(f'Eliminando {grupos_count} grupos de usuario...')
                    Group.objects.all().delete()
                    self.stdout.write(self.style.SUCCESS('✓ Grupos de usuario eliminados'))
                
                self.stdout.write(self.style.SUCCESS('🎉 Limpieza de datos completada exitosamente'))
                self.stdout.write('Ahora puedes cargar los datos limpios con: python manage.py loaddata initial_data.json')
                
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'Error durante la limpieza: {str(e)}')
            )
            raise
