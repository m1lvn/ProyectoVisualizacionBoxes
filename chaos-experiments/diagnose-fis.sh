#!/bin/bash
# Script de diagnóstico para problemas con AWS FIS

echo "════════════════════════════════════════════════════════════════"
echo "   🔍 AWS FIS - DIAGNÓSTICO COMPLETO"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Verificar AWS CLI
echo "[1/8] Verificando AWS CLI instalado..."
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1)
    echo -e "   ${GREEN}✓${NC} AWS CLI instalado: $AWS_VERSION"
else
    echo -e "   ${RED}✗${NC} AWS CLI NO instalado"
    exit 1
fi

# 2. Verificar credenciales AWS
echo ""
echo "[2/8] Verificando credenciales AWS..."
IDENTITY=$(timeout 5s aws sts get-caller-identity 2>&1)
if [ $? -eq 0 ]; then
    ACCOUNT=$(echo "$IDENTITY" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
    USER=$(echo "$IDENTITY" | grep -o '"Arn": "[^"]*"' | cut -d'"' -f4)
    echo -e "   ${GREEN}✓${NC} Credenciales configuradas"
    echo "     Account: $ACCOUNT"
    echo "     User: $USER"
else
    echo -e "   ${RED}✗${NC} Credenciales NO configuradas o timeout"
    echo "     Error: $IDENTITY"
    exit 1
fi

# 3. Verificar permisos FIS básicos
echo ""
echo "[3/8] Verificando permisos FIS (list)..."
LIST_OUTPUT=$(timeout 10s aws fis list-experiment-templates --region us-east-1 2>&1)
LIST_EXIT=$?

if [ $LIST_EXIT -eq 0 ]; then
    echo -e "   ${GREEN}✓${NC} Permiso fis:ListExperimentTemplates OK"
    TEMPLATE_COUNT=$(echo "$LIST_OUTPUT" | grep -c '"id"')
    echo "     Templates existentes: $TEMPLATE_COUNT"
elif [ $LIST_EXIT -eq 124 ]; then
    echo -e "   ${YELLOW}⚠${NC} Timeout después de 10s"
    echo "     Posible problema de red o API lenta"
else
    echo -e "   ${RED}✗${NC} Error en fis:ListExperimentTemplates"
    if echo "$LIST_OUTPUT" | grep -qi "AccessDenied\|not authorized"; then
        echo "     Sin permisos: fis:ListExperimentTemplates"
    else
        echo "     Error: $(echo "$LIST_OUTPUT" | head -n3)"
    fi
fi

# 4. Verificar archivo JSON existe
echo ""
echo "[4/8] Verificando archivos de templates..."
if [ -f "aws-fis/dynamodb-throttling.json" ]; then
    SIZE=$(wc -c < aws-fis/dynamodb-throttling.json)
    echo -e "   ${GREEN}✓${NC} dynamodb-throttling.json existe ($SIZE bytes)"
else
    echo -e "   ${RED}✗${NC} dynamodb-throttling.json NO encontrado"
fi

if [ -f "aws-fis/lambda-error-injection.json" ]; then
    SIZE=$(wc -c < aws-fis/lambda-error-injection.json)
    echo -e "   ${GREEN}✓${NC} lambda-error-injection.json existe ($SIZE bytes)"
else
    echo -e "   ${RED}✗${NC} lambda-error-injection.json NO encontrado"
fi

# 5. Validar JSON
echo ""
echo "[5/8] Validando sintaxis JSON..."
if [ -f "aws-fis/dynamodb-throttling.json" ]; then
    if python3 -m json.tool aws-fis/dynamodb-throttling.json > /dev/null 2>&1; then
        echo -e "   ${GREEN}✓${NC} dynamodb-throttling.json: JSON válido"
    else
        echo -e "   ${RED}✗${NC} dynamodb-throttling.json: JSON MALFORMADO"
        python3 -m json.tool aws-fis/dynamodb-throttling.json 2>&1 | head -n5
    fi
fi

if [ -f "aws-fis/lambda-error-injection.json" ]; then
    if python3 -m json.tool aws-fis/lambda-error-injection.json > /dev/null 2>&1; then
        echo -e "   ${GREEN}✓${NC} lambda-error-injection.json: JSON válido"
    else
        echo -e "   ${RED}✗${NC} lambda-error-injection.json: JSON MALFORMADO"
        python3 -m json.tool aws-fis/lambda-error-injection.json 2>&1 | head -n5
    fi
fi

# 6. Verificar recursos target existen
echo ""
echo "[6/8] Verificando recursos AWS (DynamoDB, Lambda)..."

# DynamoDB
TABLE_NAME="HospitalData"
if timeout 5s aws dynamodb describe-table --table-name $TABLE_NAME --region us-east-1 > /dev/null 2>&1; then
    echo -e "   ${GREEN}✓${NC} DynamoDB table '$TABLE_NAME' existe"
else
    echo -e "   ${YELLOW}⚠${NC} DynamoDB table '$TABLE_NAME' no encontrada o sin permisos"
fi

# Lambda
LAMBDA_NAME="hospital-boxes-api-dev-getBoxes"
if timeout 5s aws lambda get-function --function-name $LAMBDA_NAME --region us-east-1 > /dev/null 2>&1; then
    echo -e "   ${GREEN}✓${NC} Lambda '$LAMBDA_NAME' existe"
else
    echo -e "   ${YELLOW}⚠${NC} Lambda '$LAMBDA_NAME' no encontrada o sin permisos"
fi

# 7. Test de creación de template (DRY RUN simulado)
echo ""
echo "[7/8] Testeando creación de template (con timeout)..."
echo "     Este test intentará crear el template por 5 segundos máximo..."

if [ -f "aws-fis/dynamodb-throttling.json" ]; then
    echo "     Ejecutando: aws fis create-experiment-template..."
    
    START=$(date +%s)
    CREATE_OUTPUT=$(timeout 5s aws fis create-experiment-template \
        --cli-input-json file://aws-fis/dynamodb-throttling.json \
        --region us-east-1 2>&1)
    CREATE_EXIT=$?
    END=$(date +%s)
    ELAPSED=$((END - START))
    
    echo "     Tiempo transcurrido: ${ELAPSED}s"
    echo "     Exit code: $CREATE_EXIT"
    
    if [ $CREATE_EXIT -eq 0 ]; then
        echo -e "   ${GREEN}✓${NC} Template creado exitosamente"
        TEMPLATE_ID=$(echo "$CREATE_OUTPUT" | grep -o '"id": "[^"]*"' | cut -d'"' -f4 | head -n1)
        echo "     Template ID: $TEMPLATE_ID"
        
        # Cleanup - eliminar template de prueba
        echo "     Limpiando template de prueba..."
        aws fis delete-experiment-template --id "$TEMPLATE_ID" --region us-east-1 > /dev/null 2>&1
        
    elif [ $CREATE_EXIT -eq 124 ]; then
        echo -e "   ${RED}✗${NC} TIMEOUT después de 5s"
        echo "     ⚠️  El comando se colgó - Este es el problema"
        echo ""
        echo "     Causas posibles:"
        echo "     1. AWS CLI esperando permisos sin error explícito"
        echo "     2. Problema de red/latencia con AWS API"
        echo "     3. Bug en AWS CLI o boto3"
        
    else
        echo -e "   ${RED}✗${NC} Error al crear template"
        echo ""
        echo "     Output del error:"
        echo "$CREATE_OUTPUT" | head -n10 | sed 's/^/     /'
        
        # Analizar tipo de error
        if echo "$CREATE_OUTPUT" | grep -qi "AccessDenied\|not authorized"; then
            echo ""
            echo -e "   ${YELLOW}⚠${NC} DIAGNÓSTICO: Sin permisos FIS"
            echo "     Tu usuario no tiene: fis:CreateExperimentTemplate"
            echo "     Usuario actual: $USER"
            
        elif echo "$CREATE_OUTPUT" | grep -qi "ValidationException"; then
            echo ""
            echo -e "   ${YELLOW}⚠${NC} DIAGNÓSTICO: Error de validación en template"
            echo "     Revisa los ARNs en: aws-fis/dynamodb-throttling.json"
            
        elif echo "$CREATE_OUTPUT" | grep -qi "ResourceNotFoundException"; then
            echo ""
            echo -e "   ${YELLOW}⚠${NC} DIAGNÓSTICO: Recursos no encontrados"
            echo "     DynamoDB o Lambda especificados no existen"
        fi
    fi
fi

# 8. Resumen y recomendaciones
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "   📊 RESUMEN Y RECOMENDACIONES"
echo "════════════════════════════════════════════════════════════════"
echo ""

if [ $CREATE_EXIT -eq 0 ]; then
    echo -e "${GREEN}✅ TODO FUNCIONANDO${NC}"
    echo "   Puedes ejecutar: ./run-all-chaos-experiments.sh"
    
elif [ $CREATE_EXIT -eq 124 ]; then
    echo -e "${RED}❌ PROBLEMA IDENTIFICADO: TIMEOUT${NC}"
    echo ""
    echo "El comando 'aws fis create-experiment-template' se cuelga."
    echo ""
    echo "SOLUCIONES:"
    echo ""
    echo "1. Ejecutar solo experimentos Bash (RECOMENDADO):"
    echo "   ./run-all-chaos-experiments.sh --skip-fis"
    echo ""
    echo "2. Verificar permisos IAM en AWS Console:"
    echo "   - Ve a IAM → Roles → LabRole"
    echo "   - Busca políticas con 'FIS' o 'Fault Injection'"
    echo "   - Asegúrate de tener: fis:CreateExperimentTemplate"
    echo ""
    echo "3. Probar desde AWS Console (manual):"
    echo "   - Ve a: https://console.aws.amazon.com/fis"
    echo "   - Intenta crear un template manualmente"
    echo ""
    
else
    echo -e "${YELLOW}⚠️  PROBLEMA CON PERMISOS O CONFIGURACIÓN${NC}"
    echo ""
    echo "SOLUCIONES:"
    echo ""
    echo "1. Ejecutar sin FIS (funciona sin permisos especiales):"
    echo "   ./run-all-chaos-experiments.sh --skip-fis"
    echo ""
    echo "2. Si necesitas permisos FIS:"
    echo "   - Contacta al administrador de AWS"
    echo "   - Solicita agregar política: AWSFaultInjectionSimulatorFullAccess"
    echo "   - O permisos específicos: fis:*"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "   Diagnóstico completado"
echo "════════════════════════════════════════════════════════════════"
