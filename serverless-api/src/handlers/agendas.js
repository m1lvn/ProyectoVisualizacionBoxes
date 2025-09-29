const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');

const dynamodb = new AWS.DynamoDB.DocumentClient({
  region: process.env.AWS_DEFAULT_REGION || 'us-east-1'
});

const TABLE_NAME = process.env.DYNAMODB_TABLE || 'HospitalData';

/**
 * Obtener agendas con filtros
 */
module.exports.getAgendas = async (event) => {
  try {
    const { fecha, idBox, idPasillo, idProfesional } = event.queryStringParameters || {};
    
    let params = {
      TableName: TABLE_NAME,
      FilterExpression: '#tipo = :tipo',
      ExpressionAttributeNames: { 
        '#tipo': 'tipo' 
      },
      ExpressionAttributeValues: { 
        ':tipo': 'agenda' 
      }
    };

    // Agregar filtros según parámetros
    if (fecha) {
      params.FilterExpression += ' AND #fecha = :fecha';
      params.ExpressionAttributeNames['#fecha'] = 'fecha';
      params.ExpressionAttributeValues[':fecha'] = fecha;
    }

    if (idBox) {
      params.FilterExpression += ' AND #idBox = :idBox';
      params.ExpressionAttributeNames['#idBox'] = 'idBox';
      params.ExpressionAttributeValues[':idBox'] = parseInt(idBox);
    }

    if (idPasillo) {
      params.FilterExpression += ' AND #idPasillo = :idPasillo';
      params.ExpressionAttributeNames['#idPasillo'] = 'idPasillo';
      params.ExpressionAttributeValues[':idPasillo'] = parseInt(idPasillo);
    }

    if (idProfesional) {
      params.FilterExpression += ' AND #idProfesional = :idProfesional';
      params.ExpressionAttributeNames['#idProfesional'] = 'idProfesional';
      params.ExpressionAttributeValues[':idProfesional'] = parseInt(idProfesional);
    }

    const result = await dynamodb.scan(params).promise();
    
    // Ordenar por fecha y hora
    const sortedAgendas = result.Items.sort((a, b) => {
      if (a.fecha !== b.fecha) {
        return new Date(a.fecha) - new Date(b.fecha);
      }
      return a.horaInicio.localeCompare(b.horaInicio);
    });

    // Los datos ya vienen con nombres MySQL desde migrate_local.py corregido
    const mappedAgendas = sortedAgendas.map(item => ({
      // Campos MySQL principales
      idAgenda: item.idAgenda,
      idBox: item.idBox,
      idPasillo: item.idPasillo,
      idProfesional: item.idProfesional,
      idTipoAgenda: item.idTipoAgenda,
      fecha: item.fecha,
      horaInicio: item.horaInicio,
      horaFin: item.horaFin,
      observaciones: item.observaciones,
      profesional: item.profesional,
      especialidad: item.especialidad,
      tipoAgenda: item.tipoAgenda,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt
    }));

    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Credentials': true,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        success: true,
        data: mappedAgendas,
        count: result.Count,
        timestamp: new Date().toISOString()
      }),
    };
  } catch (error) {
    console.error('Error en getAgendas:', error);
    
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
      }),
    };
  }
};

/**
 * Crear nueva agenda - usando nombres MySQL
 */
module.exports.createAgenda = async (event) => {
  try {
    const body = JSON.parse(event.body);
    const { idBox, fecha, horaInicio, horaFin, idTipoAgenda, idProfesional, observaciones } = body;

    // Validaciones básicas
    if (!idBox || !fecha || !horaInicio || !horaFin || !idTipoAgenda) {
      return {
        statusCode: 400,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          success: false,
          error: 'Campos requeridos: idBox, fecha, horaInicio, horaFin, idTipoAgenda'
        })
      };
    }

    // Validar que la hora de inicio sea menor que la de fin
    if (horaInicio >= horaFin) {
      return {
        statusCode: 400,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          success: false,
          error: 'La hora de fin debe ser posterior a la hora de inicio'
        })
      };
    }

    // Verificar que no haya conflictos de horario
    const conflictParams = {
      TableName: TABLE_NAME,
      FilterExpression: '#tipo = :tipo AND #idBox = :idBox AND #fecha = :fecha',
      ExpressionAttributeNames: { 
        '#tipo': 'tipo',
        '#idBox': 'idBox',        // Campo MySQL
        '#fecha': 'fecha'
      },
      ExpressionAttributeValues: { 
        ':tipo': 'agenda',
        ':idBox': parseInt(idBox),
        ':fecha': fecha
      }
    };

    const existingAgendas = await dynamodb.scan(conflictParams).promise();
    
    // Verificar solapamiento de horarios
    const hasConflict = existingAgendas.Items.some(agenda => {
      return (horaInicio < agenda.horaFin && horaFin > agenda.horaInicio);
    });

    if (hasConflict) {
      return {
        statusCode: 409,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          success: false,
          error: 'Ya existe una agenda que se solapa con este horario para el mismo box'
        })
      };
    }

    // Crear nueva agenda con nombres MySQL
    const agendaId = uuidv4();
    const newAgenda = {
      PK: `AGENDA#${agendaId}`,
      SK: `${fecha}#${horaInicio}`,
      GSI1PK: `BOX#${idBox}`,
      GSI1SK: `${fecha}#${horaInicio}`,
      tipo: 'agenda',
      // Campos MySQL
      idAgenda: agendaId,
      idBox: parseInt(idBox),
      fecha,
      horaInicio,
      horaFin,
      idTipoAgenda: idTipoAgenda,
      tipoAgenda: idTipoAgenda,  // Desnormalizado para consultas
      idProfesional: idProfesional ? parseInt(idProfesional) : null,
      profesional: 'No especificado',  // Se resolverá después
      especialidad: 'No especificada', // Se resolverá después
      observaciones: observaciones || '',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    await dynamodb.put({
      TableName: TABLE_NAME,
      Item: newAgenda
    }).promise();

    return {
      statusCode: 201,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        success: true,
        data: newAgenda,
        message: 'Agenda creada exitosamente'
      })
    };

  } catch (error) {
    console.error('Error en createAgenda:', error);
    
    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        success: false,
        error: error.message
      })
    };
  }
};