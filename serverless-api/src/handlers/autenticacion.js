const AWS = require('aws-sdk');

const cognito = new AWS.CognitoIdentityServiceProvider({
  region: process.env.COGNITO_REGION
});

//Inicio de sesión de usuario
async function login(username, password) {
  const params = {
    AuthFlow: 'ADMIN_NO_SRP_AUTH',
    UserPoolId: process.env.COGNITO_USER_POOL_ID,
    ClientId: process.env.COGNITO_CLIENT_ID,
    AuthParameters: {
      USERNAME: username,
      PASSWORD: password
    }
  };

  try {
    const result = await cognito.adminInitiateAuth(params).promise();
    return {
      accessToken: result.AuthenticationResult.AccessToken,
      refreshToken: result.AuthenticationResult.RefreshToken,
      idToken: result.AuthenticationResult.IdToken
    };
  } catch (err) {
    throw new Error('Login failed: ' + err.message);
  }
}

module.exports = { login };
