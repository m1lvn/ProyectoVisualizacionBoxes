from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
import uuid


class Command(BaseCommand):
    help = 'Limpia usuarios con username vacío o duplicado'

    def handle(self, *args, **options):
        # Encontrar usuarios con username vacío
        usuarios_vacios = User.objects.filter(username='')
        
        self.stdout.write(f"Encontrados {usuarios_vacios.count()} usuarios con username vacío")
        
        for usuario in usuarios_vacios:
            # Generar un username único basado en email o UUID
            if usuario.email:
                nuevo_username = usuario.email.split('@')[0].lower().replace('.', '').replace('-', '')
            else:
                nuevo_username = f"user_{str(uuid.uuid4())[:8]}"
            
            # Asegurar que sea único
            counter = 1
            original_username = nuevo_username
            while User.objects.filter(username=nuevo_username).exists():
                nuevo_username = f"{original_username}{counter}"
                counter += 1
            
            # Actualizar el usuario
            usuario.username = nuevo_username
            usuario.save()
            
            self.stdout.write(
                self.style.SUCCESS(f"Usuario {usuario.email} actualizado con username: {nuevo_username}")
            )
        
        self.stdout.write(
            self.style.SUCCESS('Limpieza de usuarios completada')
        )
