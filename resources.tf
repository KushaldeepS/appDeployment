# Create a VPC for the flask application deployment
resource "aws_vpc" "app_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "app_vpc"
  }
}

# Create a public subnet within the VPC in us-east-1a availability zone with a CIDR block 
resource "aws_subnet" "app_subnet" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
      Name = "app_subnet"
    }
}

# Create an Internet Gateway for the VPC to allow internet access to the instances in the public subnet
resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "app_igw"
  }
}

# Create a route table for the public subnet to route traffic to the Internet Gateway
resource "aws_route_table" "route_table" {
    vpc_id = aws_vpc.app_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.app_igw.id
    }    
}

# Associate the route table with the public subnet to enable internet access for instances in the subnet
resource "aws_route_table_association" "rta" {
    subnet_id      = aws_subnet.app_subnet.id
    route_table_id = aws_route_table.route_table.id
}


# security group to allow HTTPS and SSH access to the instances in the public subnet
resource "aws_security_group" "app_web_sg" {
  vpc_id = aws_vpc.app_vpc.id
  name   = "app_web_sg"
  description = "Allow HTTP and SSH access"
  
  # Allow HTTPS access from within the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP access"
  }
  # Allow SSH access from within the VPC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access"
  }
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  tags = {
    Name = "app_web_sg"
  }
}

# Create a network interface in the public subnet and associate it with the security group
resource "aws_network_interface" "app_eni" {
  subnet_id       = aws_subnet.app_subnet.id
  private_ips     = ["10.0.1.10"]
  security_groups = [aws_security_group.app_web_sg.id]
  tags = {
    Name = "app_eni"
  }
  
}

# Allocate an Elastic IP and associate it with the network interface to provide a static public IP address for the instance
resource "aws_eip" "app_eip" {
  network_interface = aws_network_interface.app_eni.id
  associate_with_private_ip = "10.0.1.10"
  depends_on = [ aws_internet_gateway.app_igw ]
  tags = {
    Name = "app_eip"
  }
}


# Create an EC2 instance in the public subnet using the Amazon Linux 2 AMI and t2.micro instance type in us-east-1a availability zone with the key pair named "SSH client PuTTy" and associate it with the network interface
resource "aws_instance" "app_instance" {
  ami           = "ami-0b09ffb6d8b58ca91" # Amazon Linux 2 AMI in us-east-1
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name      = "SSH Client PuTTy"
  network_interface{
    network_interface_id = aws_network_interface.app_eni.id
    device_index         = 0
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("G:/Sazan/SSH Client PuTTy.pem")
    host        = aws_eip.app_eip.public_ip
  }

    provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ec2-user/flaskapp/templates",
    ]
  }
  # Upload the index.html file to the instance and set up a simple Flask application to serve it
  provisioner "file" {
    source      = "G:/Sazan/App Deployment/templates/index.html"
    destination = "/home/ec2-user/flaskapp/templates/index.html"
  }
  # Upload app.py to the instance to run the Flask application
  provisioner "file" {
    source      = "G:/Sazan/App Deployment/app.py"
    destination = "/home/ec2-user/flaskapp/app.py"
  }
  # Start the Flask application using python3 (app.py) in the background 
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y python3 python3-pip",
      "sudo pip3 install flask",
      "cd /home/ec2-user/flaskapp",
      "sudo python3 app.py"
    ]
  }

  tags = {
    Name = "app_instance"
  }
  
}