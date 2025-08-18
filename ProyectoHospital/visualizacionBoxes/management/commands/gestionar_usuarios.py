from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from visualizacionBoxes.models import TipoUsuario, PerfilUsuario


class Command(BaseCommand):
    help = 'Comando interactivo para gestionar usuarios y sus tipos'

    def handle(self, *args, **options):
        self.stdout.write('🏥 GESTIÓN DE USUARIOS DEL HOSPITAL')
        self.stdout.write('=' * 50)
        
        while True:
            self.stdout.write('\n¿Qué deseas hacer?')
            self.stdout.write('1. Ver usuarios existentes')
            self.stdout.write('2. Crear perfil para usuario existente')
            self.stdout.write('3. Cambiar tipo de usuario')
            self.stdout.write('4. Ver tipos de usuario disponibles')
            self.stdout.write('5. Crear perfiles faltantes (todos como Visitante)')
            self.stdout.write('0. Salir')
            
            opcion = input('\nSelecciona una opción (0-5): ')
            
            if opcion == '0':
                self.stdout.write('👋 ¡Hasta luego!')
                break
            elif opcion == '1':
                self.mostrar_usuarios()
            elif opcion == '2':
                self.crear_perfil_usuario()
            elif opcion == '3':
                self.cambiar_tipo_usuario()
            elif opcion == '4':
                self.mostrar_tipos_usuario()
            elif opcion == '5':
                self.crear_perfiles_faltantes()
            else:
                self.stdout.write('❌ Opción inválida')

    def mostrar_usuarios(self):
        self.stdout.write('\n👥 USUARIOS EXISTENTES:')
        usuarios = User.objects.all()
        if not usuarios:
            self.stdout.write('No hay usuarios registrados')
            return
            
        for i, user in enumerate(usuarios, 1):
            try:
                perfil = user.perfilusuario
                estado = f"✅ {perfil.tipo_usuario.nombre}"
                if perfil.pasillo_asignado:
                    estado += f" (Pasillo: {perfil.pasillo_asignado.pasillo})"
            except PerfilUsuario.DoesNotExist:
                estado = "❌ SIN PERFIL"
            
            self.stdout.write(f'{i}. {user.username} ({user.email}) - {estado}')

    def mostrar_tipos_usuario(self):
        self.stdout.write('\n📋 TIPOS DE USUARIO DISPONIBLES:')
        tipos = TipoUsuario.objects.all()
        for i, tipo in enumerate(tipos, 1):
            self.stdout.write(f'{i}. {tipo.nombre} - {tipo.descripcion}')

    def crear_perfil_usuario(self):
        self.stdout.write('\n➕ CREAR PERFIL PARA USUARIO')
        
        # Mostrar usuarios sin perfil
        usuarios_sin_perfil = []
        for user in User.objects.all():
            if not hasattr(user, 'perfilusuario'):
                usuarios_sin_perfil.append(user)
        
        if not usuarios_sin_perfil:
            self.stdout.write('✅ Todos los usuarios ya tienen perfil')
            return
        
        self.stdout.write('Usuarios sin perfil:')
        for i, user in enumerate(usuarios_sin_perfil, 1):
            self.stdout.write(f'{i}. {user.username} ({user.email})')
        
        try:
            seleccion = int(input(f'Selecciona usuario (1-{len(usuarios_sin_perfil)}): ')) - 1
            usuario = usuarios_sin_perfil[seleccion]
        except (ValueError, IndexError):
            self.stdout.write('❌ Selección inválida')
            return
        
        # Mostrar tipos disponibles
        self.mostrar_tipos_usuario()
        tipos = list(TipoUsuario.objects.all())
        
        try:
            tipo_seleccion = int(input(f'Selecciona tipo (1-{len(tipos)}): ')) - 1
            tipo_usuario = tipos[tipo_seleccion]
        except (ValueError, IndexError):
            self.stdout.write('❌ Selección inválida')
            return
        
        # Crear perfil
        PerfilUsuario.objects.create(
            usuario=usuario,
            tipo_usuario=tipo_usuario,
            activo=True
        )
        
        self.stdout.write(
            self.style.SUCCESS(f'✅ Perfil creado: {usuario.username} → {tipo_usuario.nombre}')
        )

    def cambiar_tipo_usuario(self):
        self.stdout.write('\n🔄 CAMBIAR TIPO DE USUARIO')
        
        # Mostrar usuarios con perfil
        usuarios_con_perfil = []
        for user in User.objects.all():
            if hasattr(user, 'perfilusuario'):
                usuarios_con_perfil.append(user)
        
        if not usuarios_con_perfil:
            self.stdout.write('❌ No hay usuarios con perfil')
            return
        
        self.stdout.write('Usuarios con perfil:')
        for i, user in enumerate(usuarios_con_perfil, 1):
            perfil = user.perfilusuario
            self.stdout.write(f'{i}. {user.username} - Actual: {perfil.tipo_usuario.nombre}')
        
        try:
            seleccion = int(input(f'Selecciona usuario (1-{len(usuarios_con_perfil)}): ')) - 1
            usuario = usuarios_con_perfil[seleccion]
        except (ValueError, IndexError):
            self.stdout.write('❌ Selección inválida')
            return
        
        # Mostrar tipos disponibles
        self.mostrar_tipos_usuario()
        tipos = list(TipoUsuario.objects.all())
        
        try:
            tipo_seleccion = int(input(f'Selecciona nuevo tipo (1-{len(tipos)}): ')) - 1
            nuevo_tipo = tipos[tipo_seleccion]
        except (ValueError, IndexError):
            self.stdout.write('❌ Selección inválida')
            return
        
        # Actualizar perfil
        perfil = usuario.perfilusuario
        tipo_anterior = perfil.tipo_usuario.nombre
        perfil.tipo_usuario = nuevo_tipo
        perfil.save()
        
        self.stdout.write(
            self.style.SUCCESS(f'✅ Tipo cambiado: {usuario.username} ({tipo_anterior} → {nuevo_tipo.nombre})')
        )

    def crear_perfiles_faltantes(self):
        self.stdout.write('\n➕ CREAR PERFILES FALTANTES')
        
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
                self.style.SUCCESS(f'✅ Perfiles creados como Visitante: {", ".join(usuarios_sin_perfil)}')
            )
        else:
            self.stdout.write('ℹ️  Todos los usuarios ya tienen perfil')
