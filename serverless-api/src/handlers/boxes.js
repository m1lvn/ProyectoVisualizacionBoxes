const AWS = require('aws-sdk');
const {
  extractUserFromEvent,
  filterBoxesByPermissions,
  createResponse,
  createUnauthorizedResponse,
  createUnauthenticatedResponse
} = require('../utils/auth');
const { retryWithBackoff, CircuitBreaker } = require('../utils/resilience');
const { LambdaMetrics, DynamoMetrics, measureOperation } = require('../utils/metrics');

// Configurar DynamoDB con retry básico
const dynamodb = new AWS.DynamoDB.DocumentClient({
  region: process.env.AWS_DEFAULT_REGION || 'us-east-1',
  maxRetries: 3,
  retryDelayOptions: {
    base: 100
  }
});

const TABLE_NAME = process.env.DYNAMODB_TABLE || 'HospitalData';

// Circuit Breaker para DynamoDB (compartido entre todas las invocaciones)
const dynamoBreaker = new CircuitBreaker({
  failureThreshold: 5,
  successThreshold: 2,
  timeout: 60000,
  resetTimeout: 30000
});

/**
 * Obtener boxes filtrados por pasillo con información completa
 * Implementa control de acceso basado en roles
 * ✅ CON RESILIENCIA: Retry + Circuit Breaker + Fallback
 * ✅ CON MÉTRICAS: CloudWatch custom metrics
 */
