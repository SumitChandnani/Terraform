provider "aws" {
  region = "ap-south-1"
  access_key = "AKIA3PLVAPGPRRMHXZMZ"
  secret_key = "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"
}

# resource "aws_instance" "my-first-server" {
#   ami           = "ami-010aff33ed5991201"
#   instance_type = "t2.micro"

#   tags = {
#     Name = "linux server"
#   }

# }

# resource "aws_vpc" "first-vpc" {
#   cidr_block = "10.0.0.0/16"
#   tags = {
#        Name = "production"
#     }
# }

# resource "aws_subnet" "subnet1" {
#   vpc_id     = aws_vpc.first-vpc.id
#   cidr_block = "10.0.1.0/24"

#   tags = {
#     Name = "prod-subnet"
#   }
# }


resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"

    tags = {
    Name = "Production"
    }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
}

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/24"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "prod"
  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone="ap-south-1a"

  tags = {
    Name = "Prod-Subnet"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web-traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  ingress {
    description      = "HHTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}


resource "aws_instance" "web-server-instance"{
    ami = "ami-0c1a7f89451184c8b"
    instance_type = "t2.micro"
    availability_zone ="ap-south-1a"
    key_name = "main-key"

    network_interface{
        device_index=0
        network_interface_id = aws_network_interface.web-server-nic.id
    }

    user_data = <<-EOF
                #!/bin/bash/
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2 
                sudo bash -c  'echo your very first webserver > /var/www/html/index.html'
                EOF
    tags = {
        Name = "webserver"
    }

} 