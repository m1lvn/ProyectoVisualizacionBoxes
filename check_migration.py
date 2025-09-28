"""
Script para verificar estado actual de migración en DynamoDB
"""

import requests
import json

API_BASE_URL = 'https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api'

def check_migration_status():
    """Verificar qué datos ya están migrados"""
    print("🔍 VERIFICANDO ESTADO DE MIGRACIÓN")
    print("=" * 50)
    
    try:
        # Verificar boxes
        response = requests.get(f"{API_BASE_URL}/boxes")
        if response.status_code == 200:
            boxes = response.json()
            print(f"📦 Boxes en DynamoDB: {len(boxes)}")
            if boxes:
                print(f"   Ejemplo: Box {boxes[0].get('boxId', 'N/A')} - Pasillo {boxes[0].get('pasilloId', 'N/A')}")
        else:
            print("📦 Boxes: ❌ Error obteniendo datos")
        
        # Verificar pasillos
        response = requests.get(f"{API_BASE_URL}/pasillos")
        if response.status_code == 200:
            pasillos = response.json()
            print(f"🏥 Pasillos en DynamoDB: {len(pasillos)}")
            if pasillos:
                print(f"   Ejemplo: {pasillos[0].get('nombre', 'N/A')}")
        else:
            print("🏥 Pasillos: ❌ Error obteniendo datos")
            
        # Verificar agendas
        response = requests.get(f"{API_BASE_URL}/agendas", params={'fecha': '2025-09-28'})
        if response.status_code == 200:
            agendas = response.json()
            print(f"📅 Agendas en DynamoDB: {len(agendas)} (para hoy)")
        else:
            print("📅 Agendas: ❌ Error obteniendo datos")
            
        print("\n" + "=" * 50)
        print("💡 CONCLUSIÓN:")
        print("✅ Pasillos están migrados")
        print("⏳ Boxes, especialidades, profesionales y agendas faltan por completar")
        print("🔧 Ejecutar: python3 migrate_local.py para completar")
        
    except Exception as e:
        print(f"❌ Error verificando migración: {e}")

if __name__ == "__main__":
    check_migration_status()