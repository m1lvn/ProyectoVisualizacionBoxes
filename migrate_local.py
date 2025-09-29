"""
Script de migración directa MySQL → DynamoDB desde EC2
Ejecuta la migración localmente conectando a MySQL local y DynamoDB en AWS.
"""

import mysql.connector
import boto3
import json
from datetime import datetime
import uuid
import os

# Configuración MySQL local
MYSQL_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': '123456',  # Ajustar según tu configuración
    'database': 'bdHospital'  # Nombre de tu BD
}

# Configuración DynamoDB
REGION = 'us-east-1'
TABLE_NAME = 'HospitalData'

def setup_dynamodb():
    """Configurar cliente DynamoDB"""
    return boto3.resource('dynamodb', region_name=REGION)

def migrate_pasillos(mysql_conn, dynamodb_table):
    """Migrar pasillos de MySQL a DynamoDB"""
    print("📋 Migrando pasillos...")
    
    cursor = mysql_conn.cursor(dictionary=True)
    cursor.execute("SELECT idPasillo, pasillo FROM pasillo ORDER BY idPasillo")
    pasillos = cursor.fetchall()
    
    count = 0
    for pasillo in pasillos:
        item = {
            'PK': f"PASILLO#{pasillo['idPasillo']}",
            'SK': 'METADATA',
            'GSI1PK': f"PASILLO#{pasillo['idPasillo']}",
            'GSI1SK': 'METADATA',
            'tipo': 'pasillo',
            # Usar nombres de MySQL directamente
            'idPasillo': pasillo['idPasillo'],
            'pasillo': pasillo['pasillo'],  # nombre del pasillo
            'createdAt': datetime.now().isoformat(),
            'updatedAt': datetime.now().isoformat()
        }
        
        dynamodb_table.put_item(Item=item)
        count += 1
        print(f"  ✅ Pasillo {pasillo['idPasillo']}: {pasillo['pasillo']}")
    
    cursor.close()
    print(f"📋 {count} pasillos migrados")
    return count

def migrate_boxes(mysql_conn, dynamodb_table):
    """Migrar boxes de MySQL a DynamoDB"""
    print("🏥 Migrando boxes...")
    
    cursor = mysql_conn.cursor(dictionary=True)
    
    # Primero, verificar qué columnas existen
    cursor.execute("DESCRIBE box")
    columns = cursor.fetchall()
    print("🔍 Columnas disponibles en tabla 'box':")
    for col in columns:
        print(f"  - {col['Field']} ({col['Type']})")
    
    # Consulta ajustada sin columnas que no existen
    cursor.execute("""
        SELECT b.idBox, b.capacidad, b.idPasillo, p.pasillo
        FROM box b 
        JOIN pasillo p ON b.idPasillo = p.idPasillo 
        ORDER BY b.idBox
    """)
    boxes = cursor.fetchall()
    
    count = 0
    for box in boxes:
        item = {
            'PK': f"BOX#{box['idBox']}",
            'SK': 'METADATA',
            'GSI1PK': f"PASILLO#{box['idPasillo']}",
            'GSI1SK': f"BOX#{box['idBox']}",
            'tipo': 'box',
            # Usar nombres de MySQL directamente
            'idBox': box['idBox'],
            'capacidad': box.get('capacidad', 1) or 1,
            'idPasillo': box['idPasillo'],
            'pasillo': box['pasillo'],  # nombre del pasillo
            'disponible': True,
            'createdAt': datetime.now().isoformat(),
            'updatedAt': datetime.now().isoformat()
        }
        
        dynamodb_table.put_item(Item=item)
        count += 1
        print(f"  ✅ Box {box['idBox']}: Pasillo {box['idPasillo']} - {box['pasillo']}")
    
    cursor.close()
    print(f"🏥 {count} boxes migrados")
    return count

