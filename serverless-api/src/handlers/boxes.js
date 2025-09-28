const AWS = require('aws-sdk');

// Configurar DynamoDB
const dynamodb = new AWS.DynamoDB.DocumentClient({
  region: process.env.AWS_DEFAULT_REGION || 'us-east-1'
});

const TABLE_NAME = process.env.DYNAMODB_TABLE || 'HospitalData';

/**
 * Obtener boxes filtrados por pasillo
 */
module.exports.getBoxes = async (event) => {
  try {
    const { pasillo, disponible } = event.queryStringParameters || {};
    
    let params = {
      TableName: TABLE_NAME,
      FilterExpression: '#tipo = :tipo',
      ExpressionAttributeNames: { 
        '#tipo': 'tipo' 
      },
      ExpressionAttributeValues: { 
        ':tipo': 'box' 
      }
    };

    // Filtrar por pasillo si se especifica
    if (pasillo) {
      params.FilterExpression += ' AND contains(#pasillo, :pasillo)';
      params.ExpressionAttributeNames['#pasillo'] = 'pasillo';
      params.ExpressionAttributeValues[':pasillo'] = pasillo;
    }

    // Filtrar por disponibilidad si se especifica
    if (disponible !== undefined) {
      params.FilterExpression += ' AND #disponible = :disponible';
      params.ExpressionAttributeNames['#disponible'] = 'disponible';
      params.ExpressionAttributeValues[':disponible'] = disponible === 'true';
    }

    const result = await dynamodb.scan(params).promise();
    
    // Mapear nombres de campos para coincidir con Django
    const mappedItems = result.Items.map(item => ({
      ...item,
      idbox: item.boxId,           // Django espera 'idbox'
      idpasillo: item.pasilloId,   // Django espera 'idpasillo'
      // Mantener campos originales para compatibilidad
      boxId: item.boxId,
      pasilloId: item.pasilloId
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
        data: mappedItems,
        count: result.Count,
        timestamp: new Date().toISOString()
      }),
    };
  } catch (error) {
    console.error('Error en getBoxes:', error);
    
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
 * Obtener estado detallado de un box específico
 */
module.exports.getBoxDetail = async (event) => {
  try {
    const { boxId } = event.pathParameters;
    
    const params = {
      TableName: TABLE_NAME,
      Key: {
        PK: `BOX#${boxId}`,
        SK: 'METADATA'
      }
    };

    const result = await dynamodb.get(params).promise();
    
    if (!result.Item) {
      return {
        statusCode: 404,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          success: false,
          error: 'Box no encontrado'
        })
      };
    }

    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        success: true,
        data: result.Item
      })
    };

  } catch (error) {
    console.error('Error en getBoxDetail:', error);
    
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