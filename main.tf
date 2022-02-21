provider "aws" {
  region = var.regional 
}
variable "regional" {}
variable "vpc_cidr_block" {}
variable "Public_subnet_cidr_block" {}
variable "Private_subnet_cidr_block" {}
variable "avail_zone1" {}
variable "avail_zone2" {}
variable "env" {}

resource "aws_vpc" "Ansible_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name : "${var.env}-vpc"
  }
}
resource "aws_subnet" "Public_subnet" {
  cidr_block = var.Public_subnet_cidr_block
  tags = {
    Name : "${var.env}-pub_subnet"
  }
  vpc_id = aws_vpc.Ansible_vpc.id  
  availability_zone = var.avail_zone1
}
resource "aws_subnet" "Private_subnet" {
  cidr_block = var.Private_subnet_cidr_block
  tags = {
    Name : "${var.env}-private_subnet"
  }
  vpc_id = aws_vpc.Ansible_vpc.id  
  availability_zone = var.avail_zone2
}
resource "aws_route_table" "public_RT" {
  vpc_id = aws_vpc.Ansible_vpc.id  
  route  {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Ansible_IGW.id  
  }
}
resource "aws_route_table" "private_RT" {
  vpc_id = aws_vpc.Ansible_vpc.id  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.Ansible_NATGW.id  
  }
}
resource "aws_route_table_association" "pub_rt_ass" {
  subnet_id = aws_subnet.Public_subnet.id  
  route_table_id = aws_route_table.public_RT.id  
}
resource "aws_route_table_association" "pri_rt_ass" {
  subnet_id = aws_subnet.Private_subnet.id  
  route_table_id = aws_route_table.private_RT.id  
}
resource "aws_internet_gateway" "Ansible_IGW" {
  vpc_id = aws_vpc.Ansible_vpc.id
  tags = {
    Name : "${var.env}-IGW"
  }
}
resource "aws_nat_gateway" "Ansible_NATGW" {
  subnet_id     = aws_subnet.Public_subnet.id
  allocation_id = aws_eip.Ansible-eip.id
}
resource "aws_eip" "Ansible-eip" {
  vpc = true
  tags = {
    Name : "${var.env}-eip"
  }
}
resource "aws_instance" "Ansible_master" {
  ami             = "ami-01f87c43e618bf8f0"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.Public_subnet.id
  security_groups = [aws_security_group.public-SG.id]
  key_name        = "ansible_key_pair"
  tags = {
    Name : "${var.env}-Master"
  }
  associate_public_ip_address = true
}
resource "aws_instance" "Ansible_slave1" {
  ami             = "ami-01f87c43e618bf8f0"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.Public_subnet.id
  security_groups = [aws_security_group.public-SG.id]
  key_name        = "ansible_key_pair"
  tags = {
    Name : "${var.env}-first_slave"
  }
  associate_public_ip_address = true
}
resource "aws_instance" "Ansible_slave2" {
  ami             = "ami-01f87c43e618bf8f0"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.Private_subnet.id
  security_groups = [aws_security_group.private-SG.id]
  key_name        = "ansible_key_pair"
  tags = {
    Name : "${var.env}-second_slave"
  }
}
resource "aws_instance" "Ansible_slave3" {
  ami             = "ami-01f87c43e618bf8f0"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.Private_subnet.id
  security_groups = [aws_security_group.private-SG.id]
  key_name        = "ansible_key_pair"
  tags = {
    Name : "${var.env}-third_slave"
  }
}
resource "aws_security_group" "public-SG" {
  name        = "Allow_SSH"
  description = "allow ssh inbound traffic from the internet"
  vpc_id      = aws_vpc.Ansible_vpc.id
  ingress {
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
    Name : "${var.env}-Pub_SG"
  }
}
resource "aws_security_group" "private-SG" {
  name        = "allow ssh"
  description = "allow ssh from public subnet"
  vpc_id      = aws_vpc.Ansible_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }
  tags = {
    Name : "${var.env}-Pri_SG"
  }
}
resource "aws_launch_template" "web-servers-template" {
  name = "web-servers-template"

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 8
    }
  }

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }

  cpu_options {
    core_count       = 1
    threads_per_core = 1
  }

  credit_specification {
    cpu_credits = "standard"
  }

  disable_api_termination = true

  ebs_optimized = true

  elastic_gpu_specifications {
    type = "test"
  }

  elastic_inference_accelerator {
    type = "eia1.micro"
  }

  iam_instance_profile {
    name = "test"
  }

  image_id = "ami-test"


  instance_market_options {
    market_type = "spot"
  }

  instance_type = "t2.micro"

  kernel_id = "test"

  key_name = "test"

  license_specification {
    license_configuration_arn = "arn:aws:license-manager:eu-west-1:123456789012:license-configuration:lic-0123456789abcdef0123456789abcdef"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
  }

  placement {
    availability_zone = "us-east-1a"
  }

  ram_disk_id = "test"

  vpc_security_group_ids = [aws_security_group.public-SG.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.env}-test"
    }
  }

  user_data = filebase64("${path.module}/example.sh")
}
resource "aws_autoscaling_group" "Ansible-auto-scaling" {
  availability_zones = ["us-east-1a"]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.web-servers-template.id
      }

      override {
        instance_type     = "t2.micro"
        weighted_capacity = "3"
      }

      override {
        instance_type     = "t2.micro"
        weighted_capacity = "2"
      }
    }
  }
}