#Creating a VPC
resource "aws_vpc" "newvpc"{
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "myVPC"
    }
}
#Creating a Subnet
resource "aws_subnet" "publicsubnet"{
    vpc_id = aws_vpc.newvpc.id
    availability_zone = "us-east-1a"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
}
#Creating Security Group
resource "aws_security_group" "terraform-sg" {
  name        = "SG_using_terraform"
  description = "SG created by terraform script"
  vpc_id      = aws_vpc.newvpc.id

  ingress {
    description      = "http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "https"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "terraform-sg"
  }
}
#Creating an EC2 instance
resource "aws_instance" "ec2-terraform" {
  ami           = "ami-0aa2b7722dc1b5612"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.publicsubnet.id
  vpc_security_group_ids = [aws_security_group.terraform-sg.id]
  count = 2

  tags = {
    Name = "Terraform ec2"
  }
}
 #Creating a load balancer
 resource "aws_elb" "terraform-elb" {
   name            = "classic-load-balancer"
   subnets         = [aws_subnet.publicsubnet.id]
   security_groups = [aws_security_group.terraform-sg.id]
listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 8000
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
  }
  tags = {
    Name = "terraform-elb"
  }
 }
