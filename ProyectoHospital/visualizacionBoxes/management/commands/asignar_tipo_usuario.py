from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from visualizacionBoxes.models import TipoUsuario, PerfilUsuario, Pasillo


class Command(BaseCommand):
    help = 'Asigna tipos de usuario a usuarios existentes y crea perfiles faltantes'

    def add_arguments(self, parser):
        parser.add_argument(
            '--usuario',
            type=str,
            help='Username del usuario específico (opcional)'
        )
        parser.add_argument(
            '--email',
            type=str,
            help='Email del usuario específico (opcional)'
        )
        parser.add_argument(
            '--tipo',
            type=str,
            help='Tipo de usuario a asignar: Administrador, Personal Médico, Personal Administrativo, Visitante'
        )
        parser.add_argument(
            '--pasillo',
            type=int,
            help='ID del pasillo para Personal Médico (opcional)'
        )
        parser.add_argument(
            '--listar-usuarios',
            action='store_true',
            help='Lista todos los usuarios existentes'
        )
        parser.add_argument(
            '--listar-tipos',
            action='store_true',
            help='Lista todos los tipos de usuario disponibles'
        )
        parser.add_argument(
            '--crear-perfiles-faltantes',
            action='store_true',
            help='Crea perfiles como Visitante para usuarios sin perfil'
        )

    def handle(self, *args, **options):
        # Listar tipos de usuario disponibles
        if options['listar_tipos']:
            self.stdout.write('📋 TIPOS DE USUARIO DISPONIBLES:')
            for tipo in TipoUsuario.objects.all():
                self.stdout.write(f'  - {tipo.nombre}: {tipo.descripcion}')
            return

        # Listar usuarios existentes
        if options['listar_usuarios']:
            self.stdout.write('👥 USUARIOS EXISTENTES:')
            for user in User.objects.all():
                try:
                    perfil = user.perfilusuario
                    tipo_info = f"Tipo: {perfil.tipo_usuario.nombre}"
                    if perfil.pasillo_asignado:
                        tipo_info += f" (Pasillo: {perfil.pasillo_asignado.pasillo})"
                except PerfilUsuario.DoesNotExist:
                    tipo_info = "❌ SIN PERFIL"
                
                self.stdout.write(f'  - {user.username} ({user.email}) - {tipo_info}')
            return

        # Crear perfiles faltantes
        if options['crear_perfiles_faltantes']:
            tipo_visitante = TipoUsuario.objects.get(nombre='Visitante')
            usuarios_sin_perfil = []
            
            for user in User.objects.all():
                if not hasattr(user, 'perfilusuario'):
                    PerfilUsuario.objects.create(
                        usuario=user,
                        tipo_usuario=tipo_visitante,
                        activo=True
                    )
                    usuarios_sin_perfil.append(user.username)
            
            if usuarios_sin_perfil:
                self.stdout.write(
                    self.style.SUCCESS(f'✅ Perfiles creados para: {", ".join(usuarios_sin_perfil)}')
                )
            else:
                self.stdout.write('ℹ️  Todos los usuarios ya tienen perfil')
            return

        # Validar que se proporcione tipo de usuario
        if not options['tipo']:
            self.stdout.write(
                self.style.ERROR('❌ Debes especificar --tipo. Usa --listar-tipos para ver opciones.')
            )
            return

        # Validar tipo de usuario
        try:
            tipo_usuario = TipoUsuario.objects.get(nombre=options['tipo'])
        except TipoUsuario.DoesNotExist:
            self.stdout.write(
                self.style.ERROR(f'❌ Tipo de usuario "{options["tipo"]}" no existe. Usa --listar-tipos para ver opciones.')
            )
            return

        # Obtener usuario específico
        usuario = None
        if options['usuario']:
            try:
                usuario = User.objects.get(username=options['usuario'])
            except User.DoesNotExist:
                self.stdout.write(
                    self.style.ERROR(f'❌ Usuario "{options["usuario"]}" no existe.')
                )
                return
        elif options['email']:
            try:
                usuario = User.objects.get(email=options['email'])
            except User.DoesNotExist:
                self.stdout.write(
                    self.style.ERROR(f'❌ Usuario con email "{options["email"]}" no existe.')
                )
                return
        else:
            self.stdout.write(
                self.style.ERROR('❌ Debes especificar --usuario o --email')
            )
            return

        # Obtener pasillo si se especifica
        pasillo = None
        if options['pasillo']:
            try:
                pasillo = Pasillo.objects.get(idpasillo=options['pasillo'])
            except Pasillo.DoesNotExist:
                self.stdout.write(
                    self.style.ERROR(f'❌ Pasillo con ID {options["pasillo"]} no existe.')
                )
                return

        # Crear o actualizar perfil
        perfil, created = PerfilUsuario.objects.get_or_create(
            usuario=usuario,
            defaults={
                'tipo_usuario': tipo_usuario,
                'activo': True,
                'pasillo_asignado': pasillo
            }
        )

        if not created:
            # Actualizar perfil existente
            perfil.tipo_usuario = tipo_usuario
            if pasillo:
                perfil.pasillo_asignado = pasillo
            perfil.save()

        accion = "creado" if created else "actualizado"
        pasillo_info = f" (Pasillo: {pasillo.pasillo})" if pasillo else ""
        
        self.stdout.write(
            self.style.SUCCESS(
                f'✅ Perfil {accion} para {usuario.username}: {tipo_usuario.nombre}{pasillo_info}'
            )
        )

        # Mostrar resumen de permisos
        self.stdout.write('\n📋 PERMISOS ASIGNADOS:')
        if tipo_usuario.nombre == 'Administrador':
            self.stdout.write('   ✅ Acceso completo al sistema')
            self.stdout.write('   ✅ Gestionar usuarios')
            self.stdout.write('   ✅ Configurar sistema')
            self.stdout.write('   ✅ Ver todos los pasillos')
        elif tipo_usuario.nombre == 'Personal Administrativo':
            self.stdout.write('   ✅ Ver todos los pasillos')
            self.stdout.write('   ✅ Administrar agendas')
            self.stdout.write('   ✅ Generar reportes')
            self.stdout.write('   ❌ Gestionar usuarios')
        elif tipo_usuario.nombre == 'Personal Médico':
            self.stdout.write('   ✅ Ver su pasillo asignado')
            self.stdout.write('   ✅ Generar reportes de su pasillo')
            self.stdout.write('   ✅ Consultar agendas')
            self.stdout.write('   ❌ Administrar agendas')
            if not pasillo:
                self.stdout.write(
                    self.style.WARNING('   ⚠️  RECORDATORIO: Asigna un pasillo para que funcione correctamente')
                )
        elif tipo_usuario.nombre == 'Visitante':
            self.stdout.write('   ✅ Visualización básica')
            self.stdout.write('   ❌ Funcionalidades limitadas')
