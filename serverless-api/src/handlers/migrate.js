const AWS = require('aws-sdk');
const mysql = require('mysql2/promise');

const dynamodb = new AWS.DynamoDB.DocumentClient({
  region: process.env.AWS_DEFAULT_REGION || 'us-east-1'
});

const TABLE_NAME = process.env.DYNAMODB_TABLE || 'HospitalData';

// Configuración de conexión MySQL
const mysqlConfig = {
  host: process.env.MYSQL_HOST || 'localhost',
  user: process.env.MYSQL_USER || 'root',
  password: process.env.MYSQL_PASSWORD || '123456',
  database: process.env.MYSQL_DATABASE || 'bdHospital'
};

/**
 * Función principal de migración
 */
module.exports.migrateFromMySQL = async (event) => {
  const startTime = Date.now();
  let connection = null;
  
  try {
    console.log('🚀 Iniciando migración de MySQL a DynamoDB...');
    
    // Conectar a MySQL
    connection = await mysql.createConnection(mysqlConfig);
    console.log('✅ Conectado a MySQL');

    const migrationResults = {
      pasillos: 0,
      boxes: 0,
      especialidades: 0,
      profesionales: 0,
      tiposAgenda: 0,
      agendas: 0,
      errors: []
    };

    // 1. Migrar Pasillos
    console.log('📋 Migrando pasillos...');
    await migratePasillos(connection, migrationResults);

    // 2. Migrar Boxes
    console.log('🏥 Migrando boxes...');
    await migrateBoxes(connection, migrationResults);

    // 3. Migrar Especialidades
    console.log('👩‍⚕️ Migrando especialidades...');
    await migrateEspecialidades(connection, migrationResults);

    // 4. Migrar Profesionales
    console.log('🧑‍⚕️ Migrando profesionales...');
    await migrateProfesionales(connection, migrationResults);

    // 5. Migrar Tipos de Agenda
    console.log('📅 Migrando tipos de agenda...');
    await migrateTiposAgenda(connection, migrationResults);

    // 6. Migrar Agendas
    console.log('📝 Migrando agendas...');
    await migrateAgendas(connection, migrationResults);

    const duration = (Date.now() - startTime) / 1000;
    
    console.log('🎉 Migración completada exitosamente');
    console.log(`⏱️ Tiempo total: ${duration}s`);

    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        success: true,
        message: 'Migración completada exitosamente',
        duration: `${duration}s`,
        results: migrationResults,
        timestamp: new Date().toISOString()
      })
    };

  } catch (error) {
    console.error('❌ Error durante la migración:', error);
    
    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      })
    };
  } finally {
    if (connection) {
      await connection.end();
      console.log('🔌 Conexión MySQL cerrada');
    }
  }
};

/**
 * Migrar pasillos
 */
async function migratePasillos(connection, results) {
  try {
    const [pasillos] = await connection.execute(
      'SELECT idPasillo, pasillo FROM pasillo ORDER BY idPasillo'
    );

    for (const pasillo of pasillos) {
      const item = {
        PK: `PASILLO#${pasillo.idPasillo}`,
        SK: 'METADATA',
        GSI1PK: `PASILLO#${pasillo.idPasillo}`,
        GSI1SK: 'METADATA',
        tipo: 'pasillo',
        pasilloId: pasillo.idPasillo,
        nombre: pasillo.pasillo,
        createdAt: new Date().toISOString()
      };

      await dynamodb.put({
        TableName: TABLE_NAME,
        Item: item
      }).promise();

      results.pasillos++;
    }

    console.log(`✅ ${results.pasillos} pasillos migrados`);
  } catch (error) {
    console.error('Error migrando pasillos:', error);
    results.errors.push(`Pasillos: ${error.message}`);
  }
}

/**
 * Migrar boxes
 */
async function migrateBoxes(connection, results) {
  try {
    const [boxes] = await connection.execute(`
      SELECT b.idBox, b.capacidad, b.idPasillo, p.pasillo 
      FROM box b 
      JOIN pasillo p ON b.idPasillo = p.idPasillo 
      ORDER BY b.idBox
    `);

    for (const box of boxes) {
      const item = {
        PK: `BOX#${box.idBox}`,
        SK: 'METADATA',
        GSI1PK: `PASILLO#${box.idPasillo}`,
        GSI1SK: `BOX#${box.idBox}`,
        tipo: 'box',
        boxId: box.idBox,
        capacidad: box.capacidad || 1,
        pasilloId: box.idPasillo,
        pasillo: box.pasillo,
        disponible: true,
        createdAt: new Date().toISOString()
      };

      await dynamodb.put({
        TableName: TABLE_NAME,
        Item: item
      }).promise();

      results.boxes++;
    }

    console.log(`✅ ${results.boxes} boxes migrados`);
  } catch (error) {
    console.error('Error migrando boxes:', error);
    results.errors.push(`Boxes: ${error.message}`);
  }
}

/**
 * Migrar especialidades
 */