def migrate_especialidades(mysql_conn, dynamodb_table):
    """Migrar especialidades de MySQL a DynamoDB"""
    print("🩺 Migrando especialidades...")
    
    cursor = mysql_conn.cursor(dictionary=True)
    cursor.execute("SELECT idEspecialidad, especialidad FROM especialidad ORDER BY idEspecialidad")
    especialidades = cursor.fetchall()
    
    count = 0
    for especialidad in especialidades:
        item = {
            'PK': f"ESPECIALIDAD#{especialidad['idEspecialidad']}",
            'SK': 'METADATA',
            'GSI1PK': f"ESPECIALIDAD#{especialidad['idEspecialidad']}",
            'GSI1SK': 'METADATA',
            'tipo': 'especialidad',
            # Usar nombres de MySQL directamente
            'idEspecialidad': especialidad['idEspecialidad'],
            'especialidad': especialidad['especialidad'],
            'createdAt': datetime.now().isoformat(),
            'updatedAt': datetime.now().isoformat()
        }
        
        dynamodb_table.put_item(Item=item)
        count += 1
        print(f"  ✅ Especialidad {especialidad['idEspecialidad']}: {especialidad['especialidad']}")
    
    cursor.close()
    print(f"🩺 {count} especialidades migradas")
    return count

def migrate_profesionales(mysql_conn, dynamodb_table):
    """Migrar profesionales de MySQL a DynamoDB"""
    print("👨‍⚕️ Migrando profesionales...")
    
    cursor = mysql_conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT p.idProfesional, p.nombre, p.idEspecialidad, e.especialidad 
        FROM profesional p 
        JOIN especialidad e ON p.idEspecialidad = e.idEspecialidad 
        ORDER BY p.idProfesional
    """)
    profesionales = cursor.fetchall()
    
    count = 0
    for profesional in profesionales:
        item = {
            'PK': f"PROFESIONAL#{profesional['idProfesional']}",
            'SK': 'METADATA',
            'GSI1PK': f"ESPECIALIDAD#{profesional['idEspecialidad']}",
            'GSI1SK': f"PROFESIONAL#{profesional['idProfesional']}",
            'tipo': 'profesional',
            # Usar nombres de MySQL directamente
            'idProfesional': profesional['idProfesional'],
            'nombre': profesional['nombre'],  # nombre del profesional
            'idEspecialidad': profesional['idEspecialidad'],
            'especialidad': profesional['especialidad'],
            'createdAt': datetime.now().isoformat(),
            'updatedAt': datetime.now().isoformat()
        }
        
        dynamodb_table.put_item(Item=item)
        count += 1
        print(f"  ✅ Profesional {profesional['idProfesional']}: {profesional['nombre']}")
    
    cursor.close()
    print(f"👨‍⚕️ {count} profesionales migrados")
    return count

def migrate_tipos_agenda(mysql_conn, dynamodb_table):
    """Migrar tipos de agenda de MySQL a DynamoDB"""
    print("📋 Migrando tipos de agenda...")
    
    cursor = mysql_conn.cursor(dictionary=True)
    cursor.execute("SELECT idTipoAgenda, tipoAgenda FROM tipoagenda ORDER BY idTipoAgenda")
    tipos = cursor.fetchall()
    
    count = 0
    for tipo in tipos:
        item = {
            'PK': f"TIPOAGENDA#{tipo['idTipoAgenda']}",
            'SK': 'METADATA',
            'GSI1PK': f"TIPOAGENDA#{tipo['idTipoAgenda']}",
            'GSI1SK': 'METADATA',
            'tipo': 'tipoagenda',
            # Usar nombres de MySQL directamente
            'idTipoAgenda': tipo['idTipoAgenda'],
            'tipoAgenda': tipo['tipoAgenda'],
            'createdAt': datetime.now().isoformat(),
            'updatedAt': datetime.now().isoformat()
        }
        
        dynamodb_table.put_item(Item=item)
        count += 1
        print(f"  ✅ Tipo Agenda {tipo['idTipoAgenda']}: {tipo['tipoAgenda']}")
    
    cursor.close()
    print(f"📋 {count} tipos de agenda migrados")
    return count

def migrate_agendas(mysql_conn, dynamodb_table):
    """Migrar agendas de MySQL a DynamoDB"""
    print("📅 Migrando agendas...")
    
    cursor = mysql_conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT a.idAgenda, a.fecha, a.horaInicio, a.horaFin, 
               a.idBox, a.idProfesional, a.idTipoAgenda,
               p.nombre as profesional_nombre,
               e.especialidad as especialidad_nombre,
               t.tipoAgenda,
               a.observaciones
        FROM agenda a
        LEFT JOIN profesional p ON a.idProfesional = p.idProfesional
        LEFT JOIN especialidad e ON p.idEspecialidad = e.idEspecialidad
        LEFT JOIN tipoagenda t ON a.idTipoAgenda = t.idTipoAgenda
        ORDER BY a.fecha, a.horaInicio
    """)
    agendas = cursor.fetchall()
    
    count = 0
    for agenda in agendas:
        agenda_id = str(uuid.uuid4())
        item = {
            'PK': f"AGENDA#{agenda_id}",
            'SK': f"{agenda['fecha']}#{agenda['horaInicio']}",
            'GSI1PK': f"BOX#{agenda['idBox']}",
            'GSI1SK': f"{agenda['fecha']}#{agenda['horaInicio']}",
            'tipo': 'agenda',
            # IDs y datos principales usando nombres MySQL
            'idAgenda': agenda_id,
            'originalId': agenda['idAgenda'],  # ID original de MySQL para referencia
            'fecha': str(agenda['fecha']),
            'horaInicio': str(agenda['horaInicio']),
            'horaFin': str(agenda['horaFin']),
            'idBox': agenda['idBox'],
            'idProfesional': agenda.get('idProfesional'),
            'idTipoAgenda': agenda.get('idTipoAgenda'),
            # Datos desnormalizados para consultas rápidas
            'profesional': agenda.get('profesional_nombre', 'No especificado'),
            'especialidad': agenda.get('especialidad_nombre', 'No especificada'),
            'tipoAgenda': agenda.get('tipoAgenda', 'No especificado'),
            'observaciones': agenda.get('observaciones', '') or '',
            # Metadatos
            'createdAt': datetime.now().isoformat(),
            'updatedAt': datetime.now().isoformat()
        }
        
        dynamodb_table.put_item(Item=item)
        count += 1
        profesional = agenda.get('profesional_nombre', 'Sin profesional')
        print(f"  ✅ Agenda {agenda['fecha']} {agenda['horaInicio']}-{agenda['horaFin']} Box:{agenda['idBox']} - {profesional}")
    
    cursor.close()
    print(f"📅 {count} agendas migradas")
    return count

