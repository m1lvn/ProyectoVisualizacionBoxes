from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from visualizacionBoxes.models import TipoUsuario, PerfilUsuario, Pasillo
from django.core.exceptions import ValidationError
from django.db import transaction


class Command(BaseCommand):
    help = 'Crear un usuario con perfil del hospital completo'

    def add_arguments(self, parser):
        parser.add_argument('--username', type=str, help='Nombre de usuario')
        parser.add_argument('--email', type=str, help='Email del usuario')
        parser.add_argument('--first_name', type=str, help='Nombre')
        parser.add_argument('--last_name', type=str, help='Apellido')
        parser.add_argument('--password', type=str, help='Contraseña')
        parser.add_argument('--tipo', type=str, help='Tipo de usuario (nombre)')
        parser.add_argument('--pasillo', type=str, help='Pasillo asignado (opcional)')
        parser.add_argument('--telefono', type=str, help='Teléfono (opcional)')
        parser.add_argument('--staff', action='store_true', help='Hacer usuario staff')
        parser.add_argument('--superuser', action='store_true', help='Hacer usuario superuser')

    def handle(self, *args, **options):
        # Si no se proporcionan argumentos, modo interactivo
        if not options.get('username'):
            return self.crear_usuario_interactivo()
        
        # Modo con argumentos
        return self.crear_usuario_argumentos(options)

    def crear_usuario_interactivo(self):
        """Crear usuario en modo interactivo."""
        self.stdout.write(self.style.SUCCESS('=== CREAR USUARIO DEL HOSPITAL ===\n'))
        
        # Datos básicos del usuario
        username = input('Nombre de usuario: ').strip()
        if not username:
            self.stdout.write(self.style.ERROR('El nombre de usuario es obligatorio'))
            return
        
        # Verificar si ya existe
        if User.objects.filter(username=username).exists():
            self.stdout.write(self.style.ERROR(f'Ya existe un usuario con el nombre "{username}"'))
            return
        
        email = input('Email: ').strip()
        first_name = input('Nombre: ').strip()
        last_name = input('Apellido: ').strip()
        password = input('Contraseña: ').strip()
        
        if not password:
            self.stdout.write(self.style.ERROR('La contraseña es obligatoria'))
            return
        
        # Mostrar tipos de usuario disponibles
        tipos = TipoUsuario.objects.all()
        self.stdout.write('\nTipos de usuario disponibles:')
        for i, tipo in enumerate(tipos, 1):
            self.stdout.write(f'{i}. {tipo.nombre} - {tipo.descripcion}')
        
        tipo_seleccionado = None
        while not tipo_seleccionado:
            try:
                opcion = int(input('\nSeleccione el número del tipo de usuario: '))
                if 1 <= opcion <= len(tipos):
                    tipo_seleccionado = tipos[opcion - 1]
                else:
                    self.stdout.write(self.style.ERROR('Opción inválida'))
            except ValueError:
                self.stdout.write(self.style.ERROR('Debe ingresar un número'))
        
        # Pasillo (opcional)
        pasillo_seleccionado = None
        pasillos = Pasillo.objects.all()
        if pasillos.exists():
            self.stdout.write('\nPasillos disponibles:')
            self.stdout.write('0. Sin asignar')
            for i, pasillo in enumerate(pasillos, 1):
                self.stdout.write(f'{i}. {pasillo.nombre}')
            
            try:
                opcion_pasillo = int(input('Seleccione el número del pasillo (0 para ninguno): '))
                if 1 <= opcion_pasillo <= len(pasillos):
                    pasillo_seleccionado = pasillos[opcion_pasillo - 1]
            except ValueError:
                pass
        
        # Teléfono (opcional)
        telefono = input('Teléfono (opcional): ').strip()
        
        # Permisos
        is_staff = input('¿Usuario staff? (y/N): ').lower().startswith('y')
        is_superuser = input('¿Usuario superuser? (y/N): ').lower().startswith('y')
        
        # Crear usuario
        try:
            with transaction.atomic():
                usuario = User.objects.create_user(
                    username=username,
                    email=email,
                    first_name=first_name,
                    last_name=last_name,
                    password=password,
                    is_staff=is_staff,
                    is_superuser=is_superuser
                )
                
                perfil = PerfilUsuario.objects.create(
                    usuario=usuario,
                    tipo_usuario=tipo_seleccionado,
                    pasillo_asignado=pasillo_seleccionado,
                    telefono=telefono,
                    activo=True
                )
                
                self.stdout.write(
                    self.style.SUCCESS(
                        f'\n✓ Usuario "{username}" creado exitosamente:\n'
                        f'  - Nombre: {first_name} {last_name}\n'
                        f'  - Email: {email}\n'
                        f'  - Tipo: {tipo_seleccionado.nombre}\n'
                        f'  - Pasillo: {pasillo_seleccionado.nombre if pasillo_seleccionado else "Sin asignar"}\n'
                        f'  - Staff: {"Sí" if is_staff else "No"}\n'
                        f'  - Superuser: {"Sí" if is_superuser else "No"}'
                    )
                )
                
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Error al crear usuario: {str(e)}'))

    def crear_usuario_argumentos(self, options):
        """Crear usuario con argumentos de línea de comandos."""
        try:
            # Verificar tipo de usuario
            tipo_usuario = TipoUsuario.objects.get(nombre=options['tipo'])
        except TipoUsuario.DoesNotExist:
            self.stdout.write(self.style.ERROR(f'Tipo de usuario "{options["tipo"]}" no encontrado'))
            tipos = TipoUsuario.objects.all()
            self.stdout.write('Tipos disponibles:')
            for tipo in tipos:
                self.stdout.write(f'  - {tipo.nombre}')
            return
        
        # Verificar pasillo si se especifica
        pasillo = None
        if options.get('pasillo'):
            try:
                pasillo = Pasillo.objects.get(nombre=options['pasillo'])
            except Pasillo.DoesNotExist:
                self.stdout.write(self.style.ERROR(f'Pasillo "{options["pasillo"]}" no encontrado'))
                return
        
        # Crear usuario
        try:
            with transaction.atomic():
                usuario = User.objects.create_user(
                    username=options['username'],
                    email=options.get('email', ''),
                    first_name=options.get('first_name', ''),
                    last_name=options.get('last_name', ''),
                    password=options['password'],
                    is_staff=options.get('staff', False),
                    is_superuser=options.get('superuser', False)
                )
                
                perfil = PerfilUsuario.objects.create(
                    usuario=usuario,
                    tipo_usuario=tipo_usuario,
                    pasillo_asignado=pasillo,
                    telefono=options.get('telefono', ''),
                    activo=True
                )
                
                self.stdout.write(
                    self.style.SUCCESS(f'Usuario "{options["username"]}" creado exitosamente')
                )
                
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Error: {str(e)}'))
