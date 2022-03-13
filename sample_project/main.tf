provider "aws" {}


variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {} #Could be dev, staging or production
variable my_ip {}
variable  instance_type {}


resource "aws_vpc" "myapp-vpc" {
   cidr_block = var.vpc_cidr_block
   tags = {
       #We are going to glue variable value and string together
       #String interpolation
       Name: "${var.env_prefix}-vpc"
   }
}


resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  #AZ is indicated be 2a or 2b, etc
  tags = {
       Name: "${var.env_prefix}-subnet"
   }
}

resource "aws_internet_gateway" "myapp_igw" {
    vpc_id = aws_vpc.myapp-vpc.id

    tags = {
        Name: "${var.env_prefix}-igw"
    }
}

resource "aws_route_table" "myapp-route-table" {
    vpc_id = aws_vpc.myapp-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp_igw.id
    }

    tags = {
        Name: "${var.env_prefix}-rtb"
    }
}

resource "aws_route_table_association" "a_rtb_subnet" {
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_route_table.myapp-route-table.id
}

#We can also use default rt that came with our vpc
#Syntax is related to the one we created - with a few changes.

resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp_igw.id
    }

    tags = {
        Name: "${var.env_prefix}-main-rtb"
    }
}

resource "aws_security_group" "myapp-sg" {
    name = "myapp-sg"
    vpc_id = aws_vpc.myapp-vpc.id #assoc with sg
    
    ingress {
        from_port = 22 #port range /22 for ssh
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip] #list of ip address allowed ssh
    }

    ingress {
        from_port = 8080 #port range /8080 for server access
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] #Anyone can access from browser
    }

    egress {
        from_port = 0 #Not restricted...fetching binaries, docker, etc.
        to_port = 0
        protocol = "-1" #Any protocol
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }

    tags = {
        Name: "${var.env_prefix}-sg"
    }
}

#set dynamic ami using data
data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter { #let's you define criteria. filfeter has name and filter attributes
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
    filter { #let's you define criteria. filfeter has name and filter attributes
        name = "virtualization-type"
        values = ["hvm"]
    }
}

output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image.id
    #we can output just the id component
}

output "aws_public_ip" {
    value = aws_instance.myapp-server.public_ip
    #we can output just the id component
}

#create EC2 instance
resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id#fetch ami using data
    instance_type = var.instance_type

    subnet_id =  aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_security_group.myapp-sg.id]
    availability_zone = var.avail_zone

    associate_public_ip_address = true
    #Associate key in .ssh folder. 
    key_name = "devops-project"

    tags = {
        Name = "${var.env_prefix}-server"
    }

    user_data = <<EOF
			        #!/bin/bash
			        sudo yum update -y && sudo yum install -y docker 
                    sudo systemctl start docker
			        sudo usermod -aG docker ec2-user
			        docker run -p 8080:80 nginx
		        EOF
}