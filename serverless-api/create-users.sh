#!/bin/bash
# Script para crear usuarios de prueba en Amazon Cognito
# Ejecutar desde el entorno donde tienes AWS CLI configurado

USER_POOL_ID="us-east-1_f9rmticVD"

echo "🏥 Creando usuarios de prueba para el Hospital System"
echo "User Pool ID: $USER_POOL_ID"
echo "================================================"

# Función para crear un usuario
create_user() {
    local email=$1
    local password=$2
    local group=$3
    local given_name=$4
    local family_name=$5
    local hospital_id=$6
    local pasillo_asignado=$7
    
    echo ""
    echo "Creando usuario: $email"
    
    # Atributos base
    local attributes="Name=email,Value=$email Name=email_verified,Value=true Name=given_name,Value=$given_name Name=family_name,Value=$family_name Name=custom:hospital_id,Value=$hospital_id"
    
    # Agregar pasillo si está definido
    if [ ! -z "$pasillo_asignado" ]; then
        attributes="$attributes Name=custom:pasillo_asignado,Value=$pasillo_asignado"
    fi
    
    # 1. Crear el usuario
    aws cognito-idp admin-create-user \
        --user-pool-id $USER_POOL_ID \
        --username $email \
        --user-attributes $attributes \
        --message-action SUPPRESS \
        --temporary-password "${password}_temp" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Usuario $email creado"
    else
        echo "⚠️  Usuario $email ya existe o error en creación"
    fi
    
    # 2. Establecer contraseña permanente
    aws cognito-idp admin-set-user-password \
        --user-pool-id $USER_POOL_ID \
        --username $email \
        --password $password \
        --permanent 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Contraseña establecida para $email"
    else
        echo "⚠️  Error estableciendo contraseña para $email"
    fi
    
    # 3. Agregar al grupo
    aws cognito-idp admin-add-user-to-group \
        --user-pool-id $USER_POOL_ID \
        --username $email \
        --group-name $group 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Usuario $email agregado al grupo $group"
    else
        echo "⚠️  Error agregando $email al grupo $group"
    fi
}

# Crear los usuarios de prueba
create_user "admin@hospital.com" "Hospital123!" "Admin" "Admin" "Hospital" "HOSPITAL_001"
create_user "medico1@hospital.com" "Hospital123!" "Personal" "Doctor" "Médico" "HOSPITAL_001" "PASILLO_A"
create_user "admin.staff@hospital.com" "Hospital123!" "PersonalAdministrativo" "Staff" "Administrativo" "HOSPITAL_001"

echo ""
echo "📊 PROCESO COMPLETADO"
echo "====================="
echo "Los usuarios de prueba han sido configurados:"
echo "- admin@hospital.com / Hospital123! (Admin)"
echo "- medico1@hospital.com / Hospital123! (Personal)"
echo "- admin.staff@hospital.com / Hospital123! (PersonalAdministrativo)"
echo ""
echo "Ahora puedes probar el login con cualquiera de estos usuarios en:"
echo "http://localhost:8000"