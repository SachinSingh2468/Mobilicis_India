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
    cidr_block = "10.0.0.0/24"
    map_public_ip_on_launch = true
}
# Create Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.newvpc.id
}

# Create Route Table 
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.newvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}
# Associate route table with subnet
resource "aws_route_table_association" "my_route_table_association" {
  subnet_id      = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.my_route_table.id
}

#Creating Security Group
resource "aws_security_group" "terraform-sg" {
  name        = "SG_using_terraform"
  vpc_id      = aws_vpc.newvpc.id

  ingress {
    description      = "http"
    from_port        = 80
    to_port          = 80
    protocol         = "TCP"
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
#Creating an EC2 instance 1 & 2
resource "aws_instance" "ec2-terraform-1" {
  ami           = "ami-0aa2b7722dc1b5612"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.publicsubnet.id
  vpc_security_group_ids = [aws_security_group.terraform-sg.id]

  tags = {
    Name = "ec2-terraform-1"
  }
}
resource "aws_instance" "ec2-terraform-2" {
  ami           = "ami-0aa2b7722dc1b5612"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.publicsubnet.id
  vpc_security_group_ids = [aws_security_group.terraform-sg.id]

  tags = {
    Name = "ec2-terraform-2"
  }
}
 #Creating a load balancer
 resource "aws_elb" "terraform-lb" {
   name                  = "my-load-balancer"
   subnets               = [aws_subnet.publicsubnet.id]
   security_groups       = [aws_security_group.terraform-sg.id]
    
    listener {
        instance_port     = 80
        instance_protocol = "http"
        lb_port           = 80
        lb_protocol       = "http"
    }
 }   

 #Creating Target group
 resource "aws_lb_target_group" "my_target_gp" {
  name     = "my-target-gp"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.newvpc.id
 
 health_check {
        path = "/"
    }
}
#Attach Instances to Target Group
resource "aws_lb_target_group_attachment" "tg_attachment1" {
  target_group_arn = aws_lb_target_group.my_target_gp.arn
  target_id        = aws_instance.ec2-terraform-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tg_attachment2" {
  target_group_arn = aws_lb_target_group.my_target_gp.arn
  target_id        = aws_instance.ec2-terraform-2.id
  port             = 80
}

