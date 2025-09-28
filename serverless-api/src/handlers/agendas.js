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
    const { fecha, boxId, pasilloId, profesionalId } = event.queryStringParameters || {};
    
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

    if (boxId) {
      params.FilterExpression += ' AND #boxId = :boxId';
      params.ExpressionAttributeNames['#boxId'] = 'boxId';
      params.ExpressionAttributeValues[':boxId'] = parseInt(boxId);
    }

    if (pasilloId) {
      params.FilterExpression += ' AND #pasilloId = :pasilloId';
      params.ExpressionAttributeNames['#pasilloId'] = 'pasilloId';
      params.ExpressionAttributeValues[':pasilloId'] = parseInt(pasilloId);
    }

    if (profesionalId) {
      params.FilterExpression += ' AND #profesionalId = :profesionalId';
      params.ExpressionAttributeNames['#profesionalId'] = 'profesionalId';
      params.ExpressionAttributeValues[':profesionalId'] = parseInt(profesionalId);
    }

    const result = await dynamodb.scan(params).promise();
    
    // Ordenar por fecha y hora
    const sortedAgendas = result.Items.sort((a, b) => {
      if (a.fecha !== b.fecha) {
        return new Date(a.fecha) - new Date(b.fecha);
      }
      return a.horaInicio.localeCompare(b.horaInicio);
    });

    // Mapear nombres de campos para coincidir EXACTAMENTE con MySQL original
    const mappedAgendas = sortedAgendas.map(item => ({
      ...item,
      idAgenda: item.agendaId,             // MySQL original: 'idAgenda'
      idBox: item.boxId,                   // MySQL original: 'idBox'
      idPasillo: item.pasilloId,          // MySQL original: 'idPasillo'
      idProfesional: item.profesionalId,  // MySQL original: 'idProfesional'
      idTipoAgenda: item.tipoAgenda,      // MySQL original: 'idTipoAgenda'
      // Campos para JavaScript
      profesional: item.nombreProfesional || item.profesional || 'No especificado',
      especialidad: item.especialidad || 'No especificada',
      // Mantener campos originales para compatibilidad
      boxId: item.boxId,
      pasilloId: item.pasilloId,
      agendaId: item.agendaId,
      profesionalId: item.profesionalId
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
 * Crear nueva agenda
 */
module.exports.createAgenda = async (event) => {
  try {
    const body = JSON.parse(event.body);
    const { boxId, fecha, horaInicio, horaFin, tipoAgenda, profesionalId, observaciones } = body;

    // Validaciones básicas
    if (!boxId || !fecha || !horaInicio || !horaFin || !tipoAgenda) {
      return {
        statusCode: 400,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          success: false,
          error: 'Campos requeridos: boxId, fecha, horaInicio, horaFin, tipoAgenda'
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
      FilterExpression: '#tipo = :tipo AND #boxId = :boxId AND #fecha = :fecha',
      ExpressionAttributeNames: { 
        '#tipo': 'tipo',
        '#boxId': 'boxId',
        '#fecha': 'fecha'
      },
      ExpressionAttributeValues: { 
        ':tipo': 'agenda',
        ':boxId': parseInt(boxId),
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

    // Crear nueva agenda
    const agendaId = uuidv4();
    const newAgenda = {
      PK: `AGENDA#${agendaId}`,
      SK: `${fecha}#${horaInicio}`,
      GSI1PK: `BOX#${boxId}`,
      GSI1SK: `${fecha}#${horaInicio}`,
      tipo: 'agenda',
      agendaId,
      boxId: parseInt(boxId),
      fecha,
      horaInicio,
      horaFin,
      tipoAgenda,
      profesionalId: profesionalId ? parseInt(profesionalId) : null,
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