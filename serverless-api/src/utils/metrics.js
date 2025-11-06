/**
 * Módulo de Métricas para Chaos Engineering
 * 
 * Publica métricas personalizadas a CloudWatch para monitorear
 * el comportamiento del sistema durante experimentos de chaos.
 */

const AWS = require('aws-sdk');

const cloudwatch = new AWS.CloudWatch({
  region: process.env.AWS_DEFAULT_REGION || 'us-east-1'
});

const NAMESPACE = 'ChaosEngineering/HospitalBoxes';

/**
 * Publicar métrica individual a CloudWatch
 * 
 * @param {string} metricName - Nombre de la métrica
 * @param {number} value - Valor de la métrica
 * @param {string} unit - Unidad (Count, Milliseconds, etc.)
 * @param {Object} dimensions - Dimensiones adicionales
 */
async function publishMetric(metricName, value, unit = 'Count', dimensions = {}) {
  // No publicar métricas en desarrollo local
  if (process.env.IS_LOCAL || process.env.IS_OFFLINE) {
    console.log(`[METRIC] ${metricName}: ${value} ${unit}`, dimensions);
    return;
  }

  try {
    const metricData = {
      MetricName: metricName,
      Value: value,
      Unit: unit,
      Timestamp: new Date(),
      Dimensions: Object.keys(dimensions).map(key => ({
        Name: key,
        Value: String(dimensions[key])
      }))
    };

    await cloudwatch.putMetricData({
      Namespace: NAMESPACE,
      MetricData: [metricData]
    }).promise();

    console.log(`✅ Metric published: ${metricName} = ${value} ${unit}`);
  } catch (error) {
    console.error('❌ Error publishing metric:', error);
    // No fallar la Lambda por errores de métricas
  }
}

/**
 * Publicar múltiples métricas en batch
 * 
 * @param {Array} metrics - Array de {name, value, unit, dimensions}
 */
async function publishMetrics(metrics) {
  if (process.env.IS_LOCAL || process.env.IS_OFFLINE) {
    console.log('[METRICS]', metrics);
    return;
  }

  try {
    const metricData = metrics.map(m => ({
      MetricName: m.name,
      Value: m.value,
      Unit: m.unit || 'Count',
      Timestamp: new Date(),
      Dimensions: m.dimensions ? Object.keys(m.dimensions).map(key => ({
        Name: key,
        Value: String(m.dimensions[key])
      })) : []
    }));

    await cloudwatch.putMetricData({
      Namespace: NAMESPACE,
      MetricData: metricData
    }).promise();

    console.log(`✅ ${metrics.length} metrics published`);
  } catch (error) {
    console.error('❌ Error publishing metrics:', error);
  }
}

/**
 * Wrapper para medir duración de operaciones
 * 
 * @param {string} operationName - Nombre de la operación
 * @param {Function} operation - Función async a ejecutar
 * @param {Object} dimensions - Dimensiones adicionales
 */
async function measureOperation(operationName, operation, dimensions = {}) {
  const startTime = Date.now();
  let success = true;
  let error = null;

  try {
    const result = await operation();
    return result;
  } catch (err) {
    success = false;
    error = err;
    throw err;
  } finally {
    const duration = Date.now() - startTime;

    // Publicar métricas
    await publishMetrics([
      {
        name: `${operationName}.Duration`,
        value: duration,
        unit: 'Milliseconds',
        dimensions: { ...dimensions, Operation: operationName }
      },
      {
        name: `${operationName}.${success ? 'Success' : 'Error'}`,
        value: 1,
        unit: 'Count',
        dimensions: { 
          ...dimensions, 
          Operation: operationName,
          Status: success ? 'Success' : 'Error',
          ErrorType: error ? error.code || error.name : 'None'
        }
      }
    ]);
  }
}

/**
 * Métricas específicas para Lambda
 */
const LambdaMetrics = {
  /**
   * Request recibido
   */
  async recordRequest(functionName, method, path) {
    await publishMetric('Requests', 1, 'Count', {
      Function: functionName,
      Method: method,
      Path: path
    });
  },

  /**
   * Response enviado
   */
  async recordResponse(functionName, statusCode, duration) {
    await publishMetrics([
      {
        name: 'Response.Duration',
        value: duration,
        unit: 'Milliseconds',
        dimensions: { Function: functionName, StatusCode: String(statusCode) }
      },
      {
        name: 'Response.StatusCode',
        value: 1,
        unit: 'Count',
        dimensions: { Function: functionName, StatusCode: String(statusCode) }
      }
    ]);
  },

  /**
   * Error ocurrido
   */
  async recordError(functionName, errorType, errorMessage) {
    await publishMetric('Errors', 1, 'Count', {
      Function: functionName,
      ErrorType: errorType,
      Message: errorMessage.substring(0, 100) // Limitar longitud
    });
  },

  /**
   * Throttling detectado
   */
  async recordThrottle(functionName, operation) {
    await publishMetric('Throttles', 1, 'Count', {
      Function: functionName,
      Operation: operation
    });
  },

  /**
   * Cold start detectado
   */
  async recordColdStart(functionName, duration) {
    await publishMetrics([
      {
        name: 'ColdStarts',
        value: 1,
        unit: 'Count',
        dimensions: { Function: functionName }
      },
      {
        name: 'ColdStart.Duration',
        value: duration,
        unit: 'Milliseconds',
        dimensions: { Function: functionName }
      }
    ]);
  },

  /**
   * Retry ejecutado
   */
  async recordRetry(functionName, operation, attempt) {
    await publishMetric('Retries', 1, 'Count', {
      Function: functionName,
      Operation: operation,
      Attempt: String(attempt)
    });
  },

  /**
   * Circuit Breaker cambió de estado
   */
  async recordCircuitBreakerState(state, reason) {
    await publishMetric('CircuitBreaker.StateChange', 1, 'Count', {
      State: state,
      Reason: reason
    });
  }
};

/**
 * Métricas específicas para DynamoDB
 */
const DynamoMetrics = {
  /**
   * Query/Scan ejecutado
   */
  async recordQuery(tableName, operation, duration, itemCount) {
    await publishMetrics([
      {
        name: 'DynamoDB.Duration',
        value: duration,
        unit: 'Milliseconds',
        dimensions: { Table: tableName, Operation: operation }
      },
      {
        name: 'DynamoDB.ItemCount',
        value: itemCount,
        unit: 'Count',
        dimensions: { Table: tableName, Operation: operation }
      }
    ]);
  },

  /**
   * Throttling de DynamoDB
   */
  async recordThrottle(tableName, operation) {
    await publishMetric('DynamoDB.Throttles', 1, 'Count', {
      Table: tableName,
      Operation: operation
    });
  }
};

module.exports = {
  publishMetric,
  publishMetrics,
  measureOperation,
  LambdaMetrics,
  DynamoMetrics,
  NAMESPACE
};
