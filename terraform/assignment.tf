# Configure the AWS Provider

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.0.0"
    }
  }
}

provider "aws" {
    region = "us-east-1"
}

# 1. Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "my-terraform-vpc"
  }
}

# 2. Create a Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a" # Change to an appropriate AZ in your region
  map_public_ip_on_launch = true # Instances in this subnet will get a public IP
  tags = {
    Name = "my-public-subnet"
  }
}

# 3. Create a Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b" # Change to an appropriate AZ in your region
  tags = {
    Name = "my-private-subnet"
  }
}

# 4. Create an Internet Gateway for public subnet to access internet
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my-vpc-igw"
  }
}

# 5. Create a Route Table for Public Subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# 6. Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# 7. Create a Security Group (Firewall Rules) for the web server
resource "aws_security_group" "web_server_sg" {
  name        = "web-server-security-group"
  description = "Allow HTTP/HTTPS traffic to web server"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from anywhere
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS from anywhere
  }

  # Allow SSH for management (optional but highly recommended)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Be more restrictive in production, e.g., your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-server-sg"
  }
}

# 8. Create a Compute Engine instance (EC2 instance in AWS) in the public subnet
resource "aws_instance" "web_server" {
  ami           = "ami-03ab4f7c25eca90dc" # Example: Ubuntu Server 22.04 LTS (HVM), SSD Volume Type. Find a suitable AMI for your region.
  instance_type = "t2.micro"             # Free tier eligible
  subnet_id     = aws_subnet.public_subnet.id
  associate_public_ip_address = true # Ensure it gets a public IP
  security_groups = [allow-all]
  key_name = "terraform" # Replace with an existing EC2 key pair name for SSH access

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              echo "<h1>Hello from Terraform Nginx Web Server!</h1>" | sudo tee /var/www/html/index.nginx-debian.html
              EOF

  tags = {
    Name = "my-web-server-instance"
  }
}

# Output the public IP address of the web server
output "web_server_public_ip" {
  description = "The public IP address of the web server instance"
  value       = aws_instance.web_server.public_ip
}