terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "your-tf-state-bucket"
    key    = "custom-snipeit/terraform.tfstate"
    region = "eu-west-2"
  }
}

provider "aws" {
  region = var.aws_region
}

# -----------------------------
# DATA SOURCES
# -----------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }
}

# -----------------------------
# SECURITY GROUP
# -----------------------------
resource "aws_security_group" "snipeit_sg" {
  name        = "snipeit-ec2-sg"
  description = "Allow HTTP/HTTPS"
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "snipeit-sg"
  }
}

# -----------------------------
# IAM ROLE FOR EC2 + SSM + ECR PULL
# -----------------------------
resource "aws_iam_role" "snipeit_ec2_role" {
  name = "SnipeitEc2Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.snipeit_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.snipeit_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "snipeit_instance_profile" {
  name = "SnipeitInstanceProfile"
  role = aws_iam_role.snipeit_ec2_role.name
}

# -----------------------------
# ECR REPOSITORIES
# -----------------------------
resource "aws_ecr_repository" "snipeit" {
  name = "snipeit"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "snipeit"
  }
}

resource "aws_ecr_repository" "flask_middleware" {
  name = "flask-middleware"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "flask-middleware"
  }
}

# -----------------------------
# EC2 STATIC IP (Elastic IP)
# -----------------------------
resource "aws_eip" "snipeit_eip" {
  domain = "vpc"

  tags = {
    Name = "snipeit-static-ip"
  }
}

# -----------------------------
# EC2 INSTANCE
# -----------------------------
resource "aws_instance" "snipeit_ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id     = data.aws_subnets.default.ids[0]

  vpc_security_group_ids = [aws_security_group.snipeit_sg.id]

  iam_instance_profile = aws_iam_instance_profile.snipeit_instance_profile.name

  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name        = "snipeit-host"
    Environment = "prod"
    SSMTarget   = "snipeit"
  }
}

# -----------------------------
# ASSOCIATE STATIC IP TO EC2
# -----------------------------
resource "aws_eip_association" "snipeit_eip_assoc" {
  allocation_id = aws_eip.snipeit_eip.id
  instance_id   = aws_instance.snipeit_ec2.id
}
