terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
  shared_config_files      = ["/Users/peterholgersson/.aws/config"]
  shared_credentials_files = ["/Users/peterholgersson/.aws/credentials"]
}

#create VPC:
resource "aws_vpc" "my-vpc"{
    cidr_block = var.cidr_blocks[0]
    tags =  {
        Name = "dev"
    }
}

#Create InternetGateway
resource "aws_internet_gateway" "internet-gw" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = "dev"
  }
}

#Create RouteTable
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.my-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gw.id
  }

  tags = {
    Name = "dev"
  }
}

#Create Public Subnet1
resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = var.cidr_blocks[1]
  availability_zone = "eu-west-1a"
  tags = {
    Name = "dev"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      =  aws_subnet.public1.id
  route_table_id =  aws_route_table.rt.id
}
#create Security Group
resource "aws_security_group" "for-web" {
  name        = "for-web"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "dev"
  }
}

#create a network interface with an ip in the subnet that was created above
resource "aws_network_interface" "nic" {
  subnet_id       = aws_subnet.public1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.for-web.id]
}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.internet-gw]
}

#create ubuntu server and install nginx
resource "aws_instance" "web" {
  ami = var.image_id
  key_name = "test2-stack"
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install nginx -y
              sudo systemctl start nginx.service
              sudo bash -c 'echo your very first web server > /var/www/html/index.html'
              EOF
  instance_type = "t2.micro"
  availability_zone = "eu-west-1a"

  network_interface {
    network_interface_id = aws_network_interface.nic.id
    device_index         = 0
  }

  tags = {
      Name = var.instance_name
  }

}






