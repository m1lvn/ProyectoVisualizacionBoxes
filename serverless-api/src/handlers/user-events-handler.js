/**
 * Event Handler para procesar eventos de usuario
 * 
 * Este Lambda se suscribe al topic USER_EVENTS y procesa eventos como:
 * - USER_LOGGED_IN: Registrar actividad, actualizar estadísticas
 * - USER_LOGGED_OUT: Limpiar sesiones, registrar duración
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.DYNAMODB_TABLE || 'HospitalData';

/**
 * Handler principal para eventos de usuario
 */
exports.handleUserEvents = async (event) => {
  console.log('📥 Processing user events:', JSON.stringify(event, null, 2));

  const promises = event.Records.map(async (record) => {
    try {
      const snsMessage = JSON.parse(record.Sns.Message);
      const { eventType, data, timestamp } = snsMessage;

      console.log(`Processing event: ${eventType}`, data);

      switch (eventType) {
        case 'USER_LOGGED_IN':
          await handleUserLogin(data);
          break;
          
        case 'USER_LOGGED_OUT':
          await handleUserLogout(data);
          break;
          
        default:
          console.warn(`Unknown event type: ${eventType}`);
      }
    } catch (error) {
      console.error('Error processing user event:', error);
      // No re-throw para evitar que fallos individuales afecten otros eventos
    }
  });

  await Promise.all(promises);
  
  return {
    statusCode: 200,
    body: JSON.stringify({
      message: `Processed ${event.Records.length} user events`
    })
  };
};

/**
 * Procesar evento de login de usuario
 */
async function handleUserLogin(data) {
  const { userEmail, userGroups, hospitalId, loginTime } = data;
  
  // 1. Registrar actividad de login
  await dynamoDb.send(new PutCommand({
    TableName: TABLE_NAME,
    Item: {
      PK: `USER_ACTIVITY#${userEmail}`,
      SK: `LOGIN#${Date.now()}`,
      userEmail,
      eventType: 'LOGIN',
      userGroups,
      hospitalId,
      timestamp: loginTime,
      ttl: Math.floor(Date.now() / 1000) + (30 * 24 * 60 * 60) // 30 días TTL
    }
  }));

  // 2. Actualizar estadísticas de usuario
  await dynamoDb.send(new UpdateCommand({
    TableName: TABLE_NAME,
    Key: {
      PK: `USER_STATS#${userEmail}`,
      SK: 'STATS'
    },
    UpdateExpression: 'ADD loginCount :inc SET lastLogin = :lastLogin, hospitalId = :hospitalId, userGroups = :groups',
    ExpressionAttributeValues: {
      ':inc': 1,
      ':lastLogin': loginTime,
      ':hospitalId': hospitalId,
      ':groups': userGroups
    }
  }));

  console.log(`✅ User login processed: ${userEmail}`);
}

/**
 * Procesar evento de logout de usuario
 */
async function handleUserLogout(data) {
  const { userEmail, logoutTime } = data;
  
  // Registrar actividad de logout
  await dynamoDb.send(new PutCommand({
    TableName: TABLE_NAME,
    Item: {
      PK: `USER_ACTIVITY#${userEmail}`,
      SK: `LOGOUT#${Date.now()}`,
      userEmail,
      eventType: 'LOGOUT',
      timestamp: logoutTime,
      ttl: Math.floor(Date.now() / 1000) + (30 * 24 * 60 * 60) // 30 días TTL
    }
  }));

  console.log(`✅ User logout processed: ${userEmail}`);
}