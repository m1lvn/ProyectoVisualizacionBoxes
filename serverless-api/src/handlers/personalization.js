const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, PutCommand, ScanCommand } = require('@aws-sdk/lib-dynamodb');
const { extractUserFromEvent } = require('../utils/auth');

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.HOSPITAL_DATA_TABLE || 'HospitalData';

/**
 * Obtener configuración de personalización por cliente
 * GET /config/{clientId}
 */
const getClientConfig = async (event) => {
  try {
    // Validar JWT y extraer usuario
    const user = extractUserFromEvent(event);
    if (!user) {
      return {
        statusCode: 401,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type,Authorization',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ error: 'Usuario no autenticado' })
      };
    }

    const clientId = event.pathParameters?.clientId;
    if (!clientId) {
      return {
        statusCode: 400,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type,Authorization',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ error: 'clientId es requerido' })
      };
    }

    // Obtener configuración de branding
    const brandingParams = {
      TableName: TABLE_NAME,
      Key: {
        PK: `CLIENT#${clientId}`,
        SK: 'CONFIG#branding'
      }
    };

    // Obtener configuración de textos
    const textsParams = {
      TableName: TABLE_NAME,
      Key: {
        PK: `CLIENT#${clientId}`,
        SK: 'CONFIG#texts'
      }
    };

    const [brandingResult, textsResult] = await Promise.all([
      dynamoDb.send(new GetCommand(brandingParams)),
      dynamoDb.send(new GetCommand(textsParams))
    ]);

    // Configuración por defecto si no existe
    const defaultBranding = {
      colors: { primary: '#0066cc', secondary: '#28a745', accent: '#17a2b8' },
      logo: null,
      name: 'Hospital',
      favicon: null
    };

    const defaultTexts = {
      welcomeMessage: 'Bienvenido al Sistema Hospitalario',
      labels: { 
        boxes: 'Boxes', 
        pasillos: 'Pasillos',
        agendas: 'Agendas',
        profesionales: 'Profesionales'
      },
      messages: {
        loading: 'Cargando...',
        noData: 'No hay datos disponibles',
        error: 'Error al cargar información'
      }
    };

    const config = {
      clientId,
      branding: brandingResult.Item ? {
        colors: brandingResult.Item.colors || defaultBranding.colors,
        logo: brandingResult.Item.logo || defaultBranding.logo,
        name: brandingResult.Item.name || defaultBranding.name,
        favicon: brandingResult.Item.favicon || defaultBranding.favicon
      } : defaultBranding,
      texts: textsResult.Item ? {
        welcomeMessage: textsResult.Item.welcomeMessage || defaultTexts.welcomeMessage,
        labels: { ...defaultTexts.labels, ...(textsResult.Item.labels || {}) },
        messages: { ...defaultTexts.messages, ...(textsResult.Item.messages || {}) }
      } : defaultTexts,
      lastUpdated: Math.max(
        brandingResult.Item?.updatedAt || 0,
        textsResult.Item?.updatedAt || 0
      )
    };

    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(config)
    };

  } catch (error) {
    console.error('Error obteniendo configuración del cliente:', error);
    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ error: 'Error interno del servidor' })
    };
  }
};

/**
 * Actualizar configuración de personalización por cliente
 * PUT /config/{clientId}
 */
