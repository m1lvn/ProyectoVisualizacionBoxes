const {
  CognitoIdentityProviderClient,
  InitiateAuthCommand
} = require("@aws-sdk/client-cognito-identity-provider");

const client = new CognitoIdentityProviderClient({});

/**
 * POST /auth/login
 * Body: { "username": "email@hospital.com", "password": "Password123!" }
 * Respuesta: { idToken, accessToken, refreshToken, expiresIn }
 */
module.exports.login = async (event) => {
  try {
    const { username, password } = JSON.parse(event.body || "{}");

    if (!username || !password) {
      return response(400, { ok: false, error: "username y password son obligatorios" });
    }

    const cmd = new InitiateAuthCommand({
      AuthFlow: "USER_PASSWORD_AUTH",
      ClientId: process.env.USER_POOL_CLIENT_ID,
      AuthParameters: {
        USERNAME: username,
        PASSWORD: password
      }
    });

    const out = await client.send(cmd);

    if (out.ChallengeName) {
      // Manejo de desafíos como NEW_PASSWORD_REQUIRED
      return response(403, { ok: false, challenge: out.ChallengeName });
    }

    const auth = out.AuthenticationResult || {};
    return response(200, {
      ok: true,
      idToken: auth.IdToken,
      accessToken: auth.AccessToken,
      refreshToken: auth.RefreshToken,
      expiresIn: auth.ExpiresIn
    });
  } catch (err) {
    console.error('Login error:', err);
    return response(401, { ok: false, error: "Credenciales inválidas o usuario no confirmado" });
  }
};

/**
 * POST /auth/refresh
 * Body: { "refreshToken": "<REFRESH_TOKEN>" }
 * Respuesta: { idToken, accessToken, expiresIn }
 */
module.exports.refresh = async (event) => {
  try {
    const { refreshToken } = JSON.parse(event.body || "{}");

    if (!refreshToken) {
      return response(400, { ok: false, error: "refreshToken es obligatorio" });
    }

    const cmd = new InitiateAuthCommand({
      AuthFlow: "REFRESH_TOKEN_AUTH",
      ClientId: process.env.USER_POOL_CLIENT_ID,
      AuthParameters: {
        REFRESH_TOKEN: refreshToken
      }
    });

    const out = await client.send(cmd);
    const auth = out.AuthenticationResult || {};

    return response(200, {
      ok: true,
      idToken: auth.IdToken,
      accessToken: auth.AccessToken,
      expiresIn: auth.ExpiresIn
    });
  } catch (err) {
    console.error('Refresh error:', err);
    return response(400, { ok: false, error: "No se pudo refrescar el token" });
  }
};

/**
 * GET /me
 * Endpoint protegido que devuelve información del usuario autenticado
 */
module.exports.me = async (event) => {
  try {
    // Con JWT Authorizer nativo, las claims están en requestContext.authorizer.jwt.claims
    const claims = event?.requestContext?.authorizer?.jwt?.claims || {};
    
    return response(200, {
      ok: true,
      user: {
        id: claims.sub,
        email: claims.email,
        username: claims["cognito:username"],
        groups: claims["cognito:groups"] || [],
        hospitalId: claims["custom:hospital_id"] || 'default',
        pasilloAsignado: claims["custom:pasillo_asignado"] || null,
        givenName: claims.given_name,
        familyName: claims.family_name
      },
      rawClaims: claims // Para debugging
    });
  } catch (err) {
    console.error('Me error:', err);
    return response(500, { ok: false, error: "Error interno del servidor" });
  }
};

function response(statusCode, body) {
  return {
    statusCode,
    headers: {
      "content-type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "Content-Type,Authorization",
      "Access-Control-Allow-Methods": "GET,POST,OPTIONS"
    },
    body: JSON.stringify(body)
  };
}