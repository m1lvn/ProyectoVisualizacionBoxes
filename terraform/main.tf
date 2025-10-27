# --- SSH Key Pair (gestionada por Terraform) ---
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = var.ssh_key_name
  public_key = tls_private_key.ssh.public_key_openssh
}

# Guarda la clave privada en un archivo local (solo para este despliegue)
resource "local_file" "ssh_private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${pathexpand("~")}/my-ec2-key.pem"
  file_permission = "0600"
}

# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# --- Public Subnet ---
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# --- Route Table ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- Security Group: EC2 (HTTP + SSH) ---
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# --- Security Group: RDS (solo desde EC2) ---
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow MySQL from EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# --- RDS MySQL ---
resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.rds_instance_class
  # RDS requires DBName to start with a letter and contain only alphanumeric characters.
  # Sanitize `var.project_name` to remove non-alphanumeric chars so Terraform doesn't fail.
  db_name = replace(var.project_name, "/[^A-Za-z0-9]/", "")
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnets.name
  backup_retention_period = 0

  tags = {
    Name = "${var.project_name}-rds"
  }
}

### Networking improvements: private subnets + NAT gateway for proper RDS placement
# --- Private Subnets for RDS (two AZs) ---
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone = "${var.region}a"

  tags = {
    Name = "${var.project_name}-private-subnet-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  map_public_ip_on_launch = false
  availability_zone = "${var.region}b"

  tags = {
    Name = "${var.project_name}-private-subnet-b"
  }
}

# --- EIP + NAT Gateway (single NAT in public subnet) ---
resource "aws_eip" "nat" {
  # The provider does not expect the `vpc` argument in this version.
  # Allocate an Elastic IP for the NAT Gateway. The NAT gateway will use
  # the allocation id (aws_eip.nat.id) when created.
  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.project_name}-natgw"
  }
}

# --- Route table for private subnets to route via NAT ---
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# --- DB Subnet Group: use the private subnets (requirement: >=2 AZs) ---
resource "aws_db_subnet_group" "rds_subnets" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "${var.project_name}-rds-subnet-group"
  }
}

# --- EC2 Instance (Django) ---
# Use a data source to find the latest Ubuntu 22.04 AMI for the current region/owner.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "django_server" {
  ami           = data.aws_ami.ubuntu.id   # Ubuntu 22.04 (latest found by data source)
  instance_type = var.django_instance_type
  key_name      = var.ssh_key_name
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
#!/bin/bash
# Recreando instancia con clave SSH correcta - v2
apt update -y
apt install -y python3 python3-pip git

cd /home/ubuntu
git clone https://github.com/tuusuario/PROYECTOVISUALIZACIONBOXES.git
cd PROYECTOVISUALIZACIONBOXES/ProyectoHospital
pip3 install -r requirements_serverless.txt

export DB_HOST="${aws_db_instance.mysql.address}"
export DB_NAME="${replace(var.project_name, "/[^A-Za-z0-9]/", "")}"
export DB_USER="${var.db_username}"
export DB_PASSWORD="${var.db_password}"

cd /home/ubuntu/PROYECTOVISUALIZACIONBOXES/ProyectoHospital
nohup python3 manage.py runserver 0.0.0.0:8000 > django.log 2>&1 &
EOF
}

# --- SERVERLESS API (Node.js) ---
# --- SERVERLESS API (Node.js) ---
# Comentado: la API Serverless (Lambda + API Gateway) la gestionarás con Serverless Framework.
# Si en el futuro quieres llevar esto a Terraform, deberías añadir pasos de build/packaging
# (por ejemplo: archive_file, upload a S3 y usar s3_key/s3_bucket) o usar null_resource + local-exec
# para crear el zip automáticamente antes de apply.
#
# resource "aws_iam_role" "lambda_execution" {
#   name = "${var.serverless_api_name}-lambda-role"
#
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "lambda.amazonaws.com"
#         }
#       },
#     ]
#   })
# }
#
# resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
#   role       = aws_iam_role.lambda_execution.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }
#
# resource "aws_lambda_function" "api_handler" {
#   filename         = "lambda.zip"  # Debes crear este archivo manualmente o automatizarlo
#   function_name    = "${var.serverless_api_name}-handler"
#   role             = aws_iam_role.lambda_execution.arn
#   handler          = "src/index.handler"
#   runtime          = "nodejs18.x"
#   timeout          = 30
#   memory_size      = 128
#
#   environment {
#     variables = {
#       DB_HOST = aws_db_instance.mysql.address
#       DB_PORT = "3306"
#       DB_NAME = var.project_name
#       DB_USER = var.db_username
#       DB_PASSWORD = var.db_password
#     }
#   }
#
#   source_code_hash = filebase64sha256("lambda.zip")
#
#   tags = {
#     Name = "${var.serverless_api_name}-lambda"
#   }
# }
#
# resource "aws_apigatewayv2_api" "api" {
#   name          = "${var.serverless_api_name}-api"
#   protocol_type = "HTTP"
# }
#
# resource "aws_apigatewayv2_stage" "stage" {
#   api_id = aws_apigatewayv2_api.api.id
#   name   = "$default"
# }
#
# resource "aws_apigatewayv2_integration" "integration" {
#   api_id = aws_apigatewayv2_api.api.id
#   integration_type = "AWS_PROXY"
#   integration_uri = aws_lambda_function.api_handler.invoke_arn
# }
#
# resource "aws_apigatewayv2_route" "route" {
#   api_id = aws_apigatewayv2_api.api.id
#   route_key = "GET /"
#   target = "integrations/${aws_apigatewayv2_integration.integration.id}"
# }
#
# resource "aws_lambda_permission" "apigw" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.api_handler.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
# }
#