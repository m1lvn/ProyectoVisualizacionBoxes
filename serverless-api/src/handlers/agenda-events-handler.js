/**
 * Event Handler para procesar eventos de agenda
 * 
 * Este Lambda se suscribe al topic AGENDA_EVENTS y procesa eventos como:
 * - AGENDA_CREATED: Notificar creación, actualizar estadísticas
 * - AGENDA_UPDATED: Procesar cambios, notificar afectados  
 * - AGENDA_CANCELLED: Manejar cancelación, liberar recursos
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, UpdateCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');
const { publishNotification, publishBoxStateChangeEvent } = require('../utils/sns-events');

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.DYNAMODB_TABLE || 'HospitalData';

/**
 * Handler principal para eventos de agenda
 */
exports.handleAgendaEvents = async (event) => {
  console.log('📅 Processing agenda events:', JSON.stringify(event, null, 2));

  const promises = event.Records.map(async (record) => {
    try {
      const snsMessage = JSON.parse(record.Sns.Message);
      const { eventType, data, timestamp } = snsMessage;

      console.log(`Processing agenda event: ${eventType}`, data);

      switch (eventType) {
        case 'AGENDA_CREATED':
          await handleAgendaCreated(data);
          break;
          
        case 'AGENDA_UPDATED':
          await handleAgendaUpdated(data);
          break;
          
        case 'AGENDA_CANCELLED':
          await handleAgendaCancelled(data);
          break;
          
        default:
          console.warn(`Unknown agenda event type: ${eventType}`);
      }
    } catch (error) {
      console.error('Error processing agenda event:', error);
    }
  });

  await Promise.all(promises);
  
  return {
    statusCode: 200,
    body: JSON.stringify({
      message: `Processed ${event.Records.length} agenda events`
    })
  };
};

/**
 * Procesar creación de agenda
 */
async function handleAgendaCreated(data) {
  const { agendaId, boxId, profesional, fecha, horaInicio, horaFin, createdBy } = data;
  
  // 1. Registrar evento en historial
  await dynamoDb.send(new PutCommand({
    TableName: TABLE_NAME,
    Item: {
      PK: `AGENDA_HISTORY#${agendaId}`,
      SK: `CREATE#${Date.now()}`,
      agendaId,
      eventType: 'CREATED',
      boxId,
      profesional,
      fecha,
      horaInicio,
      horaFin,
      createdBy,
      timestamp: new Date().toISOString()
    }
  }));

  // 2. Actualizar estadísticas de box
  await dynamoDb.send(new UpdateCommand({
    TableName: TABLE_NAME,
    Key: {
      PK: `BOX_STATS#${boxId}`,
      SK: 'STATS'
    },
    UpdateExpression: 'ADD totalAgendas :inc SET lastAgenda = :lastAgenda',
    ExpressionAttributeValues: {
      ':inc': 1,
      ':lastAgenda': new Date().toISOString()
    }
  }));

  // 3. Publicar cambio de estado del box
  await publishBoxStateChangeEvent(boxId, 'disponible', 'ocupado', {
    agendaId,
    profesional,
    horaInicio,
    horaFin
  });

  // 4. Enviar notificación
  await publishNotification(
    'AGENDA_CREATED',
    `Nueva agenda creada en Box ${boxId} para ${profesional} (${horaInicio}-${horaFin})`,
    [`admin@hospital.com`], // Notificar a administradores
    'normal'
  );

  console.log(`✅ Agenda created processed: ${agendaId} in Box ${boxId}`);
}

/**
 * Procesar actualización de agenda
 */
async function handleAgendaUpdated(data) {
  const { agendaId, changes, updatedBy } = data;
  
  // Registrar cambio en historial
  await dynamoDb.send(new PutCommand({
    TableName: TABLE_NAME,
    Item: {
      PK: `AGENDA_HISTORY#${agendaId}`,
      SK: `UPDATE#${Date.now()}`,
      agendaId,
      eventType: 'UPDATED',
      changes,
      updatedBy,
      timestamp: new Date().toISOString()
    }
  }));

  // Notificar cambios significativos
  const significantChanges = ['horaInicio', 'horaFin', 'profesional', 'fecha'];
  const hasSignificantChanges = significantChanges.some(field => 
    changes.old[field] !== changes.new[field]
  );

  if (hasSignificantChanges) {
    await publishNotification(
      'AGENDA_UPDATED', 
      `Agenda ${agendaId} ha sido modificada`,
      [`admin@hospital.com`],
      'high'
    );
  }

  console.log(`✅ Agenda update processed: ${agendaId}`);
}

/**
 * Procesar cancelación de agenda
 */
async function handleAgendaCancelled(data) {
  const { agendaId, boxId, reason, cancelledBy } = data;
  
  // 1. Registrar cancelación en historial
  await dynamoDb.send(new PutCommand({
    TableName: TABLE_NAME,
    Item: {
      PK: `AGENDA_HISTORY#${agendaId}`,
      SK: `CANCEL#${Date.now()}`,
      agendaId,
      eventType: 'CANCELLED',
      boxId,
      reason,
      cancelledBy,
      timestamp: new Date().toISOString()
    }
  }));

  // 2. Publicar liberación del box
  await publishBoxStateChangeEvent(boxId, 'ocupado', 'disponible');

  // 3. Notificar cancelación
  await publishNotification(
    'AGENDA_CANCELLED',
    `Agenda ${agendaId} en Box ${boxId} ha sido cancelada. Motivo: ${reason}`,
    [`admin@hospital.com`],
    'high'
  );

  console.log(`✅ Agenda cancellation processed: ${agendaId}`);
}