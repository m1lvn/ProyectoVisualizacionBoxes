#!/bin/bash
# Script para crear AMI personalizada con todo pre-instalado

# 1. Lanzar EC2 temporal
# 2. SSH y configurar todo manualmente
# 3. Crear AMI desde la instancia
# 4. Usar esa AMI en Terraform

# Comandos en EC2 temporal:
cd /home/ubuntu
git clone https://github.com/m1lvn/ProyectoVisualizacionBoxes.git
cd ProyectoVisualizacionBoxes/ProyectoHospital
python3 -m venv venv
source venv/bin/activate
pip install -r requirements_serverless.txt
pip install gunicorn

# Crear AMI:
# aws ec2 create-image --instance-id i-xxx --name "hospital-django-v1"

# Usar en Terraform:
# data "aws_ami" "hospital_django" {
#   owners = ["self"]
#   filter {
#     name   = "name"
#     values = ["hospital-django-v1"]
#   }
# }
