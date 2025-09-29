/**
 * Utilidades para manejar autorización basada en JWT claims
 */

/**
 * Extraer información del usuario desde las claims JWT en HTTP API
 */
function extractUserFromEvent(event) {
  const claims = event?.requestContext?.authorizer?.jwt?.claims || {};
  
  if (!claims.sub) {
    throw new Error('No authorization context found');
  }

  return {
    userId: claims.sub,
    email: claims.email,
    username: claims['cognito:username'],
    groups: parseGroups(claims['cognito:groups']),
    hospitalId: claims['custom:hospital_id'] || 'default',
    pasilloAsignado: claims['custom:pasillo_asignado'] || null,
    givenName: claims.given_name,
    familyName: claims.family_name
  };
}

/**
 * Parsear grupos de Cognito (vienen como string)
 */
function parseGroups(groupsString) {
  if (!groupsString) return [];
  
  try {
    // Los grupos vienen como "[Admin]" o "[Admin,Personal]"
    if (typeof groupsString === 'string') {
      if (groupsString.startsWith('[') && groupsString.endsWith(']')) {
        return groupsString.slice(1, -1).split(',').map(g => g.trim());
      }
      return [groupsString];
    }
    return Array.isArray(groupsString) ? groupsString : [];
  } catch (error) {
    console.error('Error parsing groups:', error);
    return [];
  }
}

/**
 * Verificar si el usuario tiene un rol específico
 */
function hasRole(user, requiredRole) {
  return user.groups.includes(requiredRole);
}

/**
 * Verificar si el usuario es Admin
 */
function isAdmin(user) {
  return hasRole(user, 'Admin');
}

/**
 * Verificar si el usuario puede ver todos los pasillos
 */
function canViewAllCorridors(user) {
  return isAdmin(user) || hasRole(user, 'PersonalAdministrativo');
}

/**
 * Verificar si el usuario puede ver un pasillo específico
 */
function canViewCorridor(user, pasilloId) {
  // Admin y PersonalAdministrativo pueden ver todos
  if (canViewAllCorridors(user)) {
    return true;
  }
  
  // Personal solo puede ver su pasillo asignado
  if (hasRole(user, 'Personal')) {
    return user.pasilloAsignado === pasilloId;
  }
  
  return false;
}

/**
 * Verificar si el usuario puede generar reportes
 */
function canViewReports(user) {
  return isAdmin(user) || hasRole(user, 'PersonalAdministrativo');
}

/**
 * Verificar si el usuario puede crear/modificar agendas
 */
function canManageAgendas(user) {
  // Todos los roles autenticados pueden gestionar agendas
  // pero Personal solo en su pasillo asignado
  return user.groups.length > 0;
}

/**
 * Filtrar boxes basado en permisos del usuario
 */
function filterBoxesByPermissions(boxes, user) {
  if (canViewAllCorridors(user)) {
    return boxes; // Admin y PersonalAdministrativo ven todo
  }
  
  // Personal solo ve boxes de su pasillo asignado
  if (hasRole(user, 'Personal') && user.pasilloAsignado) {
    return boxes.filter(box => box.idPasillo === user.pasilloAsignado);
  }
  
  return [];
}

/**
 * Filtrar pasillos basado en permisos del usuario
 */
function filterPasillosByPermissions(pasillos, user) {
  if (canViewAllCorridors(user)) {
    return pasillos; // Admin y PersonalAdministrativo ven todo
  }
  
  // Personal solo ve su pasillo asignado
  if (hasRole(user, 'Personal') && user.pasilloAsignado) {
    return pasillos.filter(pasillo => pasillo.idPasillo === user.pasilloAsignado);
  }
  
  return [];
}

/**
 * Generar respuesta HTTP estándar
 */
function createResponse(statusCode, body, headers = {}) {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type,Authorization',
      'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
      ...headers
    },
    body: JSON.stringify(body)
  };
}

/**
 * Generar respuesta de error de autorización
 */
function createUnauthorizedResponse(message = 'No tiene permisos para acceder a este recurso') {
  return createResponse(403, {
    error: 'Forbidden',
    message
  });
}

/**
 * Generar respuesta de error de autenticación
 */
function createUnauthenticatedResponse(message = 'Se requiere autenticación') {
  return createResponse(401, {
    error: 'Unauthorized',
    message
  });
}

module.exports = {
  extractUserFromEvent,
  parseGroups,
  hasRole,
  isAdmin,
  canViewAllCorridors,
  canViewCorridor,
  canViewReports,
  canManageAgendas,
  filterBoxesByPermissions,
  filterPasillosByPermissions,
  createResponse,
  createUnauthorizedResponse,
  createUnauthenticatedResponse
};