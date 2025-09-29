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
      params.FilterExpression += ' AND #idBox = :idBox';
      params.ExpressionAttributeNames['#idBox'] = 'idBox';  // Campo MySQL
      params.ExpressionAttributeValues[':idBox'] = parseInt(boxId);
    }

    if (pasilloId) {
      params.FilterExpression += ' AND #idPasillo = :idPasillo';
      params.ExpressionAttributeNames['#idPasillo'] = 'idPasillo';  // Campo MySQL
      params.ExpressionAttributeValues[':idPasillo'] = parseInt(pasilloId);
    }

    if (profesionalId) {
      params.FilterExpression += ' AND #idProfesional = :idProfesional';
      params.ExpressionAttributeNames['#idProfesional'] = 'idProfesional';  // Campo MySQL
      params.ExpressionAttributeValues[':idProfesional'] = parseInt(profesionalId);
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
      // Los datos ya vienen con nombres MySQL desde migrate_local.py corregido
      idAgenda: item.idAgenda,             // MySQL original: 'idAgenda'
      idBox: item.idBox,                   // MySQL original: 'idBox'
      idPasillo: item.idPasillo,          // MySQL original: 'idPasillo' (si existe)
      idProfesional: item.idProfesional,  // MySQL original: 'idProfesional'
      idTipoAgenda: item.idTipoAgenda,    // MySQL original: 'idTipoAgenda'
      // Campos desnormalizados para JavaScript
      profesional: item.profesional || 'No especificado',
      especialidad: item.especialidad || 'No especificada',
      tipoAgenda: item.tipoAgenda || 'No especificado',
      // Mantener campos legacy para compatibilidad
      boxId: item.idBox,                  // Legacy compatibility
      pasilloId: item.idPasillo,         // Legacy compatibility
      agendaId: item.idAgenda,            // Legacy compatibility
      profesionalId: item.idProfesional  // Legacy compatibility
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
    // Validaciones básicas - usar nombre de campo que viene en POST
    const body = JSON.parse(event.body);
    const { boxId, idBox, fecha, horaInicio, horaFin, tipoAgenda, profesionalId, idprofesional, observaciones } = body;

    // Manejar diferentes nombres de campos para compatibilidad
    const finalBoxId = boxId || idBox;
    const finalProfesionalId = profesionalId || idprofesional;

    if (!finalBoxId || !fecha || !horaInicio || !horaFin || !tipoAgenda) {
      return {
        statusCode: 400,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          success: false,
          error: 'Campos requeridos: boxId (o idBox), fecha, horaInicio, horaFin, tipoAgenda'
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
        ':idBox': parseInt(finalBoxId),
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
      GSI1PK: `BOX#${finalBoxId}`,
      GSI1SK: `${fecha}#${horaInicio}`,
      tipo: 'agenda',
      // Usar nombres de MySQL directamente
      idAgenda: agendaId,
      idBox: parseInt(finalBoxId),
      fecha,
      horaInicio,
      horaFin,
      idTipoAgenda: tipoAgenda,
      tipoAgenda: tipoAgenda,      // Desnormalizado para consultas
      idProfesional: finalProfesionalId ? parseInt(finalProfesionalId) : null,
      profesional: 'No especificado', // Se resolverá después
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