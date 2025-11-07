#!/bin/bash
# ============================================
# EC2 User Data Script - Django Bootstrap
# ============================================
# Este script se ejecuta automáticamente al iniciar la instancia EC2
# Instala y configura el servidor Django

set -e  # Exit on error
set -x  # Debug mode

# ============================================
# VARIABLES (inyectadas por Terraform)
# ============================================
GITHUB_REPO="${github_repo_url}"
DJANGO_PORT="${django_port}"
PROJECT_NAME="${project_name}"
ENVIRONMENT="${environment}"

# ============================================
# SYSTEM UPDATE
# ============================================
echo "=== Updating system packages ==="
apt-get update -y
apt-get upgrade -y

# ============================================
# INSTALL DEPENDENCIES
# ============================================
echo "=== Installing dependencies ==="
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    nginx \
    supervisor \
    curl \
    wget

# ============================================
# CLONE REPOSITORY
# ============================================
echo "=== Cloning repository from $GITHUB_REPO ==="
cd /home/ubuntu
if [ -d "ProyectoVisualizacionBoxes" ]; then
    echo "Repository already exists, pulling latest changes"
    cd ProyectoVisualizacionBoxes
    git pull
else
    git clone $GITHUB_REPO
    cd ProyectoVisualizacionBoxes
fi

# ============================================
# PYTHON VIRTUAL ENVIRONMENT
# ============================================
echo "=== Setting up Python virtual environment ==="
cd /home/ubuntu/ProyectoVisualizacionBoxes/ProyectoHospital
python3 -m venv venv
source venv/bin/activate

# ============================================
# INSTALL PYTHON DEPENDENCIES
# ============================================
echo "=== Installing Python packages ==="
pip install --upgrade pip
pip install -r requirements_serverless.txt
pip install gunicorn  # Production WSGI server

# ============================================
# DJANGO CONFIGURATION
# ============================================
echo "=== Configuring Django ==="

# Create settings_local.py for production
cat > /home/ubuntu/ProyectoVisualizacionBoxes/ProyectoHospital/ProyectoHospital/settings_local.py << 'SETTINGS_EOF'
# Production settings
DEBUG = False
ALLOWED_HOSTS = ['*']  # Update with actual domain in production

# DynamoDB configuration (using IAM role)
DATABASES = {}  # DynamoDB no necesita configuración adicional

# Static files
STATIC_ROOT = '/home/ubuntu/ProyectoVisualizacionBoxes/ProyectoHospital/staticfiles'
STATIC_URL = '/static/'
SETTINGS_EOF

# Collect static files
python manage.py collectstatic --noinput

# Run migrations
python manage.py migrate --noinput

# ============================================
# GUNICORN CONFIGURATION
# ============================================
echo "=== Configuring Gunicorn ==="
cat > /home/ubuntu/gunicorn_config.py << 'GUNICORN_EOF'
import multiprocessing

bind = "0.0.0.0:${django_port}"
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "sync"
worker_connections = 1000
max_requests = 1000
max_requests_jitter = 50
timeout = 30
keepalive = 2
errorlog = "/var/log/gunicorn/error.log"
accesslog = "/var/log/gunicorn/access.log"
loglevel = "info"
GUNICORN_EOF

# Create log directory
mkdir -p /var/log/gunicorn
chown ubuntu:ubuntu /var/log/gunicorn

# ============================================
# SUPERVISOR CONFIGURATION
# ============================================
echo "=== Configuring Supervisor ==="
cat > /etc/supervisor/conf.d/$PROJECT_NAME.conf << SUPERVISOR_EOF
[program:$PROJECT_NAME-django]
command=/home/ubuntu/ProyectoVisualizacionBoxes/ProyectoHospital/venv/bin/gunicorn \\
    --config /home/ubuntu/gunicorn_config.py \\
    ProyectoHospital.wsgi:application
directory=/home/ubuntu/ProyectoVisualizacionBoxes/ProyectoHospital
user=ubuntu
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/$PROJECT_NAME-django.log
environment=PATH="/home/ubuntu/ProyectoVisualizacionBoxes/ProyectoHospital/venv/bin"
SUPERVISOR_EOF

# Reload supervisor
supervisorctl reread
supervisorctl update
supervisorctl start $PROJECT_NAME-django

# ============================================
# NGINX CONFIGURATION
# ============================================
echo "=== Configuring Nginx ==="
cat > /etc/nginx/sites-available/$PROJECT_NAME << NGINX_EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:${django_port};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /static/ {
        alias /home/ubuntu/ProyectoVisualizacionBoxes/ProyectoHospital/staticfiles/;
    }

    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
NGINX_EOF

# Enable site
ln -sf /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and reload nginx
nginx -t
systemctl restart nginx
systemctl enable nginx

# ============================================
# FILE PERMISSIONS
# ============================================
echo "=== Setting permissions ==="
chown -R ubuntu:ubuntu /home/ubuntu/ProyectoVisualizacionBoxes

# ============================================
# HEALTH CHECK
# ============================================
echo "=== Running health check ==="
sleep 5
curl -f http://localhost/health || echo "Health check failed, but continuing..."

# ============================================
# COMPLETION
# ============================================
echo "=== Bootstrap completed successfully ==="
echo "Django is running on port ${django_port}"
echo "Nginx is proxying on port 80"
echo "Logs: /var/log/$PROJECT_NAME-django.log"
echo "Gunicorn logs: /var/log/gunicorn/"
