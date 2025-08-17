from django.core.management.base import BaseCommand
from allauth.socialaccount.models import SocialApp
from django.contrib.sites.models import Site
import json
import os
from django.conf import settings


class Command(BaseCommand):
    help = 'Configura la aplicación social de Google para django-allauth'

    def handle(self, *args, **options):
        """Configura la aplicación social de Google."""
        
        # Obtener o crear el sitio
        site, created = Site.objects.get_or_create(
            pk=settings.SITE_ID,
            defaults={
                'domain': 'localhost:8000',
                'name': 'Hospital Padre Hurtado'
            }
        )
        
        if created:
            self.stdout.write(
                self.style.SUCCESS(f'Sitio "{site.name}" creado exitosamente.')
            )
        else:
            self.stdout.write(
                self.style.WARNING(f'Sitio "{site.name}" ya existe.')
            )
        
        # Cargar credenciales de Google
        google_oauth_file = os.path.join(settings.BASE_DIR.parent, 'clavesGoogle.json')
        
        if not os.path.exists(google_oauth_file):
            self.stdout.write(
                self.style.ERROR(f'No se encontró el archivo de credenciales: {google_oauth_file}')
            )
            return
        
        with open(google_oauth_file, 'r') as f:
            google_credentials = json.load(f)
        
        client_id = google_credentials['web']['client_id']
        client_secret = google_credentials['web']['client_secret']
        
        # Crear o actualizar la aplicación social de Google
        social_app, created = SocialApp.objects.get_or_create(
            provider='google',
            defaults={
                'name': 'Google OAuth',
                'client_id': client_id,
                'secret': client_secret,
            }
        )
        
        if not created:
            # Actualizar credenciales si ya existe
            social_app.client_id = client_id
            social_app.secret = client_secret
            social_app.save()
            self.stdout.write(
                self.style.WARNING('Aplicación social de Google actualizada.')
            )
        else:
            self.stdout.write(
                self.style.SUCCESS('Aplicación social de Google creada exitosamente.')
            )
        
        # Asociar la aplicación con el sitio
        if site not in social_app.sites.all():
            social_app.sites.add(site)
            self.stdout.write(
                self.style.SUCCESS(f'Aplicación social asociada al sitio "{site.name}".')
            )
        else:
            self.stdout.write(
                self.style.WARNING(f'Aplicación social ya está asociada al sitio "{site.name}".')
            )
        
        self.stdout.write(
            self.style.SUCCESS('\n✅ Configuración de Google OAuth completada!')
        )
        self.stdout.write(
            self.style.SUCCESS(f'🔗 Client ID: {client_id[:20]}...')
        )
        self.stdout.write(
            self.style.SUCCESS('🌐 Aplicación configurada para: localhost:8000')
        )
