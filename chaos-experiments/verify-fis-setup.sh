#!/bin/bash
# ════════════════════════════════════════════════════════════════
# Verificar y preparar AWS Fault Injection Simulator (FIS)
# ════════════════════════════════════════════════════════════════

set -e

echo "════════════════════════════════════════════════════════════"
echo "   AWS FIS - VERIFICACIÓN Y PREPARACIÓN"
echo "════════════════════════════════════════════════════════════"
echo ""

REGION="us-east-1"

# ═══════════════════════════════════════════════════════════════
# 1. Verificar AWS CLI y credenciales
# ═══════════════════════════════════════════════════════════════

echo "[1/6] Verificando AWS CLI..."

if ! command -v aws &> /dev/null; then
    echo "   ❌ AWS CLI no está instalado"
    echo "   Instala con: sudo apt install awscli"
    exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "   ❌ AWS CLI no configurado"
    echo "   Ejecuta: aws configure"
    exit 1
fi

AWS_USER_ARN=$(aws sts get-caller-identity --query Arn --output text)

echo "   ✅ AWS CLI configurado"
echo "   Account: $AWS_ACCOUNT_ID"
echo "   User: $AWS_USER_ARN"

# ═══════════════════════════════════════════════════════════════
# 2. Verificar permisos IAM para FIS
# ═══════════════════════════════════════════════════════════════

echo ""
echo "[2/6] Verificando permisos IAM..."

echo "   Permisos requeridos para AWS FIS:"
echo "   - fis:CreateExperimentTemplate"
echo "   - fis:StartExperiment"
echo "   - fis:StopExperiment"
echo "   - fis:GetExperiment"
echo "   - fis:ListExperiments"

# Verificar si LabRole existe
LAB_ROLE_ARN=""

if aws iam get-role --role-name LabRole &>/dev/null; then
    LAB_ROLE_ARN=$(aws iam get-role --role-name LabRole --query 'Role.Arn' --output text)
    echo "   ✅ LabRole encontrado"
    echo "   ARN: $LAB_ROLE_ARN"
else
    echo "   ⚠️  LabRole no encontrado"
    echo "   FIS requiere un rol IAM con permisos específicos"
    echo ""
    echo "   Opciones:"
    echo "   A) Usar rol existente diferente"
    echo "   B) Saltar experimentos FIS (usar solo Bash)"
    echo ""
    
    read -p "   Selecciona opción (A/B): " option
    
    if [ "${option^^}" = "A" ]; then
        read -p "   Ingresa ARN del rol: " LAB_ROLE_ARN
    else
        echo ""
        echo "   ⚠️  Experimentos FIS no estarán disponibles"
        echo "   Puedes usar los scripts Bash como alternativa"
        LAB_ROLE_ARN=""
    fi
fi

# ═══════════════════════════════════════════════════════════════
# 3. Verificar recursos target (DynamoDB, Lambda)
# ═══════════════════════════════════════════════════════════════

echo ""
echo "[3/6] Verificando recursos target..."

# Verificar DynamoDB table
DYNAMODB_ARN=""

if aws dynamodb describe-table --table-name HospitalData --region "$REGION" &>/dev/null; then
    DYNAMODB_ARN=$(aws dynamodb describe-table \
        --table-name HospitalData \
        --region "$REGION" \
        --query 'Table.TableArn' \
        --output text)
    
    echo "   ✅ DynamoDB table 'HospitalData' encontrada"
    echo "   ARN: $DYNAMODB_ARN"
else
    echo "   ❌ DynamoDB table 'HospitalData' no encontrada"
    echo "   FIS requiere un recurso target válido"
fi

# Verificar Lambda functions
echo ""
echo "   Verificando Lambda functions..."

LAMBDA_FUNCTIONS=("getBoxes" "getAgendas" "createAgenda")
FOUND_FUNCTIONS=()

for func in "${LAMBDA_FUNCTIONS[@]}"; do
    FULL_NAME="hospital-boxes-api-dev-$func"
    
    if aws lambda get-function --function-name "$FULL_NAME" --region "$REGION" &>/dev/null; then
        LAMBDA_ARN=$(aws lambda get-function \
            --function-name "$FULL_NAME" \
            --region "$REGION" \
            --query 'Configuration.FunctionArn' \
            --output text)
        
        echo "   ✅ Lambda '$FULL_NAME' encontrada"
        FOUND_FUNCTIONS+=("$LAMBDA_ARN")
    else
        echo "   ⚠️  Lambda '$FULL_NAME' no encontrada"
    fi
done

