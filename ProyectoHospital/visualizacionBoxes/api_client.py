# ProyectoHospital/visualizacionBoxes/api_client.py
import requests
from django.conf import settings
import json

class ServerlessAPIClient:
    def __init__(self):
        self.base_url = getattr(settings, 'SERVERLESS_API_BASE_URL', 
                               'https://your-api-url.execute-api.us-east-1.amazonaws.com/dev')
        self.timeout = 30
        self.headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        }
    
    def _make_request(self, method, endpoint, params=None, data=None):
        """Hacer request a la API Serverless"""
        url = f"{self.base_url}{endpoint}"
        try:
            if method.upper() == 'GET':
                response = requests.get(url, params=params, headers=self.headers, timeout=self.timeout)
            elif method.upper() == 'POST':
                response = requests.post(url, json=data, headers=self.headers, timeout=self.timeout)
            
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error API: {e}")
            return {'success': False, 'error': str(e)}
    
    def get_pasillos(self):
        """Obtener todos los pasillos"""
        return self._make_request('GET', '/api/pasillos')
    
    def get_boxes(self, pasillo=None, disponible=None):
        """Obtener boxes con filtros opcionales"""
        params = {}
        if pasillo:
            params['pasillo'] = pasillo
        if disponible is not None:
            params['disponible'] = str(disponible).lower()
        
        return self._make_request('GET', '/api/boxes', params=params)
    
    def get_agendas(self, fecha=None, box_id=None, pasillo_id=None):
        """Obtener agendas con filtros opcionales"""
        params = {}
        if fecha:
            params['fecha'] = fecha
        if box_id:
            params['boxId'] = box_id
        if pasillo_id:
            params['pasilloId'] = pasillo_id
        
        return self._make_request('GET', '/api/agendas', params=params)
    
    def create_agenda(self, agenda_data):
        """Crear nueva agenda"""
        return self._make_request('POST', '/api/agendas', data=agenda_data)

# Instancia global
api_client = ServerlessAPIClient()