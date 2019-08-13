resource "aws_vpc" "krastin-vpc-client" {
  cidr_block = "10.150.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "krastin-vpc-client"
  }

}

resource "aws_internet_gateway" "krastin-vpc-client-gw1" {
  vpc_id = "${aws_vpc.krastin-vpc-client.id}"

  tags = {
    Name = "krastin-vpc-client-gw1"
  }
}

resource "aws_default_route_table" "krastin-vpc-client-rt1" {
  default_route_table_id = "${aws_vpc.krastin-vpc-client.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.krastin-vpc-client-gw1.id}"
  }

  tags = {
    Name = "krastin-vpc-client-rt1"
  }
}

resource "aws_security_group" "krastin-vpc-client-sg-permit" {
  name = "krastin-vpc-client-sg-permit"
  description = "allow all inbound and outbound traffic"

  vpc_id = "${aws_vpc.krastin-vpc-client.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "krastin-vpc-client-sg-permit"
  }
}

resource "aws_subnet" "krastin-vpc-client-subnet-10-150" {
  vpc_id            = "${aws_vpc.krastin-vpc-client.id}"
  cidr_block        = "10.150.0.0/16"
  map_public_ip_on_launch = true
  # availability_zone = "us-east-1"

  tags = {
    Name = "krastin-vpc-client-subnet-10-150"
  }
}