async function migrateEspecialidades(connection, results) {
  try {
    const [especialidades] = await connection.execute(
      'SELECT idEspecialidad, especialidad FROM especialidad ORDER BY idEspecialidad'
    );

    for (const especialidad of especialidades) {
      const item = {
        PK: `ESPECIALIDAD#${especialidad.idEspecialidad}`,
        SK: 'METADATA',
        GSI1PK: `ESPECIALIDAD#${especialidad.idEspecialidad}`,
        GSI1SK: 'METADATA',
        tipo: 'especialidad',
        especialidadId: especialidad.idEspecialidad,
        nombre: especialidad.especialidad,
        createdAt: new Date().toISOString()
      };

      await dynamodb.put({
        TableName: TABLE_NAME,
        Item: item
      }).promise();

      results.especialidades++;
    }

    console.log(`✅ ${results.especialidades} especialidades migradas`);
  } catch (error) {
    console.error('Error migrando especialidades:', error);
    results.errors.push(`Especialidades: ${error.message}`);
  }
}

/**
 * Migrar profesionales
 */
async function migrateProfesionales(connection, results) {
  try {
    const [profesionales] = await connection.execute(`
      SELECT p.idProfesional, p.nombre, p.idEspecialidad, e.especialidad 
      FROM profesional p 
      JOIN especialidad e ON p.idEspecialidad = e.idEspecialidad 
      ORDER BY p.idProfesional
    `);

    for (const profesional of profesionales) {
      const item = {
        PK: `PROFESIONAL#${profesional.idProfesional}`,
        SK: 'METADATA',
        GSI1PK: `ESPECIALIDAD#${profesional.idEspecialidad}`,
        GSI1SK: `PROFESIONAL#${profesional.idProfesional}`,
        tipo: 'profesional',
        profesionalId: profesional.idProfesional,
        nombre: profesional.nombre,
        especialidadId: profesional.idEspecialidad,
        especialidad: profesional.especialidad,
        createdAt: new Date().toISOString()
      };

      await dynamodb.put({
        TableName: TABLE_NAME,
        Item: item
      }).promise();

      results.profesionales++;
    }

    console.log(`✅ ${results.profesionales} profesionales migrados`);
  } catch (error) {
    console.error('Error migrando profesionales:', error);
    results.errors.push(`Profesionales: ${error.message}`);
  }
}

/**
 * Migrar tipos de agenda
 */
async function migrateTiposAgenda(connection, results) {
  try {
    const [tipos] = await connection.execute(
      'SELECT idTipoAgenda, tipoAgenda FROM tipoagenda ORDER BY idTipoAgenda'
    );

    for (const tipo of tipos) {
      const item = {
        PK: `TIPOAGENDA#${tipo.idTipoAgenda}`,
        SK: 'METADATA',
        GSI1PK: `TIPOAGENDA#${tipo.idTipoAgenda}`,
        GSI1SK: 'METADATA',
        tipo: 'tipoagenda',
        tipoAgendaId: tipo.idTipoAgenda,
        nombre: tipo.tipoAgenda,
        createdAt: new Date().toISOString()
      };

      await dynamodb.put({
        TableName: TABLE_NAME,
        Item: item
      }).promise();

      results.tiposAgenda++;
    }

    console.log(`✅ ${results.tiposAgenda} tipos de agenda migrados`);
  } catch (error) {
    console.error('Error migrando tipos agenda:', error);
    results.errors.push(`Tipos Agenda: ${error.message}`);
  }
}

/**
 * Migrar agendas
 */
async function migrateAgendas(connection, results) {
  try {
    const [agendas] = await connection.execute(`
      SELECT a.idAgenda, a.fecha, a.horaInicio, a.horaFin, a.observaciones,
             a.idBox, a.idTipoAgenda, a.idProfesional,
             t.tipoAgenda, p.nombre as profesional_nombre,
             b.idPasillo
      FROM agenda a
      LEFT JOIN tipoagenda t ON a.idTipoAgenda = t.idTipoAgenda
      LEFT JOIN profesional p ON a.idProfesional = p.idProfesional  
      LEFT JOIN box b ON a.idBox = b.idBox
      ORDER BY a.fecha, a.horaInicio
    `);

    for (const agenda of agendas) {
      const item = {
        PK: `AGENDA#${agenda.idAgenda}`,
        SK: `${agenda.fecha}#${agenda.horaInicio}`,
        GSI1PK: `BOX#${agenda.idBox}`,
        GSI1SK: `${agenda.fecha}#${agenda.horaInicio}`,
        tipo: 'agenda',
        agendaId: agenda.idAgenda,
        fecha: agenda.fecha,
        horaInicio: agenda.horaInicio,
        horaFin: agenda.horaFin,
        observaciones: agenda.observaciones || '',
        boxId: agenda.idBox,
        pasilloId: agenda.idPasillo,
        tipoAgendaId: agenda.idTipoAgenda,
        tipoAgenda: agenda.tipoAgenda,
        profesionalId: agenda.idProfesional,
        profesionalNombre: agenda.profesional_nombre,
        createdAt: new Date().toISOString()
      };

      await dynamodb.put({
        TableName: TABLE_NAME,
        Item: item
      }).promise();

      results.agendas++;
    }

    console.log(`✅ ${results.agendas} agendas migradas`);
  } catch (error) {
    console.error('Error migrando agendas:', error);
    results.errors.push(`Agendas: ${error.message}`);
  }
}