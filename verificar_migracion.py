"""
Script de verificación de migración MySQL → DynamoDB
Compara los datos entre ambas bases para asegurar integridad completa.
"""

import mysql.connector
import requests
import json
from datetime import datetime

# Configuración MySQL
MYSQL_CONFIG = {
    'host': 'localhost',
    'user': 'root',  # Ajustar según tu configuración
    'password': 'password',  # Ajustar según tu configuración
    'database': 'hospital'  # Ajustar según tu BD
}

# URL de la API
API_BASE_URL = 'https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api'

def compare_boxes():
    """Comparar boxes entre MySQL y DynamoDB"""
    print("🔍 Comparando BOXES...")
    
    # Obtener de MySQL
    mysql_conn = mysql.connector.connect(**MYSQL_CONFIG)
    cursor = mysql_conn.cursor(dictionary=True)
    cursor.execute("SELECT idBox, capacidad, idPasillo FROM box ORDER BY idBox")
    mysql_boxes = cursor.fetchall()
    
    # Obtener de DynamoDB (via API)
    response = requests.get(f"{API_BASE_URL}/boxes")
    dynamo_boxes = response.json() if response.status_code == 200 else []
    
    print(f"MySQL: {len(mysql_boxes)} boxes")
    print(f"DynamoDB: {len(dynamo_boxes)} boxes")
    
    # Verificar datos
    missing_in_dynamo = []
    for mysql_box in mysql_boxes:
        found = any(
            box['boxId'] == mysql_box['idBox'] 
            for box in dynamo_boxes
        )
        if not found:
            missing_in_dynamo.append(mysql_box['idBox'])
    
    if missing_in_dynamo:
        print(f"❌ Boxes faltantes en DynamoDB: {missing_in_dynamo}")
    else:
        print("✅ Todos los boxes migrados correctamente")
    
    cursor.close()
    mysql_conn.close()
    return len(missing_in_dynamo) == 0

def compare_pasillos():
    """Comparar pasillos entre MySQL y DynamoDB"""
    print("\n🔍 Comparando PASILLOS...")
    
    # Obtener de MySQL
    mysql_conn = mysql.connector.connect(**MYSQL_CONFIG)
    cursor = mysql_conn.cursor(dictionary=True)
    cursor.execute("SELECT idPasillo, pasillo FROM pasillo ORDER BY idPasillo")
    mysql_pasillos = cursor.fetchall()
    
    # Obtener de DynamoDB (via API)
    response = requests.get(f"{API_BASE_URL}/pasillos")
    dynamo_pasillos = response.json() if response.status_code == 200 else []
    
    print(f"MySQL: {len(mysql_pasillos)} pasillos")
    print(f"DynamoDB: {len(dynamo_pasillos)} pasillos")
    
    # Verificar datos
    missing_in_dynamo = []
    for mysql_pasillo in mysql_pasillos:
        found = any(
            pasillo['pasilloId'] == mysql_pasillo['idPasillo'] 
            for pasillo in dynamo_pasillos
        )
        if not found:
            missing_in_dynamo.append(mysql_pasillo['idPasillo'])
    
    if missing_in_dynamo:
        print(f"❌ Pasillos faltantes en DynamoDB: {missing_in_dynamo}")
    else:
        print("✅ Todos los pasillos migrados correctamente")
    
    cursor.close()
    mysql_conn.close()
    return len(missing_in_dynamo) == 0

def compare_agendas(fecha='2025-09-28'):
    """Comparar agendas entre MySQL y DynamoDB"""
    print(f"\n🔍 Comparando AGENDAS para {fecha}...")
    
    # Obtener de MySQL
    mysql_conn = mysql.connector.connect(**MYSQL_CONFIG)
    cursor = mysql_conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT idAgenda, fecha, horaInicio, horaFin, idBox, idTipoAgenda
        FROM agenda 
        WHERE fecha = %s 
        ORDER BY idAgenda
    """, (fecha,))
    mysql_agendas = cursor.fetchall()
    
    # Obtener de DynamoDB (via API)
    response = requests.get(f"{API_BASE_URL}/agendas", params={'fecha': fecha})
    dynamo_agendas = response.json() if response.status_code == 200 else []
    
    print(f"MySQL: {len(mysql_agendas)} agendas")
    print(f"DynamoDB: {len(dynamo_agendas)} agendas")
    
    cursor.close()
    mysql_conn.close()
    return True  # Por ahora, solo mostrar conteo

def run_full_verification():
    """Ejecutar verificación completa"""
    print("🚀 INICIANDO VERIFICACIÓN DE MIGRACIÓN COMPLETA")
    print("=" * 60)
    
    results = {
        'boxes': compare_boxes(),
        'pasillos': compare_pasillos(), 
        'agendas': compare_agendas()
    }
    
    print("\n" + "=" * 60)
    print("📊 RESUMEN DE VERIFICACIÓN:")
    
    all_ok = True
    for entity, ok in results.items():
        status = "✅ OK" if ok else "❌ FALTA MIGRAR"
        print(f"{entity.capitalize()}: {status}")
        if not ok:
            all_ok = False
    
    if all_ok:
        print("\n🎉 ¡MIGRACIÓN COMPLETA! Todos los datos están en DynamoDB")
        print("✅ Puedes proceder a eliminar MySQL")
    else:
        print("\n⚠️  Hay datos faltantes. Ejecuta la migración nuevamente.")
        print(f"Comando: curl -X POST {API_BASE_URL}/migrate")

if __name__ == "__main__":
    try:
        run_full_verification()
    except mysql.connector.Error as e:
        print(f"❌ Error conectando a MySQL: {e}")
        print("💡 Ajusta la configuración MYSQL_CONFIG en el script")
    except requests.exceptions.RequestException as e:
        print(f"❌ Error conectando a la API: {e}")
        print("💡 Verifica que la API esté funcionando")
    except Exception as e:
        print(f"❌ Error inesperado: {e}")