const updateClientConfig = async (event) => {
  try {
    // Validar JWT y extraer usuario
    const user = extractUserFromEvent(event);
    if (!user) {
      return {
        statusCode: 401,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type,Authorization',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ error: 'Usuario no autenticado' })
      };
    }

    // Solo Admin puede modificar configuración
    if (!user.groups || !user.groups.includes('Admin')) {
      return {
        statusCode: 403,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type,Authorization',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ error: 'Solo administradores pueden modificar la configuración' })
      };
    }

    const clientId = event.pathParameters?.clientId;
    if (!clientId) {
      return {
        statusCode: 400,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type,Authorization',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ error: 'clientId es requerido' })
      };
    }

    let requestBody;
    try {
      requestBody = JSON.parse(event.body || '{}');
    } catch (parseError) {
      return {
        statusCode: 400,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type,Authorization',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ error: 'JSON inválido en el cuerpo de la petición' })
      };
    }

    const { branding, texts } = requestBody;
    const timestamp = Date.now();
    const updates = [];

    // Actualizar configuración de branding si se proporciona
    if (branding) {
      const brandingParams = {
        TableName: TABLE_NAME,
        Item: {
          PK: `CLIENT#${clientId}`,
          SK: 'CONFIG#branding',
          colors: branding.colors || { primary: '#0066cc', secondary: '#28a745', accent: '#17a2b8' },
          logo: branding.logo || null,
          name: branding.name || 'Hospital',
          favicon: branding.favicon || null,
          updatedAt: timestamp,
          updatedBy: user.email || user.sub
        }
      };
      updates.push(dynamoDb.send(new PutCommand(brandingParams)));
    }

    // Actualizar configuración de textos si se proporciona
    if (texts) {
      const textsParams = {
        TableName: TABLE_NAME,
        Item: {
          PK: `CLIENT#${clientId}`,
          SK: 'CONFIG#texts',
          welcomeMessage: texts.welcomeMessage || 'Bienvenido al Sistema Hospitalario',
          labels: texts.labels || { 
            boxes: 'Boxes', 
            pasillos: 'Pasillos',
            agendas: 'Agendas',
            profesionales: 'Profesionales'
          },
          messages: texts.messages || {
            loading: 'Cargando...',
            noData: 'No hay datos disponibles',
            error: 'Error al cargar información'
          },
          updatedAt: timestamp,
          updatedBy: user.email || user.sub
        }
      };
      updates.push(dynamoDb.send(new PutCommand(textsParams)));
    }

    if (updates.length === 0) {
      return {
        statusCode: 400,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type,Authorization',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ error: 'Se debe proporcionar al menos branding o texts para actualizar' })
      };
    }

    // Ejecutar todas las actualizaciones
    await Promise.all(updates);

    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ 
        message: 'Configuración actualizada exitosamente',
        clientId,
        updatedAt: timestamp,
        updatedBy: user.email || user.sub
      })
    };

  } catch (error) {
    console.error('Error actualizando configuración del cliente:', error);
    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ error: 'Error interno del servidor' })
    };
  }
};

/**
 * Listar todos los clientes con configuración
 * GET /config
 */
const listClients = async (event) => {
  try {
    // Validar JWT y extraer usuario
    const user = extractUserFromEvent(event);
    if (!user) {
      return {
        statusCode: 401,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type,Authorization',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ error: 'Usuario no autenticado' })
      };
    }

    // Solo Admin puede ver lista de clientes
    if (!user.groups || !user.groups.includes('Admin')) {
      return {
        statusCode: 403,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type,Authorization',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ error: 'Solo administradores pueden ver la lista de clientes' })
      };
    }

    const scanParams = {
      TableName: TABLE_NAME,
      FilterExpression: 'begins_with(PK, :pk_prefix) AND SK = :sk',
      ExpressionAttributeValues: {
        ':pk_prefix': 'CLIENT#',
        ':sk': 'CONFIG#branding'
      },
      ProjectionExpression: 'PK, #name, updatedAt',
      ExpressionAttributeNames: {
        '#name': 'name'
      }
    };

    const result = await dynamoDb.send(new ScanCommand(scanParams));

    const clients = result.Items.map(item => ({
      clientId: item.PK.replace('CLIENT#', ''),
      name: item.name || 'Hospital',
      lastUpdated: item.updatedAt || 0
    }));

    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ clients })
    };

  } catch (error) {
    console.error('Error listando clientes:', error);
    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ error: 'Error interno del servidor' })
    };
  }
};

module.exports = {
  getClientConfig,
  updateClientConfig,
  listClients
};