module.exports.getBoxes = async (event) => {
  const startTime = Date.now();
  const functionName = 'getBoxes';
  
  try {
    // Registrar request
    await LambdaMetrics.recordRequest(
      functionName,
      event.httpMethod || 'GET',
      event.path || '/boxes'
    );
    
    // Extraer información del usuario autenticado
    let user;
    try {
      user = extractUserFromEvent(event);
    } catch (authError) {
      console.error('Authentication error:', authError);
      await LambdaMetrics.recordError(functionName, 'AuthError', authError.message);
      return createUnauthenticatedResponse();
    }

    console.log('User accessing boxes:', user);

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

    const dynamoStartTime = Date.now();
    const [resultBoxes, resultPasillos] = await Promise.all([
      retryWithBackoff(
        () => dynamoBreaker.execute(() => dynamodb.scan(paramsBoxes).promise()),
        { 
          maxRetries: 3, 
          baseDelay: 100,
          onRetry: async (attempt, delay, error) => {
            console.warn(`⚠️ Retry ${attempt}/3 para getBoxes después de ${delay}ms`, {
              error: error.message,
              throttled: error.code === 'ProvisionedThroughputExceededException'
            });
            
            // Registrar retry
            await LambdaMetrics.recordRetry(functionName, 'DynamoDB.Scan.Boxes', attempt);
            
            // Registrar throttling si aplica
            if (error.code === 'ProvisionedThroughputExceededException') {
              await DynamoMetrics.recordThrottle(TABLE_NAME, 'Scan');
            }
          }
        }
      ),
      retryWithBackoff(
        () => dynamoBreaker.execute(() => dynamodb.scan(paramsPasillos).promise()),
        { 
          maxRetries: 3, 
          baseDelay: 100,
          onRetry: async (attempt, delay, error) => {
            console.warn(`⚠️ Retry ${attempt}/3 para getPasillos después de ${delay}ms`, {
              error: error.message
            });
            await LambdaMetrics.recordRetry(functionName, 'DynamoDB.Scan.Pasillos', attempt);
          }
        }
      )
    ]);
    
    const dynamoDuration = Date.now() - dynamoStartTime;
    
    // Registrar métricas de DynamoDB
    await DynamoMetrics.recordQuery(TABLE_NAME, 'Scan', dynamoDuration, resultBoxes.Items.length);
    
    // Crear mapa de pasillos por ID
    const pasillosMap = {};
    resultPasillos.Items.forEach(pasillo => {
      // Los pasillos ahora usan nombres MySQL
      pasillosMap[pasillo.idPasillo] = pasillo.pasillo;
    });
    
    // Mapear solo campos MySQL puros
    let mappedItems = resultBoxes.Items.map(item => ({
      // Campos MySQL principales
      idBox: item.idBox,
      idPasillo: item.idPasillo,
      pasillo: item.pasillo || pasillosMap[item.idPasillo] || 'Sin pasillo',
      capacidad: item.capacidad,
      disponible: item.disponible,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt
    }));
    
    // Filtrar boxes basado en permisos del usuario
    mappedItems = filterBoxesByPermissions(mappedItems, user);
    
    // Registrar respuesta exitosa
    const totalDuration = Date.now() - startTime;
    await LambdaMetrics.recordResponse(functionName, 200, totalDuration);
    
    return createResponse(200, {
      success: true,
      data: mappedItems,
      count: mappedItems.length,
      userPermissions: {
        userId: user.userId,
        groups: user.groups,
        pasilloAsignado: user.pasilloAsignado
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error en getBoxes:', error);
    
    // Registrar error
    await LambdaMetrics.recordError(functionName, error.code || error.name, error.message);
    
    // Métricas del circuit breaker para debugging
    const breakerStats = dynamoBreaker.getStats();
    console.log('Circuit Breaker Stats:', breakerStats);
    
    // Verificar si es un error de throttling (código específico)
    const isThrottling = error.code === 'ProvisionedThroughputExceededException' ||
                         error.code === 'ThrottlingException';
    
    // Verificar si es un error del circuit breaker
    const isCircuitOpen = error.message && error.message.includes('Circuit breaker is OPEN');
    
    // Registrar métricas específicas
    if (isThrottling) {
      await LambdaMetrics.recordThrottle(functionName, 'DynamoDB');
    }
    
    if (isCircuitOpen) {
      await LambdaMetrics.recordCircuitBreakerState('OPEN', 'Too many failures');
    }
    
    // Registrar respuesta de error
    const totalDuration = Date.now() - startTime;
    const statusCode = isThrottling || isCircuitOpen ? 503 : 500;
    await LambdaMetrics.recordResponse(functionName, statusCode, totalDuration);
    
    // Estrategia de fallback: datos degradados
    if (isThrottling || isCircuitOpen) {
      console.warn('⚠️ Servicio degradado, retornando respuesta fallback');
      
      return createResponse(503, {
        success: false,
        error: 'Service temporarily unavailable due to high load',
        fallback: true,
        degradedMode: true,
        retryAfter: 30,
        circuitBreakerState: breakerStats.state,
        message: 'El sistema está experimentando alta carga. Por favor, intenta de nuevo en unos segundos.',
        timestamp: new Date().toISOString()
      });
    }
    
    // Error genérico
    return createResponse(500, {
      success: false,
      error: error.message,
      circuitBreakerState: breakerStats.state,
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Obtener estado detallado de un box específico
 * ✅ CON RESILIENCIA: Retry + Circuit Breaker
 */
module.exports.getBoxDetail = async (event) => {
  try {
    const { idBox } = event.pathParameters;
    
    const params = {
      TableName: TABLE_NAME,
      Key: {
        PK: `BOX#${idBox}`,
        SK: 'METADATA'
      }
    };

    // Usar retry y circuit breaker
    const result = await retryWithBackoff(
      () => dynamoBreaker.execute(() => dynamodb.get(params).promise()),
      { 
        maxRetries: 3, 
        baseDelay: 100,
        onRetry: (attempt, delay, error) => {
          console.warn(`⚠️ Retry ${attempt}/3 para getBoxDetail después de ${delay}ms`, {
            idBox,
            error: error.message
          });
        }
      }
    );
    
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
    console.error('❌ Error en getBoxDetail:', error);
    
    const breakerStats = dynamoBreaker.getStats();
    const isThrottling = error.code === 'ProvisionedThroughputExceededException';
    const isCircuitOpen = error.message && error.message.includes('Circuit breaker is OPEN');
    
    if (isThrottling || isCircuitOpen) {
      return {
        statusCode: 503,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json',
          'Retry-After': '30'
        },
        body: JSON.stringify({
          success: false,
          error: 'Service temporarily unavailable',
          fallback: true,
          circuitBreakerState: breakerStats.state
        })
      };
    }
    
    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        success: false,
        error: error.message,
        circuitBreakerState: breakerStats.state
      })
    };
  }
};