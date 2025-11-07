#!/bin/bash
# Script para diagnosticar el API Gateway deployment

echo "🔍 Diagnóstico del API Gateway"
echo "=========================================="
echo ""

# 1. Verificar stack
echo "1️⃣ Verificando stack hospital-boxes-api-dev..."
aws cloudformation describe-stacks \
    --stack-name hospital-boxes-api-dev \
    --query 'Stacks[0].[StackName,StackStatus]' \
    --output text 2>/dev/null

if [ $? -ne 0 ]; then
    echo "❌ Stack hospital-boxes-api-dev NO EXISTE"
    echo ""
    echo "📋 Stacks disponibles:"
    aws cloudformation list-stacks \
        --query 'StackSummaries[?StackStatus==`CREATE_COMPLETE` || StackStatus==`UPDATE_COMPLETE`].[StackName,StackStatus]' \
        --output table
    exit 1
fi

echo ""

# 2. Listar recursos del stack
echo "2️⃣ Recursos del stack:"
aws cloudformation describe-stack-resources \
    --stack-name hospital-boxes-api-dev \
    --query 'StackResources[?ResourceType==`AWS::ApiGatewayV2::Api`].[LogicalResourceId,ResourceType,PhysicalResourceId]' \
    --output table

echo ""

# 3. Verificar outputs
echo "3️⃣ Outputs del stack:"
aws cloudformation describe-stacks \
    --stack-name hospital-boxes-api-dev \
    --query 'Stacks[0].Outputs' \
    --output table

echo ""

# 4. Listar todos los API Gateways (HTTP APIs)
echo "4️⃣ Todos los HTTP APIs en la cuenta:"
aws apigatewayv2 get-apis \
    --query 'Items[?ProtocolType==`HTTP`].[Name,ApiId,ApiEndpoint]' \
    --output table

echo ""

# 5. Buscar APIs con nombre relacionado
echo "5️⃣ APIs con 'hospital' o 'boxes' en el nombre:"
aws apigatewayv2 get-apis \
    --query 'Items[?contains(Name, `hospital`) || contains(Name, `boxes`)].[Name,ApiId,ApiEndpoint,ProtocolType]' \
    --output table

echo ""
echo "=========================================="
echo "✅ Diagnóstico completado"
