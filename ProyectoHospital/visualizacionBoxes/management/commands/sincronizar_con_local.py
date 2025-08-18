from django.core.management.base import BaseCommand
from django.db import transaction
from visualizacionBoxes.models import Tipoagenda, TipoUsuario


class Command(BaseCommand):
    help = 'Limpia todos los datos de producción para cargar datos reales de local'

    def handle(self, *args, **options):
        self.stdout.write('Iniciando limpieza de datos de producción para sincronizar con local...')
        
        try:
            with transaction.atomic():
                # Primero eliminar todas las agendas que referencian tipos de agenda
                from visualizacionBoxes.models import Agenda
                agendas_count = Agenda.objects.count()
                if agendas_count > 0:
                    self.stdout.write(f'Eliminando {agendas_count} registros de agenda...')
                    Agenda.objects.all().delete()
                    self.stdout.write(self.style.SUCCESS('✓ Agendas eliminadas'))
                
                # Eliminar los perfiles de usuario que referencian tipos de usuario
                try:
                    from visualizacionBoxes.models import PerfilUsuario
                    perfiles_count = PerfilUsuario.objects.count()
                    if perfiles_count > 0:
                        self.stdout.write(f'Eliminando {perfiles_count} perfiles de usuario...')
                        PerfilUsuario.objects.all().delete()
                        self.stdout.write(self.style.SUCCESS('✓ Perfiles de usuario eliminados'))
                except ImportError:
                    self.stdout.write('ℹ️  Modelo PerfilUsuario no encontrado, saltando...')
                
                # Eliminar los tipos de agenda
                tipos_count = Tipoagenda.objects.count()
                if tipos_count > 0:
                    self.stdout.write(f'Eliminando {tipos_count} tipos de agenda...')
                    Tipoagenda.objects.all().delete()
                    self.stdout.write(self.style.SUCCESS('✓ Tipos de agenda eliminados'))
                
                # Eliminar los tipos de usuario (si existen)
                try:
                    tipos_usuario_count = TipoUsuario.objects.count()
                    if tipos_usuario_count > 0:
                        self.stdout.write(f'Eliminando {tipos_usuario_count} tipos de usuario...')
                        TipoUsuario.objects.all().delete()
                        self.stdout.write(self.style.SUCCESS('✓ Tipos de usuario eliminados'))
                except:
                    self.stdout.write('ℹ️  Modelo TipoUsuario no encontrado, saltando...')
                
                # Eliminar grupos de Django (por si quedaron del fixture anterior)
                try:
                    from django.contrib.auth.models import Group
                    grupos_count = Group.objects.count()
                    if grupos_count > 0:
                        self.stdout.write(f'Eliminando {grupos_count} grupos de Django...')
                        for group in Group.objects.all():
                            group.user_set.clear()
                        Group.objects.all().delete()
                        self.stdout.write(self.style.SUCCESS('✓ Grupos de Django eliminados'))
                except:
                    pass
                
                self.stdout.write(self.style.SUCCESS('🎉 Limpieza de datos completada exitosamente'))
                self.stdout.write('📋 Próximos pasos:')
                self.stdout.write('   1. python manage.py loaddata datos_reales_locales.json')
                self.stdout.write('   2. Verificar en el admin que aparezcan los tipos de usuario correctos')
                
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'Error durante la limpieza: {str(e)}')
            )
            raise
