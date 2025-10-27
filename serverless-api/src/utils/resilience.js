/**
 * Utilidades de Resiliencia para Chaos Engineering
 * 
 * Implementa patrones de resiliencia:
 * - Retry con backoff exponencial
 * - Circuit Breaker
 * - Timeout management
 * - Fallback strategies
 */

/**
 * Retry con backoff exponencial
 * 
 * @param {Function} fn - Función async a ejecutar
 * @param {Object} options - Opciones de configuración
 * @returns {Promise} Resultado de la función
 */
async function retryWithBackoff(fn, options = {}) {
  const {
    maxRetries = 3,
    baseDelay = 100,
    maxDelay = 10000,
    onRetry = null
  } = options;

  let lastError;
  
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      
      // No reintentar si es el último intento
      if (attempt === maxRetries - 1) {
        throw error;
      }
      
      // Calcular delay con backoff exponencial
      const delay = Math.min(baseDelay * Math.pow(2, attempt), maxDelay);
      
      console.warn(
        `⚠️ Retry ${attempt + 1}/${maxRetries} after ${delay}ms`,
        { error: error.message }
      );
      
      // Callback opcional
      if (onRetry) {
        onRetry(attempt + 1, delay, error);
      }
      
      // Esperar antes del siguiente intento
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  
  throw lastError;
}

/**
 * Circuit Breaker Pattern
 * 
 * Estados:
 * - CLOSED: Normal operation
 * - OPEN: Failing, reject immediately
 * - HALF_OPEN: Testing if service recovered
 */
class CircuitBreaker {
  constructor(options = {}) {
    this.failureThreshold = options.failureThreshold || 5;
    this.successThreshold = options.successThreshold || 2;
    this.timeout = options.timeout || 60000; // 60 segundos
    this.resetTimeout = options.resetTimeout || 30000; // 30 segundos
    
    this.state = 'CLOSED';
    this.failureCount = 0;
    this.successCount = 0;
    this.nextAttempt = Date.now();
    this.stats = {
      totalCalls: 0,
      successfulCalls: 0,
      failedCalls: 0,
      rejectedCalls: 0
    };
  }

  async execute(fn) {
    this.stats.totalCalls++;

    // Si el circuit está abierto
    if (this.state === 'OPEN') {
      if (Date.now() < this.nextAttempt) {
        this.stats.rejectedCalls++;
        const error = new Error('Circuit breaker is OPEN');
        error.code = 'CIRCUIT_OPEN';
        throw error;
      }
      // Transición a HALF_OPEN
      this.state = 'HALF_OPEN';
      console.log('🔄 Circuit breaker: OPEN -> HALF_OPEN');
    }

    try {
      // Ejecutar con timeout
      const result = await this._executeWithTimeout(fn, this.timeout);
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  async _executeWithTimeout(fn, timeout) {
    return Promise.race([
      fn(),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error('Circuit breaker timeout')), timeout)
      )
    ]);
  }

  onSuccess() {
    this.stats.successfulCalls++;
    this.failureCount = 0;

    if (this.state === 'HALF_OPEN') {
      this.successCount++;
      if (this.successCount >= this.successThreshold) {
        this.state = 'CLOSED';
        this.successCount = 0;
        console.log('✅ Circuit breaker: HALF_OPEN -> CLOSED');
      }
    }
  }

  onFailure() {
    this.stats.failedCalls++;
    this.failureCount++;
    this.successCount = 0;

    if (this.failureCount >= this.failureThreshold) {
      this.state = 'OPEN';
      this.nextAttempt = Date.now() + this.resetTimeout;
      console.error(
        `🚨 Circuit breaker opened after ${this.failureCount} failures. ` +
        `Will retry in ${this.resetTimeout}ms`
      );
    }
  }

  getState() {
    return {
      state: this.state,
      failureCount: this.failureCount,
      successCount: this.successCount,
      nextAttempt: this.nextAttempt,
      stats: this.stats
    };
  }

  reset() {
    this.state = 'CLOSED';
    this.failureCount = 0;
    this.successCount = 0;
    this.nextAttempt = Date.now();
    console.log('🔄 Circuit breaker reset to CLOSED');
  }
}

/**
 * Fallback handler
 * 
 * @param {Function} primaryFn - Función principal
 * @param {Function} fallbackFn - Función de fallback
 * @returns {Promise} Resultado de primary o fallback
 */
async function withFallback(primaryFn, fallbackFn) {
  try {
    return await primaryFn();
  } catch (error) {
    console.warn('⚠️ Primary function failed, using fallback', {
      error: error.message
    });
    return await fallbackFn(error);
  }
}

/**
 * Cache simple con TTL
 */
class SimpleCache {
  constructor(ttl = 60000) {
    this.cache = new Map();
    this.ttl = ttl;
  }

  set(key, value) {
    this.cache.set(key, {
      value,
      expiry: Date.now() + this.ttl
    });
  }

  get(key) {
    const item = this.cache.get(key);
    
    if (!item) return null;
    
    if (Date.now() > item.expiry) {
      this.cache.delete(key);
      return null;
    }
    
    return item.value;
  }

  has(key) {
    return this.get(key) !== null;
  }

  clear() {
    this.cache.clear();
  }
}

/**
 * Helper para operaciones de DynamoDB con resiliencia
 */
async function dynamoDBWithResilience(dynamoClient, operation, params, options = {}) {
  const breaker = options.circuitBreaker || new CircuitBreaker();
  const cache = options.cache || null;
  
  // Intentar obtener de cache
  if (cache && operation.name === 'scan') {
    const cacheKey = JSON.stringify(params);
    const cached = cache.get(cacheKey);
    if (cached) {
      console.log('✅ Cache hit for', operation.name);
      return cached;
    }
  }
  
  // Ejecutar con retry y circuit breaker
  const result = await retryWithBackoff(
    () => breaker.execute(() => operation(params).promise()),
    {
      maxRetries: 3,
      baseDelay: 100,
      onRetry: (attempt, delay, error) => {
        console.warn(`DynamoDB operation retry ${attempt}:`, {
          operation: operation.name,
          error: error.code || error.message,
          delay
        });
      }
    }
  );
  
  // Guardar en cache
  if (cache && operation.name === 'scan') {
    const cacheKey = JSON.stringify(params);
    cache.set(cacheKey, result);
  }
  
  return result;
}

module.exports = {
  retryWithBackoff,
  CircuitBreaker,
  withFallback,
  SimpleCache,
  dynamoDBWithResilience
};
