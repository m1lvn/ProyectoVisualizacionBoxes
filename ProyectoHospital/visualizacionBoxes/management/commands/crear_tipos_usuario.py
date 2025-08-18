from django.core.management.base import BaseCommand
from visualizacionBoxes.models import TipoUsuario


class Command(BaseCommand):
    help = 'Crea los tipos de usuario según la nueva especificación del sistema'

    def handle(self, *args, **options):
        """Crea los tipos de usuario según la especificación actualizada."""
        
        # No eliminar, sino actualizar los existentes
        self.stdout.write('Actualizando tipos de usuario...')
        
        tipos_usuario = [
            {
                'nombre': 'Administrador',
                'descripcion': 'Acceso completo al sistema. Puede gestionar usuarios, configurar sistema, ver todos los pasillos, administrar agendas y generar reportes de todos los datos.',
            },
            {
                'nombre': 'Personal Administrativo', 
                'descripcion': 'Acceso administrativo completo. Puede ver todos los pasillos, administrar todas las agendas y generar reportes de todos los datos. No puede gestionar usuarios ni configurar sistema.',
            },
            {
                'nombre': 'Personal Médico',
                'descripcion': 'Acceso médico limitado a su pasillo asignado. Puede ver visualizaciones y generar reportes solo de su pasillo. Puede consultar agendas pero no administrarlas.',
            },
            {
                'nombre': 'Visitante',
                'descripcion': 'Acceso de solo lectura limitado. Puede ver visualizaciones generales sin datos sensibles. Sin acceso a agendas, reportes detallados o funciones administrativas.',
            },
        ]

        for tipo_data in tipos_usuario:
            tipo, created = TipoUsuario.objects.update_or_create(
                nombre=tipo_data['nombre'],
                defaults={
                    'descripcion': tipo_data['descripcion'],
                    'activo': True
                }
            )
            
            if created:
                self.stdout.write(
                    self.style.SUCCESS(f'✅ Tipo de usuario "{tipo.nombre}" creado exitosamente.')
                )
            else:
                self.stdout.write(
                    self.style.SUCCESS(f'🔄 Tipo de usuario "{tipo.nombre}" actualizado exitosamente.')
                )

        self.stdout.write('\n' + '='*60)
        self.stdout.write(self.style.SUCCESS('🎉 CONFIGURACIÓN COMPLETADA'))
        self.stdout.write('='*60)
        self.stdout.write('\n📋 PERMISOS POR TIPO DE USUARIO:')
        self.stdout.write('')
        self.stdout.write('👑 ADMINISTRADOR:')
        self.stdout.write('   ✅ Visualización General (todos los pasillos)')
        self.stdout.write('   ✅ Visualización Pasillos (todos)')
        self.stdout.write('   ✅ Generar Reportes (todos los datos)')
        self.stdout.write('   ✅ Administrar Agendas (todas)')
        self.stdout.write('   ✅ Gestionar Usuarios')
        self.stdout.write('   ✅ Configuración Sistema')
        self.stdout.write('')
        self.stdout.write('👨‍💼 PERSONAL ADMINISTRATIVO:')
        self.stdout.write('   ✅ Visualización General (todos los pasillos)')
        self.stdout.write('   ✅ Visualización Pasillos (todos)')
        self.stdout.write('   ✅ Generar Reportes (todos los datos)')
        self.stdout.write('   ✅ Administrar Agendas (todas)')
        self.stdout.write('   ❌ Gestionar Usuarios')
        self.stdout.write('   ❌ Configuración Sistema')
        self.stdout.write('')
        self.stdout.write('👨‍⚕️ PERSONAL MÉDICO:')
        self.stdout.write('   ✅ Visualización General (solo su pasillo)')
        self.stdout.write('   ✅ Visualización Pasillos (solo el suyo)')
        self.stdout.write('   ✅ Generar Reportes (solo su pasillo)')
        self.stdout.write('   ❌ Administrar Agendas (solo consultar)')
        self.stdout.write('   ❌ Gestionar Usuarios')
        self.stdout.write('   ❌ Configuración Sistema')
        self.stdout.write('')
        self.stdout.write('� VISITANTE:')
        self.stdout.write('   ✅ Visualización General (limitada)')
        self.stdout.write('   ❌ Visualización Pasillos')
        self.stdout.write('   ❌ Generar Reportes')
        self.stdout.write('   ❌ Administrar Agendas')
        self.stdout.write('   ❌ Gestionar Usuarios')
        self.stdout.write('   ❌ Configuración Sistema')
        self.stdout.write('')
        self.stdout.write('�💡 RECORDATORIO: Para Personal Médico, no olvides asignar un pasillo en el admin.')
        self.stdout.write('='*60)
