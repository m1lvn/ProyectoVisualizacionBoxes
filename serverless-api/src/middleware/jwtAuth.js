const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

// Cliente JWKS para obtener las claves públicas de Cognito
const client = jwksClient({
  jwksUri: `https://cognito-idp.${process.env.AWS_DEFAULT_REGION}.amazonaws.com/${process.env.USER_POOL_ID}/.well-known/jwks.json`,
  cache: true,
  cacheMaxEntries: 5,
  cacheMaxAge: 600000, // 10 minutes
});

/**
 * Obtener clave de firma para verificar JWT
 */
function getKey(header, callback) {
  client.getSigningKey(header.kid, (err, key) => {
    if (err) {
      callback(err);
      return;
    }
    const signingKey = key.publicKey || key.rsaPublicKey;
    callback(null, signingKey);
  });
}

/**
 * Lambda Authorizer para API Gateway
 * Valida JWT tokens de Cognito y devuelve política IAM
 */
module.exports.authorize = async (event) => {
  try {
    console.log('Authorization event:', JSON.stringify(event, null, 2));
    
    // Extraer token del header Authorization
    const token = event.authorizationToken;
    if (!token) {
      console.log('No authorization token provided');
      throw new Error('Unauthorized');
    }

    // Remover 'Bearer ' prefix si existe
    const cleanToken = token.replace('Bearer ', '');
    
    // Verificar el token JWT
    const decoded = await verifyToken(cleanToken);
    console.log('Token decoded successfully:', decoded);
    
    // Extraer información del usuario
    const principalId = decoded.sub;
    const email = decoded.email;
    const groups = decoded['cognito:groups'] || [];
    const hospitalId = decoded['custom:hospital_id'] || 'default';
    const pasilloAsignado = decoded['custom:pasillo_asignado'] || null;
    
    console.log(`User: ${email}, Groups: ${groups.join(',')}, Hospital: ${hospitalId}, Pasillo: ${pasilloAsignado}`);
    
    // Generar política IAM
    const policy = generatePolicy(principalId, 'Allow', event.methodArn, {
      email,
      groups: groups.join(','),
      hospitalId,
      pasilloAsignado: pasilloAsignado || 'all',
      userId: principalId
    });
    
    console.log('Generated policy:', JSON.stringify(policy, null, 2));
    return policy;
    
  } catch (error) {
    console.error('Authorization error:', error);
    
    // En caso de error, denegar acceso
    const policy = generatePolicy('user', 'Deny', event.methodArn);
    return policy;
  }
};

/**
 * Verificar token JWT usando las claves públicas de Cognito
 */
function verifyToken(token) {
  return new Promise((resolve, reject) => {
    // Primero decodificar header para obtener kid
    const decoded = jwt.decode(token, { complete: true });
    if (!decoded) {
      reject(new Error('Invalid token format'));
      return;
    }

    // Obtener clave de firma
    getKey(decoded.header, (err, key) => {
      if (err) {
        reject(err);
        return;
      }

      // Verificar token con clave pública
      jwt.verify(token, key, {
        algorithms: ['RS256'],
        audience: process.env.USER_POOL_CLIENT_ID,
        issuer: `https://cognito-idp.${process.env.AWS_DEFAULT_REGION}.amazonaws.com/${process.env.USER_POOL_ID}`
      }, (verifyErr, payload) => {
        if (verifyErr) {
          reject(verifyErr);
          return;
        }
        resolve(payload);
      });
    });
  });
}

/**
 * Generar política IAM para API Gateway
 */
function generatePolicy(principalId, effect, resource, context = {}) {
  const authResponse = {
    principalId,
    policyDocument: {
      Version: '2012-10-17',
      Statement: [
        {
          Action: 'execute-api:Invoke',
          Effect: effect,
          Resource: resource
        }
      ]
    }
  };

  // Agregar contexto si se proporciona
  if (Object.keys(context).length > 0) {
    authResponse.context = context;
  }

  return authResponse;
}

/**
 * Middleware para extraer información del usuario desde el contexto de API Gateway
 * Para usar en otras funciones Lambda
 */
function extractUserFromEvent(event) {
  const requestContext = event.requestContext;
  
  if (!requestContext || !requestContext.authorizer) {
    throw new Error('No authorization context found');
  }

  return {
    userId: requestContext.authorizer.userId,
    email: requestContext.authorizer.email,
    groups: requestContext.authorizer.groups ? requestContext.authorizer.groups.split(',') : [],
    hospitalId: requestContext.authorizer.hospitalId || 'default',
    pasilloAsignado: requestContext.authorizer.pasilloAsignado
  };
}

/**
 * Verificar si el usuario tiene un grupo/rol específico
 */
function hasRole(userGroups, requiredRole) {
  if (typeof userGroups === 'string') {
    userGroups = userGroups.split(',');
  }
  return userGroups.includes(requiredRole);
}

/**
 * Verificar permisos de administrador
 */
function isAdmin(userGroups) {
  return hasRole(userGroups, 'Admin');
}

/**
 * Verificar permisos para gestionar reservas/agendas
 */
function canManageAgendas(userGroups) {
  return hasRole(userGroups, 'Admin') || hasRole(userGroups, 'PersonalAdministrativo');
}

/**
 * Verificar permisos para ver reportes
 */
function canViewReports(userGroups) {
  return hasRole(userGroups, 'Admin') || hasRole(userGroups, 'PersonalAdministrativo');
}

/**
 * Verificar si puede ver todos los pasillos
 */
function canViewAllCorridors(userGroups) {
  return hasRole(userGroups, 'Admin') || hasRole(userGroups, 'PersonalAdministrativo');
}

/**
 * Verificar si puede ver un pasillo específico
 */
function canViewCorridor(userGroups, userPasillo, targetPasillo) {
  // Admin y Personal Administrativo pueden ver todos
  if (canViewAllCorridors(userGroups)) {
    return true;
  }
  
  // Personal solo puede ver su pasillo asignado
  if (hasRole(userGroups, 'Personal')) {
    return userPasillo && (userPasillo === targetPasillo || userPasillo === 'all');
  }
  
  return false;
}

/**
 * Filtrar boxes según permisos del usuario
 */
function filterBoxesByPermissions(boxes, userGroups, userPasillo) {
  // Admin y Personal Administrativo ven todo
  if (canViewAllCorridors(userGroups)) {
    return boxes;
  }
  
  // Personal solo ve su pasillo asignado
  if (hasRole(userGroups, 'Personal') && userPasillo && userPasillo !== 'all') {
    return boxes.filter(box => box.idPasillo === parseInt(userPasillo));
  }
  
  return [];
}

module.exports = {
  authorize: module.exports.authorize,
  extractUserFromEvent,
  hasRole,
  isAdmin,
  canManageAgendas,
  canViewReports,
  canViewAllCorridors,
  canViewCorridor,
  filterBoxesByPermissions
};