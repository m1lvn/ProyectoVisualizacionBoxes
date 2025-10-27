@echo off
REM setup-env.bat - Helper para configurar variables de entorno para Chaos Engineering

echo ════════════════════════════════════════════════════════════════
echo 🔧 Setup de Variables de Entorno - Chaos Engineering
echo ════════════════════════════════════════════════════════════════
echo.

REM Verificar si existe .env
if not exist ".env" (
    echo ⚠️  Archivo .env no encontrado
    echo.
    echo Copiando .env.example como .env...
    copy .env.example .env >nul
    echo ✅ Archivo .env creado
    echo.
    echo 📝 Ahora debes editar .env y completar los valores faltantes
    echo.
    pause
    exit /b 0
)

echo ✅ Archivo .env encontrado
echo.

REM ════════════════════════════════════════════════════════════════
REM Detectar valores automáticamente
REM ════════════════════════════════════════════════════════════════

echo 🔍 Detectando configuración automática...
echo.

REM 1. Obtener API Endpoint desde .env.development del proyecto
if exist "..\\.env.development" (
    for /f "tokens=2 delims==" %%a in ('findstr "SERVERLESS_API_URL" "..\\.env.development"') do (
        set API_URL=%%a
        echo ✅ API Endpoint detectado: %%a
    )
) else (
    echo ⚠️  .env.development no encontrado en directorio padre
)

REM 2. Obtener AWS Account ID
echo.
echo 🔍 Obteniendo AWS Account ID...
for /f %%i in ('aws sts get-caller-identity --query Account --output text 2^>nul') do set AWS_ACCOUNT=%%i

if defined AWS_ACCOUNT (
    echo ✅ AWS Account ID: %AWS_ACCOUNT%
) else (
    echo ⚠️  No se pudo obtener AWS Account ID
    echo    Verifica que AWS CLI esté configurado: aws configure
)

REM 3. Verificar AWS credentials
echo.
echo 🔍 Verificando credenciales AWS...
aws sts get-caller-identity >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo ✅ Credenciales AWS configuradas correctamente
) else (
    echo ❌ Credenciales AWS no configuradas
    echo    Ejecuta: aws configure
    echo    O para AWS Academy, copia las credenciales temporales
)

echo.
echo ════════════════════════════════════════════════════════════════
echo 📋 Resumen de configuración actual
echo ════════════════════════════════════════════════════════════════
echo.

REM Leer valores actuales del .env
echo Variables configuradas en .env:
echo.

findstr /V "^#" .env | findstr /V "^$" | findstr "=" >nul
if %ERRORLEVEL% equ 0 (
    for /f "tokens=1,2 delims==" %%a in ('findstr /V "^#" .env ^| findstr /V "^$"') do (
        if not "%%b"=="" (
            echo   ✅ %%a = %%b
        ) else (
            echo   ⚠️  %%a = ^(vacío - necesita configuración^)
        )
    )
) else (
    echo ⚠️  No hay variables configuradas en .env
)

echo.
echo ════════════════════════════════════════════════════════════════
echo 🚀 Próximos pasos
echo ════════════════════════════════════════════════════════════════
echo.

REM Verificar qué falta configurar
set NEEDS_CONFIG=0

findstr /C:"JWT_TOKEN=" .env | findstr /V "JWT_TOKEN=." >nul
if %ERRORLEVEL% equ 0 (
    echo ⚠️  JWT_TOKEN vacío
    echo    Obtener token:
    echo    curl -X POST https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api/auth/login ^
    echo      -H "Content-Type: application/json" ^
    echo      -d "{\"username\":\"tu_usuario\",\"password\":\"tu_password\"}"
    echo.
    set NEEDS_CONFIG=1
)

findstr /C:"AWS_ACCOUNT_ID=" .env | findstr /V "AWS_ACCOUNT_ID=." >nul
if %ERRORLEVEL% equ 0 (
    if defined AWS_ACCOUNT (
        echo ✅ Auto-completando AWS_ACCOUNT_ID...
        powershell -Command "(Get-Content .env) -replace 'AWS_ACCOUNT_ID=.*', 'AWS_ACCOUNT_ID=%AWS_ACCOUNT%' | Set-Content .env"
        echo    AWS_ACCOUNT_ID = %AWS_ACCOUNT%
    ) else (
        echo ⚠️  AWS_ACCOUNT_ID vacío
        echo    Ejecuta: aws sts get-caller-identity --query Account --output text
        echo.
        set NEEDS_CONFIG=1
    )
)

if %NEEDS_CONFIG% equ 0 (
    echo ✅ Todas las variables críticas están configuradas
    echo.
    echo 📝 GREMLIN_* solo es necesario si usarás experimentos #6 y #7
) else (
    echo.
    echo 📝 Edita el archivo .env y completa las variables vacías:
    echo    notepad .env
)

echo.
echo ════════════════════════════════════════════════════════════════
echo 🎯 Para cargar variables en esta sesión de PowerShell
echo ════════════════════════════════════════════════════════════════
echo.
echo Ejecuta:
echo   Get-Content .env ^| ForEach-Object { if ($_ -match '^([^^#][^^=]+)=(.*)$') { $env:$($matches[1]) = $matches[2] } }
echo.
echo O más simple:
echo   foreach($line in Get-Content .env) { if($line -match '(.+)=(.+)') { [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2]) } }
echo.
echo ════════════════════════════════════════════════════════════════

pause
