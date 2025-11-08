#!/bin/bash
# user-data.sh mejorado - descarga desde S3

set -e
set -x

# Variables
S3_BUCKET="hospital-boxes-artifacts"
APP_VERSION="v1.0.0"
APP_TAR="ProyectoHospital-${APP_VERSION}.tar.gz"

# Descargar código desde S3
echo "=== Downloading application from S3 ==="
cd /home/ubuntu
aws s3 cp s3://${S3_BUCKET}/${APP_TAR} .
tar -xzf ${APP_TAR}
rm ${APP_TAR}

# Setup virtualenv
cd ProyectoVisualizacionBoxes/ProyectoHospital
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements_serverless.txt
pip install gunicorn

# Configure Django
python manage.py collectstatic --noinput
python manage.py migrate --noinput

# Start Gunicorn with Supervisor
# ... (resto del script)
