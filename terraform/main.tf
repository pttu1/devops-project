provider "aws" {
    region = ""
    access_key = ""
    secret_key = ""
}

#create variables . default is taken is terraform cannot file value.
#We can creatre list of strings for cidr_blocks. here, we use type=list(string)
#In terraform.tfvars cidr_blocks = ["10.0.0.0/16", 10.0.10.0/16]
#We can have lists of objects. cidr_blocks = ["10.0.0.0/16", 10.0.10.0/16]
variable "subnet_cidr_block" {
    description = "subnet cidr block"
    default = "10.0.10.0/24"
    type = string
}

variable "vpc_cidr_block" {
    description = "vpc cidr block"
}

variable "environment" {
    description = "deployment environment"
}

#create variable after setting environment variable

#Create VPC with syntax resource, resource name,
#and the name we want to give it (like variable). 
#We are going to create CIDER block (IP address range)

#We then give names to our resources using tags (which is key:value pairs)

resource "aws_vpc" "development-vpc" {
   cidr_block = "10.0.0.0/16"
   tags = {
       Name: "Development"
       vpc_env: "dev"
   }
}

#We create a subnet and identify the VPC that the subnet will be created inside
#We do that by using the resource, resource name and its id.
#There are other attrubutes like arn, etc

resource "aws_subnet" "dev-subnet-1" {
  vpc_id = aws_vpc.development-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = "us-west-2a"
  #AZ is indicated be 2a or 2b, etc
  tags = {
       Name: "Subnet-1-dev"
   }
}

#Say we want to create a subnet in an existing VPC, we can get the ID using data. 
#Data lets us query existing resources and components while 'resource' lets you create new ones
#Two times of components on aws provider.

#Say we want to create subnet in existing default vpc
data "aws_vpc" "existing-vpc"{
    default = true
}

resource "aws_subnet" "dev-subnet-2" {
    vpc_id = data.aws_vpc.existing-vpc.id
    cidr_block = "173.31.49.0/20" #check cidr block for your existing default vpc/subnets ip range that is not assigned
    availability_zone = "us-west-2b"
}

#create output using output. We destroy first using terraform destrou
#We can use $terraform plan to ensure they are unknown at the time.
#One attriibute value per output.
#We can see our outputs after we do $terraform apply. 

output "dev-vpc-id" {
    value = aws_vpc.development-vpc.id
}

output "dev-subnet-id" {
    value = aws_subnet.dev-subnet-1.id
  
}