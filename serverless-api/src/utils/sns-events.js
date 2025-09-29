/**
 * Utilidades para comunicación desacoplada usando Amazon SNS
 * 
 * Este módulo proporciona funciones para publicar eventos en topics SNS
 * permitiendo comunicación asíncrona entre microservicios.
 */

const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');

const snsClient = new SNSClient({ region: process.env.AWS_REGION || 'us-east-1' });

// Topic ARNs desde variables de entorno
const TOPICS = {
  USER_EVENTS: process.env.USER_EVENTS_TOPIC_ARN,
  AGENDA_EVENTS: process.env.AGENDA_EVENTS_TOPIC_ARN,
  NOTIFICATIONS: process.env.NOTIFICATIONS_TOPIC_ARN,
  BOX_EVENTS: process.env.BOX_EVENTS_TOPIC_ARN
};

/**
 * Función genérica para publicar eventos en SNS
 */
async function publishEvent(topicArn, eventType, data, attributes = {}) {
  try {
    const message = {
      eventType,
      timestamp: new Date().toISOString(),
      data,
      source: 'hospital-api'
    };

    const params = {
      TopicArn: topicArn,
      Message: JSON.stringify(message),
      MessageAttributes: {
        eventType: {
          DataType: 'String',
          StringValue: eventType
        },
        source: {
          DataType: 'String', 
          StringValue: 'hospital-api'
        },
        ...Object.keys(attributes).reduce((acc, key) => {
          acc[key] = {
            DataType: 'String',
            StringValue: String(attributes[key])
          };
          return acc;
        }, {})
      }
    };

    const command = new PublishCommand(params);
    const result = await snsClient.send(command);
    
    console.log(`✅ Event published: ${eventType} to ${topicArn}`, {
      messageId: result.MessageId,
      eventType,
      data: JSON.stringify(data).substring(0, 100) + '...'
    });
    
    return result;
  } catch (error) {
    console.error(`❌ Error publishing event ${eventType}:`, error);
    throw error;
  }
}

// ===========================
// EVENTOS DE USUARIO
// ===========================

/**
 * Publicar evento de login de usuario
 */
async function publishUserLoginEvent(userEmail, userGroups, hospitalId) {
  return publishEvent(
    TOPICS.USER_EVENTS,
    'USER_LOGGED_IN',
    {
      userEmail,
      userGroups,
      hospitalId,
      loginTime: new Date().toISOString()
    },
    {
      userEmail,
      hospitalId
    }
  );
}

/**
 * Publicar evento de logout de usuario
 */
async function publishUserLogoutEvent(userEmail) {
  return publishEvent(
    TOPICS.USER_EVENTS,
    'USER_LOGGED_OUT',
    {
      userEmail,
      logoutTime: new Date().toISOString()
    },
    {
      userEmail
    }
  );
}

// ===========================
// EVENTOS DE AGENDA
// ===========================

/**
 * Publicar evento de creación de agenda
 */
async function publishAgendaCreatedEvent(agenda, createdBy) {
  return publishEvent(
    TOPICS.AGENDA_EVENTS,
    'AGENDA_CREATED',
    {
      agendaId: agenda.idAgenda,
      boxId: agenda.idBox,
      profesional: agenda.profesional,
      fecha: agenda.fecha,
      horaInicio: agenda.horaInicio,
      horaFin: agenda.horaFin,
      tipoAgenda: agenda.tipoAgenda,
      createdBy,
      createdAt: new Date().toISOString()
    },
    {
      boxId: String(agenda.idBox),
      fecha: agenda.fecha,
      createdBy
    }
  );
}

/**
 * Publicar evento de modificación de agenda
 */
async function publishAgendaUpdatedEvent(oldAgenda, newAgenda, updatedBy) {
  return publishEvent(
    TOPICS.AGENDA_EVENTS,
    'AGENDA_UPDATED',
    {
      agendaId: newAgenda.idAgenda,
      boxId: newAgenda.idBox,
      changes: {
        old: oldAgenda,
        new: newAgenda
      },
      updatedBy,
      updatedAt: new Date().toISOString()
    },
    {
      boxId: String(newAgenda.idBox),
      fecha: newAgenda.fecha,
      updatedBy
    }
  );
}

/**
 * Publicar evento de cancelación de agenda
 */
async function publishAgendaCancelledEvent(agenda, cancelledBy, reason) {
  return publishEvent(
    TOPICS.AGENDA_EVENTS,
    'AGENDA_CANCELLED',
    {
      agendaId: agenda.idAgenda,
      boxId: agenda.idBox,
      profesional: agenda.profesional,
      fecha: agenda.fecha,
      cancelledBy,
      reason,
      cancelledAt: new Date().toISOString()
    },
    {
      boxId: String(agenda.idBox),
      fecha: agenda.fecha,
      cancelledBy
    }
  );
}

// ===========================
// EVENTOS DE BOX
// ===========================

/**
 * Publicar evento de cambio de estado de box
 */
async function publishBoxStateChangeEvent(boxId, oldState, newState, agenda = null) {
  return publishEvent(
    TOPICS.BOX_EVENTS,
    'BOX_STATE_CHANGED',
    {
      boxId,
      oldState,
      newState,
      agenda,
      timestamp: new Date().toISOString()
    },
    {
      boxId: String(boxId),
      newState
    }
  );
}

// ===========================
// NOTIFICACIONES
// ===========================

/**
 * Publicar notificación general
 */
async function publishNotification(type, message, targetUsers = [], priority = 'normal') {
  return publishEvent(
    TOPICS.NOTIFICATIONS,
    'NOTIFICATION',
    {
      type,
      message,
      targetUsers,
      priority,
      createdAt: new Date().toISOString()
    },
    {
      type,
      priority
    }
  );
}

/**
 * Publicar alerta de sistema
 */
async function publishSystemAlert(alertType, message, severity = 'info') {
  return publishEvent(
    TOPICS.NOTIFICATIONS,
    'SYSTEM_ALERT',
    {
      alertType,
      message,
      severity,
      timestamp: new Date().toISOString()
    },
    {
      alertType,
      severity
    }
  );
}

// ===========================
// EXPORTS
// ===========================

module.exports = {
  // Función genérica
  publishEvent,
  
  // Eventos de usuario
  publishUserLoginEvent,
  publishUserLogoutEvent,
  
  // Eventos de agenda
  publishAgendaCreatedEvent,
  publishAgendaUpdatedEvent,
  publishAgendaCancelledEvent,
  
  // Eventos de box
  publishBoxStateChangeEvent,
  
  // Notificaciones
  publishNotification,
  publishSystemAlert,
  
  // Constantes
  TOPICS
};