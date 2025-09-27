const AWS = require('aws-sdk');

const dynamodb = new AWS.DynamoDB.DocumentClient({
  region: process.env.AWS_DEFAULT_REGION || 'us-east-1'
});

const TABLE_NAME = process.env.DYNAMODB_TABLE || 'HospitalData';

/**
 * Obtener todos los pasillos
 */
module.exports.getPasillos = async (event) => {
  try {
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
      a.nombre.localeCompare(b.nombre)
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
        data: sortedPasillos,
        count: result.Count,
        timestamp: new Date().toISOString()
      }),
    };
  } catch (error) {
    console.error('Error en getPasillos:', error);
    
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
 * Obtener boxes de un pasillo específico
 */
module.exports.getPasilloBoxes = async (event) => {
  try {
    const { pasilloId } = event.pathParameters;
    
    const params = {
      TableName: TABLE_NAME,
      FilterExpression: '#tipo = :tipo AND #pasilloId = :pasilloId',
      ExpressionAttributeNames: { 
        '#tipo': 'tipo',
        '#pasilloId': 'pasilloId'
      },
      ExpressionAttributeValues: { 
        ':tipo': 'box',
        ':pasilloId': parseInt(pasilloId)
      }
    };

    const result = await dynamodb.scan(params).promise();
    
    // Ordenar boxes por número
    const sortedBoxes = result.Items.sort((a, b) => 
      a.boxId - b.boxId
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
        pasilloId: parseInt(pasilloId)
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