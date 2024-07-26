# VPC
resource "aws_vpc" "default" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.project}-vpc",
    
  }
}

# Creating Public subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr_blocks)
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

   tags = {
    Name = "${var.project}-pub-subnet-${var.availability_zones[count.index]}"

  }
}
# Creating Private subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr_blocks)
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = var.availability_zones[count.index]
    tags = {
    Name = "${var.project}-priv-subnet-${var.availability_zones[count.index]}"

  }
}

# Creating internet gateway for accesing to internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.default.id
  tags =  {
   Name = "${var.project}-igw"

  }
}
# create route table with a record to internet incase of 0.0.0.0
resource "aws_route_table" "public-rt" {
 vpc_id = aws_vpc.default.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.igw.id
 }
 
 tags = {
   Name = "${var.project}-public-rt"
 }
}


resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "default" {
  depends_on = [aws_internet_gateway.igw]
  allocation_id = aws_eip.nat.id
  # Launching aws nat gateway in public subnet
  subnet_id     = aws_subnet.public[1].id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.default.id
   tags = {
  #  Name = "nat-gateway-rt"
   Name = "${var.project}-nat-gateway-rt"

 }
}
resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.default.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidr_blocks)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr_blocks)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public-rt.id
}



resource "aws_security_group" "security_group" {
 name   = "ecs-security-group"
 vpc_id = aws_vpc.default.id

 ingress {
   from_port   = 0
   to_port     = 0
   protocol    = -1
   self        = "false"
   cidr_blocks = ["0.0.0.0/0"]
   description = "any"
 }

 egress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}


resource "aws_efs_file_system" "fs" {
  creation_token = "my-product"

  tags = {
    Name = "MyProduct"
  }
  
}

resource "aws_efs_mount_target" "ecs_temp_space_az0" {
  file_system_id = aws_efs_file_system.fs.id
  subnet_id      = aws_subnet.private[0].id
  security_groups = [aws_security_group.security_group.id]
}


resource "aws_efs_mount_target" "ecs_temp_space_az1" {
  file_system_id = aws_efs_file_system.fs.id
  subnet_id      = aws_subnet.private[1].id
  security_groups = [aws_security_group.security_group.id]
}