if [ ${#FOUND_FUNCTIONS[@]} -eq 0 ]; then
    echo ""
    echo "   ⚠️  No se encontraron Lambda functions"
    echo "   Asegúrate de haber desplegado el servicio serverless"
fi

# ═══════════════════════════════════════════════════════════════
# 4. Actualizar templates FIS con ARNs reales
# ═══════════════════════════════════════════════════════════════

echo ""
echo "[4/6] Actualizando templates FIS..."

if [ -n "$DYNAMODB_ARN" ] && [ -n "$LAB_ROLE_ARN" ]; then
    # Actualizar dynamodb-throttling.json
    TEMPLATE_PATH="aws-fis/dynamodb-throttling.json"
    
    if [ -f "$TEMPLATE_PATH" ]; then
        LOG_GROUP_ARN="arn:aws:logs:${REGION}:${AWS_ACCOUNT_ID}:log-group:/aws/fis/experiments:*"
        
        python3 -c "
import json
with open('$TEMPLATE_PATH', 'r') as f:
    template = json.load(f)

template['targets']['HospitalDataTable']['resourceArns'] = ['$DYNAMODB_ARN']
template['roleArn'] = '$LAB_ROLE_ARN'
template['logConfiguration']['cloudWatchLogsConfiguration']['logGroupArn'] = '$LOG_GROUP_ARN'

with open('$TEMPLATE_PATH', 'w') as f:
    json.dump(template, f, indent=2)
"
        
        echo "   ✅ Template 'dynamodb-throttling.json' actualizado"
        echo "   - DynamoDB ARN: $DYNAMODB_ARN"
        echo "   - Role ARN: $LAB_ROLE_ARN"
    fi
    
    # Actualizar lambda-error-injection.json
    LAMBDA_TEMPLATE_PATH="aws-fis/lambda-error-injection.json"
    
    if [ -f "$LAMBDA_TEMPLATE_PATH" ] && [ ${#FOUND_FUNCTIONS[@]} -gt 0 ]; then
        TARGET_FUNC_ARN="${FOUND_FUNCTIONS[0]}"
        
        python3 -c "
import json
with open('$LAMBDA_TEMPLATE_PATH', 'r') as f:
    template = json.load(f)

template['targets']['LambdaFunctions']['resourceArns'] = ['$TARGET_FUNC_ARN']
template['roleArn'] = '$LAB_ROLE_ARN'
template['logConfiguration']['cloudWatchLogsConfiguration']['logGroupArn'] = '$LOG_GROUP_ARN'

with open('$LAMBDA_TEMPLATE_PATH', 'w') as f:
    json.dump(template, f, indent=2)
"
        
        echo "   ✅ Template 'lambda-error-injection.json' actualizado"
        echo "   - Lambda ARN: $TARGET_FUNC_ARN"
    fi
else
    echo "   ⚠️  No se pueden actualizar templates (faltan recursos)"
fi

# ═══════════════════════════════════════════════════════════════
# 5. Crear log group si no existe
# ═══════════════════════════════════════════════════════════════

echo ""
echo "[5/6] Verificando CloudWatch Log Group..."

LOG_GROUP_NAME="/aws/fis/experiments"

if aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP_NAME" --region "$REGION" &>/dev/null; then
    echo "   ✅ Log group '$LOG_GROUP_NAME' ya existe"
else
    echo "   Creando log group..."
    
    if aws logs create-log-group --log-group-name "$LOG_GROUP_NAME" --region "$REGION" 2>/dev/null; then
        echo "   ✅ Log group creado"
    else
        echo "   ⚠️  No se pudo crear log group (puede requerir permisos)"
        echo "   Los experimentos FIS pueden no guardar logs"
    fi
fi

# ═══════════════════════════════════════════════════════════════
# 6. Resumen y próximos pasos
# ═══════════════════════════════════════════════════════════════

echo ""
echo "[6/6] Resumen de verificación:"
echo ""

ALL_GOOD=true

if [ -n "$DYNAMODB_ARN" ]; then
    echo "   ✅ DynamoDB table disponible"
else
    echo "   ❌ DynamoDB table NO disponible"
    ALL_GOOD=false
fi

if [ -n "$LAB_ROLE_ARN" ]; then
    echo "   ✅ IAM Role configurado"
else
    echo "   ❌ IAM Role NO configurado"
    ALL_GOOD=false
fi

if [ ${#FOUND_FUNCTIONS[@]} -gt 0 ]; then
    echo "   ✅ Lambda functions disponibles (${#FOUND_FUNCTIONS[@]})"
else
    echo "   ⚠️  Lambda functions NO encontradas"
fi

echo ""

if [ "$ALL_GOOD" = true ]; then
    echo "════════════════════════════════════════════════════════════"
    echo "   ✅ AWS FIS LISTO PARA USAR"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "Próximos pasos:"
    echo ""
    echo "1. Crear experiment template:"
    echo "   aws fis create-experiment-template \\"
    echo "     --cli-input-json file://aws-fis/dynamodb-throttling.json \\"
    echo "     --region $REGION"
    echo ""
    echo "2. Listar templates:"
    echo "   aws fis list-experiment-templates --region $REGION"
    echo ""
    echo "3. Ejecutar experimento:"
    echo "   aws fis start-experiment \\"
    echo "     --experiment-template-id <TEMPLATE_ID> \\"
    echo "     --region $REGION"
    echo ""
    echo "O usa el script automatizado:"
    echo "   ./run-fis-experiment.sh dynamodb-throttling"
    echo ""
else
    echo "════════════════════════════════════════════════════════════"
    echo "   ⚠️  AWS FIS NO ESTÁ COMPLETAMENTE CONFIGURADO"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "Recomendación:"
    echo "   Usa los scripts Bash para experimentos de chaos"
    echo "   (No requieren permisos especiales de FIS)"
    echo ""
    echo "   cd bash-scripts"
    echo "   ./01-dos-attack.sh"
    echo ""
fi

# Guardar configuración para referencia
CONFIG_FILE="results/fis-verification-config.json"
mkdir -p results

cat > "$CONFIG_FILE" <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%d %H:%M:%S")",
  "awsAccountId": "$AWS_ACCOUNT_ID",
  "region": "$REGION",
  "dynamoDbArn": "$DYNAMODB_ARN",
  "labRoleArn": "$LAB_ROLE_ARN",
  "lambdaFunctionsCount": ${#FOUND_FUNCTIONS[@]},
  "fisReady": $ALL_GOOD
}
EOF

echo "Configuración guardada en: $CONFIG_FILE"
echo ""
