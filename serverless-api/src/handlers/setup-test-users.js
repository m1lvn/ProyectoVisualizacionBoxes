const AWS = require('aws-sdk');
const cognito = new AWS.CognitoIdentityServiceProvider();

const testUsers = [
  {
    username: 'admin@hospital.com',
    email: 'admin@hospital.com',
    givenName: 'Admin',
    familyName: 'Hospital',
    hospitalId: 'HOSPITAL_001',
    password: 'Admin123!',
    group: 'Admin'
  },
  {
    username: 'medico1@hospital.com',
    email: 'medico1@hospital.com',
    givenName: 'Dr',
    familyName: 'Martinez',
    hospitalId: 'HOSPITAL_001',
    pasilloAsignado: 'Psillo C',
    password: 'Medico123!',
    group: 'Personal'
  },
  {
    username: 'admin.staff@hospital.com',
    email: 'admin.staff@hospital.com',
    givenName: 'Ana',
    familyName: 'Garcia',
    hospitalId: 'HOSPITAL_001',
    password: 'Staff123!',
    group: 'PersonalAdministrativo'
  }
];

async function createTestUser(userPoolId, userData) {
  try {
    console.log(`Creating user: ${userData.username}`);
    
    // Preparar atributos del usuario
    const userAttributes = [
      { Name: 'email', Value: userData.email },
      { Name: 'given_name', Value: userData.givenName },
      { Name: 'family_name', Value: userData.familyName },
      { Name: 'custom:hospital_id', Value: userData.hospitalId }
    ];
    
    // Agregar pasillo asignado si existe
    if (userData.pasilloAsignado) {
      userAttributes.push({ Name: 'custom:pasillo_asignado', Value: userData.pasilloAsignado });
    }

    // Crear usuario
    await cognito.adminCreateUser({
      UserPoolId: userPoolId,
      Username: userData.username,
      UserAttributes: userAttributes,
      MessageAction: 'SUPPRESS'
    }).promise();
    
    console.log(`User ${userData.username} created successfully`);

    // Establecer contraseña permanente
    await cognito.adminSetUserPassword({
      UserPoolId: userPoolId,
      Username: userData.username,
      Password: userData.password,
      Permanent: true
    }).promise();
    
    console.log(`Password set for ${userData.username}`);

    // Agregar usuario al grupo
    await cognito.adminAddUserToGroup({
      UserPoolId: userPoolId,
      Username: userData.username,
      GroupName: userData.group
    }).promise();
    
    console.log(`User ${userData.username} added to group ${userData.group}`);
    
  } catch (error) {
    if (error.code === 'UsernameExistsException') {
      console.log(`User ${userData.username} already exists, skipping...`);
    } else {
      console.error(`Error creating user ${userData.username}:`, error);
      throw error;
    }
  }
}

async function deleteTestUser(userPoolId, username) {
  try {
    await cognito.adminDeleteUser({
      UserPoolId: userPoolId,
      Username: username
    }).promise();
    console.log(`User ${username} deleted successfully`);
  } catch (error) {
    if (error.code === 'UserNotFoundException') {
      console.log(`User ${username} not found, skipping deletion...`);
    } else {
      console.error(`Error deleting user ${username}:`, error);
    }
  }
}

exports.handler = async (event, context) => {
  console.log('CustomResource event:', JSON.stringify(event, null, 2));
  
  const response = {
    Status: 'SUCCESS',
    PhysicalResourceId: 'test-users-initializer',
    StackId: event.StackId,
    RequestId: event.RequestId,
    LogicalResourceId: event.LogicalResourceId,
    Data: {}
  };

  try {
    const userPoolId = event.ResourceProperties.UserPoolId;
    const requestType = event.RequestType;
    
    console.log(`Request type: ${requestType}`);
    console.log(`User Pool ID: ${userPoolId}`);

    if (requestType === 'Create' || requestType === 'Update') {
      // Crear usuarios de prueba
      for (const userData of testUsers) {
        await createTestUser(userPoolId, userData);
      }
      console.log('All test users created successfully');
      
    } else if (requestType === 'Delete') {
      // Limpiar usuarios de prueba al eliminar el stack
      for (const userData of testUsers) {
        await deleteTestUser(userPoolId, userData.username);
      }
      console.log('All test users deleted successfully');
    }

    response.Data.Message = `Successfully ${requestType.toLowerCase()}d test users`;
    
  } catch (error) {
    console.error('Error:', error);
    response.Status = 'FAILED';
    response.Reason = error.message;
  }

  // Enviar respuesta a CloudFormation
  await sendResponse(event, context, response);
  return response;
};

async function sendResponse(event, context, response) {
  const https = require('https');
  const url = require('url');
  
  const responseBody = JSON.stringify(response);
  const parsedUrl = url.parse(event.ResponseURL);
  
  const options = {
    hostname: parsedUrl.hostname,
    port: 443,
    path: parsedUrl.path,
    method: 'PUT',
    headers: {
      'content-type': '',
      'content-length': responseBody.length
    }
  };

  return new Promise((resolve, reject) => {
    const request = https.request(options, (res) => {
      console.log('Status code:', res.statusCode);
      resolve();
    });

    request.on('error', (error) => {
      console.error('Error sending response:', error);
      reject(error);
    });

    request.write(responseBody);
    request.end();
  });
}