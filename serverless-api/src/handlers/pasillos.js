const AWS = require('aws-sdk');
const {
  extractUserFromEvent,
  filterPasillosByPermissions,
  createResponse,
  createUnauthenticatedResponse
} = require('../utils/auth');

const dynamodb = new AWS.DynamoDB.DocumentClient({
  region: process.env.AWS_DEFAULT_REGION || 'us-east-1'
});

const TABLE_NAME = process.env.DYNAMODB_TABLE || 'HospitalData';

/**
 * Obtener pasillos con control de acceso basado en roles
 */
module.exports.getPasillos = async (event) => {
  try {
    // Extraer información del usuario autenticado
    let user;
    try {
      user = extractUserFromEvent(event);
    } catch (authError) {
      console.error('Authentication error:', authError);
      return createUnauthenticatedResponse();
    }

    console.log('User accessing pasillos:', user);
    const params = {
      TableName: TABLE_NAME,
      FilterExpression: '#tipo = :tipo',
      ExpressionAttributeNames: { 
        '#tipo': 'tipo' 
      },
      ExpressionAttributeValues: { 
        ':tipo': 'pasillo' 
      }
    };

    const result = await dynamodb.scan(params).promise();
    
    // Ordenar pasillos por nombre
    const sortedPasillos = result.Items.sort((a, b) => 
      (a.pasillo || '').localeCompare(b.pasillo || '')
    );

    // Mapear solo campos MySQL puros
    let mappedPasillos = sortedPasillos.map(item => ({
      // Campos MySQL principales
      idPasillo: item.idPasillo,
      pasillo: item.pasillo,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt
    }));

    // Filtrar pasillos basado en permisos del usuario
    mappedPasillos = filterPasillosByPermissions(mappedPasillos, user);

    return createResponse(200, {
      success: true,
      data: mappedPasillos,
      count: mappedPasillos.length,
      userPermissions: {
        userId: user.userId,
        groups: user.groups,
        pasilloAsignado: user.pasilloAsignado
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error en getPasillos:', error);
    
    return createResponse(500, {
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Obtener boxes de un pasillo específico
 */
module.exports.getPasilloBoxes = async (event) => {
  try {
    const { idPasillo } = event.pathParameters;
    
    const params = {
      TableName: TABLE_NAME,
      FilterExpression: '#tipo = :tipo AND #idPasillo = :idPasillo',
      ExpressionAttributeNames: { 
        '#tipo': 'tipo',
        '#idPasillo': 'idPasillo'
      },
      ExpressionAttributeValues: { 
        ':tipo': 'box',
        ':idPasillo': parseInt(idPasillo)
      }
    };

    const result = await dynamodb.scan(params).promise();
    
    // Ordenar boxes por número
    const sortedBoxes = result.Items.sort((a, b) => 
      a.idBox - b.idBox  // Campo MySQL correcto
    );

    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Credentials': true,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        success: true,
        data: sortedBoxes,
        count: result.Count,
        idPasillo: parseInt(idPasillo)
      }),
    };
  } catch (error) {
    console.error('Error en getPasilloBoxes:', error);
    
    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        success: false,
        error: error.message
      }),
    };
  }
};