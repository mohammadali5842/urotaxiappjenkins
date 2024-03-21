terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket = "urotaxi-tfstate-bucket"
    region = "ap-south-1"
    key = "terraform.tfstate"
    dynamodb_table = "urotaxi-tfstate-locktable"
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "urotaxivpc" {
  cidr_block = var.urotaxivpc_cidr
  tags = {
    "Name" = "urotaxivpc"
  }
}

resource "aws_subnet" "urotaxipubsn1" {
  vpc_id = aws_vpc.urotaxivpc.id
  cidr_block = var.urotaxipubsn1_cidr
  tags = {
    "Name" = "urotaxipubsn1" 
  }
  availability_zone = "ap-south-1a"
}

resource "aws_subnet" "urotaxiprisn2" {
  vpc_id = aws_vpc.urotaxivpc.id
  cidr_block = var.urotaxiprisn2_cidr
  tags = {
    "Name" = "urotaxipubsn1" 
  }
  availability_zone = "ap-south-1a"
}

resource "aws_subnet" "urotaxiprisn3" {
  vpc_id = aws_vpc.urotaxivpc.id
  cidr_block = var.urotaxiprisn3_cidr
  tags = {
    "Name" = "urotaxipubsn1" 
  }
  availability_zone = "ap-south-1b"
}
 resource "aws_internet_gateway" "urotaxiig" {
   vpc_id = aws_vpc.urotaxivpc.id
 }

 resource "aws_route_table" "urotaxiigrt" {
    vpc_id = aws_vpc.urotaxivpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.urotaxiig.id
    }
    tags = {
      "Name" = "urotaxiigrt"
    }
 }

 resource "aws_route_table_association" "name" {
   route_table_id = aws_route_table.urotaxiigrt.id
   subnet_id = aws_subnet.urotaxipubsn1.id
 }

 resource "aws_security_group" "urotaxijavaserversg" {
   vpc_id = aws_vpc.urotaxivpc.id
   ingress {
    from_port = "22"
    to_port = "22"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   }
   egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
   }
 }

  resource "aws_security_group" "urotaxidbsg" {
   vpc_id = aws_vpc.urotaxivpc.id
   ingress {
    from_port = "3306"
    to_port = "3306"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   }
   egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
   }
 }

 resource "aws_db_subnet_group" "urotaxidbsubgroup" {
    name = "urotaxidbsubgroup"
   subnet_ids = [aws_subnet.urotaxiprisn2.id,aws_subnet.urotaxiprisn3.id]
   tags = {
     "Name" = "urotaxidbsubgroup" 
   }
 }

resource "aws_db_instance" "urotaxi_db" {
    vpc_security_group_ids = [ aws_security_group.urotaxidbsg.id ]
    allocated_storage = 10
    db_name = "urotaxi_db"
    engine = "mysql"
    engine_version = "8.0"
    instance_class = "db.t3.micro"
    username = var.db_username
    password = var.db_password
    skip_final_snapshot = true
    db_subnet_group_name = aws_db_subnet_group.urotaxidbsubgroup.name
   

}

 resource "aws_key_pair" "urotaxi_kp" {
   public_key = var.urotaxi_publickey
   key_name = "urotaxi_kp"
 }

 resource "aws_instance" "urotaxiec2" {
   vpc_security_group_ids = [aws_security_group.urotaxijavaserversg.id]
   ami = var.ami
   instance_type = var.instance_shape
   subnet_id = aws_subnet.urotaxipubsn1.id
   key_name = aws_key_pair.urotaxi_kp.key_name
   tags = {
    "Name" = "urotaxiec2"
   }
   associate_public_ip_address = "true"
 }



























