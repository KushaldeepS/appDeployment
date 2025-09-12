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
