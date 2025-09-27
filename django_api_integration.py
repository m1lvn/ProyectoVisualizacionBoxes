# Configuración para Django - Integración con API Serverless
# Agregar estas configuraciones a tu settings.py

import os
import requests

# API Serverless Configuration
SERVERLESS_API_BASE_URL = os.environ.get(
    'SERVERLESS_API_URL', 
    'https://your-api-id.execute-api.us-east-1.amazonaws.com/dev'
)

# Timeout para llamadas a la API
API_TIMEOUT = 30

# Headers por defecto para las requests
API_HEADERS = {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
}

# Función helper para hacer llamadas a la API
class ServerlessAPIClient:
    def __init__(self):
        self.base_url = SERVERLESS_API_BASE_URL.rstrip('/')
        self.timeout = API_TIMEOUT
        self.headers = API_HEADERS
    
    def get(self, endpoint, params=None):
        """Realizar GET request a la API Serverless"""
        url = f"{self.base_url}{endpoint}"
        try:
            response = requests.get(
                url, 
                params=params, 
                headers=self.headers, 
                timeout=self.timeout
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error llamando API: {e}")
            return None
    
    def post(self, endpoint, data=None):
        """Realizar POST request a la API Serverless"""
        url = f"{self.base_url}{endpoint}"
        try:
            response = requests.post(
                url, 
                json=data, 
                headers=self.headers, 
                timeout=self.timeout
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error llamando API: {e}")
            return None
    
    def get_boxes(self, pasillo=None, disponible=None):
        """Obtener boxes desde la API"""
        params = {}
        if pasillo:
            params['pasillo'] = pasillo
        if disponible is not None:
            params['disponible'] = str(disponible).lower()
        
        return self.get('/api/boxes', params)
    
    def get_agendas(self, fecha=None, box_id=None, pasillo_id=None):
        """Obtener agendas desde la API"""
        params = {}
        if fecha:
            params['fecha'] = fecha
        if box_id:
            params['boxId'] = box_id
        if pasillo_id:
            params['pasilloId'] = pasillo_id
        
        return self.get('/api/agendas', params)
    
    def get_pasillos(self):
        """Obtener pasillos desde la API"""
        return self.get('/api/pasillos')
    
    def create_agenda(self, agenda_data):
        """Crear nueva agenda"""
        return self.post('/api/agendas', agenda_data)

# Instancia global del cliente API
api_client = ServerlessAPIClient()

# Middleware para inyectar el cliente API en las views
class ServerlessAPIMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        request.api_client = api_client
        response = self.get_response(request)
        return response

# Agregar el middleware a MIDDLEWARE en settings.py:
# MIDDLEWARE = [
#     ...
#     'tu_app.middleware.ServerlessAPIMiddleware',
#     ...
# ]