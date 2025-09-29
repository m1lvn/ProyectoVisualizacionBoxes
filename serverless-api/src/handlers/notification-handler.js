/**
 * Event Handler para procesar notificaciones del sistema
 * 
 * Este Lambda se suscribe al topic NOTIFICATIONS y procesa:
 * - NOTIFICATION: Notificaciones generales para usuarios
 * - SYSTEM_ALERT: Alertas del sistema
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, QueryCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.DYNAMODB_TABLE || 'HospitalData';

/**
 * Handler principal para notificaciones
 */
exports.handleNotifications = async (event) => {
  console.log('🔔 Processing notification events:', JSON.stringify(event, null, 2));

  const promises = event.Records.map(async (record) => {
    try {
      const snsMessage = JSON.parse(record.Sns.Message);
      const { eventType, data, timestamp } = snsMessage;

      console.log(`Processing notification: ${eventType}`, data);

      switch (eventType) {
        case 'NOTIFICATION':
          await handleNotification(data);
          break;
          
        case 'SYSTEM_ALERT':
          await handleSystemAlert(data);
          break;
          
        default:
          console.warn(`Unknown notification type: ${eventType}`);
      }
    } catch (error) {
      console.error('Error processing notification:', error);
    }
  });

  await Promise.all(promises);
  
  return {
    statusCode: 200,
    body: JSON.stringify({
      message: `Processed ${event.Records.length} notifications`
    })
  };
};

/**
 * Procesar notificación general
 */
async function handleNotification(data) {
  const { type, message, targetUsers, priority, createdAt } = data;
  const notificationId = `notification-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  
  // Guardar notificación general
  await dynamoDb.send(new PutCommand({
    TableName: TABLE_NAME,
    Item: {
      PK: `NOTIFICATION#${notificationId}`,
      SK: 'NOTIFICATION',
      notificationId,
      type,
      message,
      priority,
      createdAt,
      targetUsers,
      status: 'sent'
    }
  }));

  // Crear notificaciones individuales para cada usuario
  const userNotificationPromises = targetUsers.map(async (userEmail) => {
    return dynamoDb.send(new PutCommand({
      TableName: TABLE_NAME,
      Item: {
        PK: `USER_NOTIFICATIONS#${userEmail}`,
        SK: `${Date.now()}#${notificationId}`,
        notificationId,
        userEmail,
        type,
        message,
        priority,
        createdAt,
        read: false,
        ttl: Math.floor(Date.now() / 1000) + (7 * 24 * 60 * 60) // 7 días TTL
      }
    }));
  });

  await Promise.all(userNotificationPromises);
  console.log(`✅ Notification processed: ${notificationId} for ${targetUsers.length} users`);
}

/**
 * Procesar alerta del sistema
 */
async function handleSystemAlert(data) {
  const { alertType, message, severity, timestamp } = data;
  const alertId = `alert-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  
  // Guardar alerta del sistema
  await dynamoDb.send(new PutCommand({
    TableName: TABLE_NAME,
    Item: {
      PK: `SYSTEM_ALERT#${alertId}`,
      SK: 'ALERT',
      alertId,
      alertType,
      message,
      severity,
      timestamp,
      status: 'active',
      ttl: Math.floor(Date.now() / 1000) + (30 * 24 * 60 * 60) // 30 días TTL
    }
  }));

  // Para alertas críticas, notificar a todos los administradores
  if (severity === 'critical' || severity === 'error') {
    await dynamoDb.send(new PutCommand({
      TableName: TABLE_NAME,
      Item: {
        PK: `USER_NOTIFICATIONS#admin@hospital.com`,
        SK: `${Date.now()}#${alertId}`,
        notificationId: alertId,
        userEmail: 'admin@hospital.com',
        type: 'SYSTEM_ALERT',
        message: `🚨 ${alertType}: ${message}`,
        priority: 'critical',
        createdAt: timestamp,
        read: false
      }
    }));
  }

  console.log(`✅ System alert processed: ${alertId} (${severity})`);
}

/**
 * Función auxiliar para obtener notificaciones de usuario (se puede usar desde API)
 */
exports.getUserNotifications = async (userEmail, limit = 50) => {
  try {
    const result = await dynamoDb.send(new QueryCommand({
      TableName: TABLE_NAME,
      KeyConditionExpression: 'PK = :pk',
      ExpressionAttributeValues: {
        ':pk': `USER_NOTIFICATIONS#${userEmail}`
      },
      ScanIndexForward: false, // Más recientes primero
      Limit: limit
    }));

    return result.Items || [];
  } catch (error) {
    console.error('Error getting user notifications:', error);
    return [];
  }
};