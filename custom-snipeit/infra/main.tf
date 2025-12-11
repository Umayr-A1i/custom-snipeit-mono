########################################
# AWS PROVIDER
########################################

provider "aws" {
  region = var.aws_region
}

########################################
# DATA SOURCES
########################################

# Default VPC
data "aws_vpc" "default" {
  default = true
}

# All subnets in default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Latest Ubuntu 22.04 LTS
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

########################################
# V1 DB PASSWORD FROM SECRETS MANAGER
########################################

# /custom-snipeit-v1/db_password  (JSON {"value":"..."})
data "aws_secretsmanager_secret_version" "db_password_v1" {
  secret_id = "/custom-snipeit-v1/db_password"
}

########################################
# SECURITY GROUPS (V1)
########################################

# EC2 SG (HTTP/HTTPS + SSH)
resource "aws_security_group" "snipeit_sg" {
  name        = "snipeit-ec2-sg-v1"
  description = "Allow HTTP/HTTPS + SSH for Snipe-IT V1"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name = "snipeit-sg-v1"
  }
}

# RDS SG (only EC2 can connect)
resource "aws_security_group" "snipeit_db_sg" {
  name        = "snipeit-db-sg-v1"
  description = "MySQL ingress only from EC2 SG (V1)"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "Allow MySQL from EC2 instance only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.snipeit_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "snipeit-db-sg-v1"
  }
}

########################################
# SSH KEY PAIR (V1)
########################################

resource "aws_key_pair" "snipeit_key" {
  key_name   = "umayr-dev-key-v1"
  public_key = file("${path.module}/umayr-dev-key-v1.pub")

  lifecycle {
    ignore_changes = [public_key]
  }
}

########################################
# IAM ROLE + INSTANCE PROFILE FOR EC2 (V1)
########################################

resource "aws_iam_role" "snipeit_ec2_role" {
  name = "SnipeitEc2Role-v1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# SSM managed policy so we can connect with Session Manager
resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.snipeit_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 can pull from ECR
resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.snipeit_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EC2 can read V1 secrets
resource "aws_iam_role_policy" "secrets_policy" {
  name = "SnipeitSecretsAccess-v1"
  role = aws_iam_role.snipeit_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = "arn:aws:secretsmanager:eu-west-2:448049798930:secret:/custom-snipeit-v1/*"
    }]
  })
}

resource "aws_iam_instance_profile" "snipeit_instance_profile" {
  name = "SnipeitInstanceProfile-v1"
  role = aws_iam_role.snipeit_ec2_role.name
}

########################################
# ECR REPOSITORIES FOR V1
########################################

resource "aws_ecr_repository" "snipeit" {
  name         = "snipeit-v1"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "flask_middleware" {
  name         = "flask-middleware-v1"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

########################################
# RDS SUBNET GROUP
########################################

resource "aws_db_subnet_group" "snipeit_v1" {
  name       = "snipeit-v1-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "snipeit-v1-db-subnet-group"
  }
}

########################################
# RDS MYSQL INSTANCE FOR V1
########################################

resource "aws_db_instance" "snipeit_v1" {
  identifier        = "snipeit-v1-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.rds_instance_size
  allocated_storage = 20

  db_name  = "snipeit_v1"
  username = "snipeit_v1"

  # Decode JSON from Secrets Manager and extract "value"
  password = jsondecode(data.aws_secretsmanager_secret_version.db_password_v1.secret_string)["value"]

  db_subnet_group_name   = aws_db_subnet_group.snipeit_v1.name
  vpc_security_group_ids = [aws_security_group.snipeit_db_sg.id]

  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "snipeit-v1-db"
  }
}

########################################
# EXISTING V1 ELASTIC IP (13.43.140.216)
########################################

# We REUSE the existing EIP instead of creating a new one.
data "aws_eip" "snipeit_eip" {
  public_ip = "13.43.140.216"
}

########################################
# EC2 INSTANCE
########################################

resource "aws_instance" "snipeit_ec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.snipeit_sg.id]

  iam_instance_profile = aws_iam_instance_profile.snipeit_instance_profile.name

  key_name = aws_key_pair.snipeit_key.key_name

  # Bootstrap Docker, SSM, etc.
  user_data = file("${path.module}/user_data.sh")

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name        = "snipeit-host-v1"
    Environment = "prod-v1"
    SSMTarget   = "snipeit-v1"
  }
}

########################################
# ASSOCIATE EXISTING STATIC IP TO EC2
########################################

resource "aws_eip_association" "snipeit_association" {
  instance_id   = aws_instance.snipeit_ec2.id
  allocation_id = data.aws_eip.snipeit_eip.id
}