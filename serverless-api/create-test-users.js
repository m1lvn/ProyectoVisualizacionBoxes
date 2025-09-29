/**
 * Script para crear usuarios de prueba en Amazon Cognito
 * 
 * Este script crea los usuarios de prueba necesarios para el sistema:
 * - admin@hospital.com (Admin)
 * - medico1@hospital.com (Personal)  
 * - admin.staff@hospital.com (PersonalAdministrativo)
 */

const {
  CognitoIdentityProviderClient,
  AdminCreateUserCommand,
  AdminSetUserPasswordCommand,
  AdminAddUserToGroupCommand,
  ListUserPoolsCommand,
  DescribeUserPoolCommand
} = require("@aws-sdk/client-cognito-identity-provider");

// Configuración
const client = new CognitoIdentityProviderClient({ region: 'us-east-1' });

// Usuarios de prueba a crear
const testUsers = [
  {
    email: 'admin@hospital.com',
    password: 'Hospital123!',
    group: 'Admin',
    given_name: 'Admin',
    family_name: 'Hospital',
    hospital_id: 'HOSPITAL_001'
  },
  {
    email: 'medico1@hospital.com', 
    password: 'Hospital123!',
    group: 'Personal',
    given_name: 'Doctor',
    family_name: 'Médico',
    hospital_id: 'HOSPITAL_001',
    pasillo_asignado: 'PASILLO_A'
  },
  {
    email: 'admin.staff@hospital.com',
    password: 'Hospital123!', 
    group: 'PersonalAdministrativo',
    given_name: 'Staff',
    family_name: 'Administrativo',
    hospital_id: 'HOSPITAL_001'
  }
];

async function findUserPool() {
  // Usar el User Pool ID conocido
  const userPoolId = 'us-east-1_f9rmticVD';
  const userPoolName = 'hospital-users-dev';
  
  console.log(`Usando User Pool: ${userPoolName} (${userPoolId})`);
  return userPoolId;
}

async function createUser(userPoolId, userInfo) {
  try {
    console.log(`\nCreando usuario: ${userInfo.email}`);
    
    // 1. Crear el usuario
    const createUserCommand = new AdminCreateUserCommand({
      UserPoolId: userPoolId,
      Username: userInfo.email,
      UserAttributes: [
        { Name: 'email', Value: userInfo.email },
        { Name: 'email_verified', Value: 'true' },
        { Name: 'given_name', Value: userInfo.given_name },
        { Name: 'family_name', Value: userInfo.family_name },
        { Name: 'custom:hospital_id', Value: userInfo.hospital_id }
      ].concat(userInfo.pasillo_asignado ? [
        { Name: 'custom:pasillo_asignado', Value: userInfo.pasillo_asignado }
      ] : []),
      MessageAction: 'SUPPRESS', // No enviar email de bienvenida
      TemporaryPassword: userInfo.password + '_temp'
    });
    
    const createResult = await client.send(createUserCommand);
    console.log(`✅ Usuario ${userInfo.email} creado`);
    
    // 2. Establecer contraseña permanente
    const setPasswordCommand = new AdminSetUserPasswordCommand({
      UserPoolId: userPoolId,
      Username: userInfo.email,
      Password: userInfo.password,
      Permanent: true
    });
    
    await client.send(setPasswordCommand);
    console.log(`✅ Contraseña establecida para ${userInfo.email}`);
    
    // 3. Agregar al grupo
    const addToGroupCommand = new AdminAddUserToGroupCommand({
      UserPoolId: userPoolId,
      Username: userInfo.email,
      GroupName: userInfo.group
    });
    
    await client.send(addToGroupCommand);
    console.log(`✅ Usuario ${userInfo.email} agregado al grupo ${userInfo.group}`);
    
    return true;
  } catch (error) {
    if (error.name === 'UsernameExistsException') {
      console.log(`⚠️  Usuario ${userInfo.email} ya existe`);
      return false;
    } else {
      console.error(`❌ Error creando usuario ${userInfo.email}:`, error.message);
      return false;
    }
  }
}

async function main() {
  console.log('🏥 Creando usuarios de prueba para el Hospital System');
  console.log('================================================\n');
  
  try {
    // 1. Encontrar el User Pool
    const userPoolId = await findUserPool();
    
    // 2. Crear cada usuario
    const results = [];
    for (const userInfo of testUsers) {
      const success = await createUser(userPoolId, userInfo);
      results.push({ email: userInfo.email, success });
    }
    
    // 3. Resumen final
    console.log('\n📊 RESUMEN:');
    console.log('============');
    results.forEach(result => {
      const status = result.success ? '✅ Creado' : '⚠️  Ya existía o error';
      console.log(`${result.email}: ${status}`);
    });
    
    console.log('\n🎉 Proceso completado!');
    console.log('\nUsuarios de prueba disponibles:');
    console.log('- admin@hospital.com / Hospital123! (Admin)');
    console.log('- medico1@hospital.com / Hospital123! (Personal)'); 
    console.log('- admin.staff@hospital.com / Hospital123! (PersonalAdministrativo)');
    
  } catch (error) {
    console.error('\n❌ Error ejecutando el script:', error.message);
    process.exit(1);
  }
}

// Ejecutar el script
if (require.main === module) {
  main().catch(console.error);
}

module.exports = { createUser, findUserPool };