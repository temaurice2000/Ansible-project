provider "aws" {
  region = "us-east-1"
}
resource "aws_vpc" "my-vpc" {
  cidr_block = "192.168.0.0/24"
  tags = {
    Name = "my-vpc"
  }
}
resource "aws_subnet" "pub-sub" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "192.168.0.0/26"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}
resource "aws_internet_gateway" "my-IGW" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = "my-igw"
  }
}
resource "aws_security_group" "public-SG" {
  description = "Allow ssh, http and jenkins"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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
}
resource "aws_route_table" "pub-RT" {
    vpc_id = aws_vpc.my-vpc.id  
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my-IGW.id  
    }
    tags = {
        Name = "pub-rt"
    }
}
resource "aws_route_table_association" "my-pub-association" {
    subnet_id = aws_subnet.pub-sub.id   
    route_table_id = aws_route_table.pub-RT.id  
}
resource "aws_instance" "Jenkins-server" {
    subnet_id = aws_subnet.pub-sub.id  
    ami = "ami-0c4f7023847b90238"
    instance_type = "t2.micro"
    associate_public_ip_address = true 
    availability_zone = "us-east-1b"
    /* cpu_core_count = "1"  */
    key_name = "lab-test-22"
    tags = {
        Name = "jenkisns_Server"
    }
}
resource "aws_ebs_volume" "new-volume" {
    availability_zone = "us-east-1b"
    size = "50"
}
resource "aws_volume_attachment" "volume-attached" {
  device_name = "/dev/sda1"
  volume_id   = aws_ebs_volume.new-volume.id
  instance_id = aws_instance.Jenkins-server.id
}
/* resource "aws_key_pair" "lab-test-22" {
    key_name = "lab-test-22"
    public_key = "---- BEGIN SSH2 PUBLIC KEY ----Comment:"imported-openssh-key"AAAAB3NzaC1yc2EAAAADAQABAAABAQC//4cHKSsKkDbXjxbMATnKVlYEjxZdJZZbqRh68cdwvGptGUcwqLbhTWymhavSx2mw7fNe0fbNywgJr0w7/fUpzdSVg9RqlGJThcg6pg+UW128xi/sOmyS6FuZOJyqHYUqm+NtBJ7plE22bndd9ZGsXf0QmC0cBHRTcPqRZ24TIV5mo70qRR+zOMqmioJ85uAbCd8rUlJh5HMeF5Mm7e4fKn6DJK/s4Yzi7KoKBHJawd/Ewd7KOdCBC/mSjCBBGdNhZYQfKtNgWp7SSD1TM0VwSlBzIiy5zVk10pEdFjIcr42cAWxaiTOspdGEvMU+I6WvXru3kLcwGoangay3dWFz---- END SSH2 PUBLIC KEY ----"
} */