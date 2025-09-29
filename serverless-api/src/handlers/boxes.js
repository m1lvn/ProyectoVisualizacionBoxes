const AWS = require('aws-sdk');

// Configurar DynamoDB
const dynamodb = new AWS.DynamoDB.DocumentClient({
  region: process.env.AWS_DEFAULT_REGION || 'us-east-1'
});

const TABLE_NAME = process.env.DYNAMODB_TABLE || 'HospitalData';

/**
 * Obtener boxes filtrados por pasillo con información completa
 */
module.exports.getBoxes = async (event) => {
  try {
    const { pasillo, disponible } = event.queryStringParameters || {};
    
    // Obtener boxes
    let paramsBoxes = {
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
      paramsBoxes.FilterExpression += ' AND contains(#pasillo, :pasillo)';
      paramsBoxes.ExpressionAttributeNames['#pasillo'] = 'pasillo';
      paramsBoxes.ExpressionAttributeValues[':pasillo'] = pasillo;
    }

    // Filtrar por disponibilidad si se especifica
    if (disponible !== undefined) {
      paramsBoxes.FilterExpression += ' AND #disponible = :disponible';
      paramsBoxes.ExpressionAttributeNames['#disponible'] = 'disponible';
      paramsBoxes.ExpressionAttributeValues[':disponible'] = disponible === 'true';
    }

    // Obtener pasillos para mapear nombres
    const paramsPasillos = {
      TableName: TABLE_NAME,
      FilterExpression: '#tipo = :tipo',
      ExpressionAttributeNames: { 
        '#tipo': 'tipo' 
      },
      ExpressionAttributeValues: { 
        ':tipo': 'pasillo' 
      }
    };

    const [resultBoxes, resultPasillos] = await Promise.all([
      dynamodb.scan(paramsBoxes).promise(),
      dynamodb.scan(paramsPasillos).promise()
    ]);
    
    // Crear mapa de pasillos por ID
    const pasillosMap = {};
    resultPasillos.Items.forEach(pasillo => {
      // Los pasillos ahora usan nombres MySQL
      pasillosMap[pasillo.idPasillo] = pasillo.pasillo;
    });
    
    // Mapear nombres de campos para coincidir EXACTAMENTE con MySQL original
    const mappedItems = resultBoxes.Items.map(item => ({
      ...item,
      // Los datos ya vienen con nombres MySQL desde el migrate_local.py corregido
      idBox: item.idBox,           // MySQL original: 'idBox' 
      idPasillo: item.idPasillo,   // MySQL original: 'idPasillo'
      pasillo: item.pasillo || pasillosMap[item.idPasillo] || 'Sin pasillo', // MySQL original: 'pasillo'
      capacidad: item.capacidad,   // MySQL original: 'capacidad'
      disponible: item.disponible, // Para compatibilidad
      // Mantener campos originales para compatibilidad con código legacy
      boxId: item.idBox,          // Legacy compatibility
      pasilloId: item.idPasillo   // Legacy compatibility
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
        count: resultBoxes.Count,
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