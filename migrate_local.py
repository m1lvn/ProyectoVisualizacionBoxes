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
            'pasilloId': pasillo['idPasillo'],
            'nombre': pasillo['pasillo'],
            'createdAt': datetime.now().isoformat()
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
    cursor.execute("""
        SELECT b.idBox, b.capacidad, b.idPasillo, p.pasillo, b.tipoBox
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
            'boxId': box['idBox'],
            'capacidad': box.get('capacidad', 1) or 1,
            'pasilloId': box['idPasillo'],
            'pasillo': box['pasillo'],
            'tipobox': box.get('tipoBox', 'Standard'),
            'disponible': True,
            'numerocamas': box.get('capacidad', 1) or 1,
            'createdAt': datetime.now().isoformat()
        }
        
        dynamodb_table.put_item(Item=item)
        count += 1
        print(f"  ✅ Box {box['idBox']}: Pasillo {box['idPasillo']}")
    
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
            'especialidadId': especialidad['idEspecialidad'],
            'nombre': especialidad['especialidad'],
            'createdAt': datetime.now().isoformat()
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
            'profesionalId': profesional['idProfesional'],
            'nombre': profesional['nombre'],
            'especialidadId': profesional['idEspecialidad'],
            'especialidad': profesional['especialidad'],
            'createdAt': datetime.now().isoformat()
        }
        
        dynamodb_table.put_item(Item=item)
        count += 1
        print(f"  ✅ Profesional {profesional['idProfesional']}: {profesional['nombre']}")
    
    cursor.close()
    print(f"👨‍⚕️ {count} profesionales migrados")
    return count

def migrate_agendas(mysql_conn, dynamodb_table):
    """Migrar agendas de MySQL a DynamoDB"""
    print("📅 Migrando agendas...")
    
    cursor = mysql_conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT a.idAgenda, a.fecha, a.horaInicio, a.horaFin, 
               a.idBox, a.idProfesional, a.idTipoAgenda,
               p.nombre as profesional_nombre,
               t.tipoAgenda
        FROM agenda a
        LEFT JOIN profesional p ON a.idProfesional = p.idProfesional
        LEFT JOIN tipoagenda t ON a.idTipoAgenda = t.idTipoAgenda
        ORDER BY a.fecha, a.horaInicio
    """)
    agendas = cursor.fetchall()
    
    count = 0
    for agenda in agendas:
        agenda_id = str(uuid.uuid4())
        item = {
            'PK': f"AGENDA#{agenda_id}",
            'SK': str(agenda['fecha']),
            'GSI1PK': f"BOX#{agenda['idBox']}",
            'GSI1SK': str(agenda['fecha']),
            'tipo': 'agenda',
            'agendaId': agenda_id,
            'originalId': agenda['idAgenda'],
            'fecha': str(agenda['fecha']),
            'horaInicio': str(agenda['horaInicio']),
            'horaFin': str(agenda['horaFin']),
            'boxId': agenda['idBox'],
            'profesionalId': agenda.get('idProfesional'),
            'profesional': agenda.get('profesional_nombre', ''),
            'tipoAgendaId': agenda.get('idTipoAgenda'),
            'tipoAgenda': agenda.get('tipoAgenda', ''),
            'createdAt': datetime.now().isoformat()
        }
        
        dynamodb_table.put_item(Item=item)
        count += 1
        print(f"  ✅ Agenda {agenda['fecha']} {agenda['horaInicio']}-{agenda['horaFin']} Box:{agenda['idBox']}")
    
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