def run_migration():
    """Ejecutar migración completa"""
    print("🚀 INICIANDO MIGRACIÓN COMPLETA MySQL → DynamoDB")
    print("=" * 60)
    
    start_time = datetime.now()
    
    try:
        # Conectar a MySQL
        mysql_conn = mysql.connector.connect(**MYSQL_CONFIG)
        print("✅ Conectado a MySQL")
        
        # Conectar a DynamoDB
        dynamodb = setup_dynamodb()
        table = dynamodb.Table(TABLE_NAME)
        print("✅ Conectado a DynamoDB")
        
        # Ejecutar migraciones
        results = {}
        results['pasillos'] = migrate_pasillos(mysql_conn, table)
        results['boxes'] = migrate_boxes(mysql_conn, table)  
        results['especialidades'] = migrate_especialidades(mysql_conn, table)
        results['profesionales'] = migrate_profesionales(mysql_conn, table)
        results['tipos_agenda'] = migrate_tipos_agenda(mysql_conn, table)
        results['agendas'] = migrate_agendas(mysql_conn, table)
        
        # Cerrar conexión MySQL
        mysql_conn.close()
        
        # Mostrar resultados
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        print("\n" + "=" * 60)
        print("🎉 MIGRACIÓN COMPLETADA!")
        print(f"⏱️  Tiempo total: {duration:.2f} segundos")
        print("\n📊 Resultados:")
        
        total = 0
        for entity, count in results.items():
            print(f"  {entity.capitalize()}: {count}")
            total += count
            
        print(f"\n✅ Total de registros migrados: {total}")
        print("\n🔗 Puedes verificar en:")
        print("https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api/boxes")
        
    except mysql.connector.Error as e:
        print(f"❌ Error MySQL: {e}")
        print("💡 Verifica credenciales y que MySQL esté corriendo")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    run_migration()