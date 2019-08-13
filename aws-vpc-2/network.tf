resource "aws_vpc" "krastin-vpc2" {
  cidr_block = "10.200.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "krastin-vpc2"
  }

}

resource "aws_internet_gateway" "krastin-vpc2-gw1" {
  vpc_id = "${aws_vpc.krastin-vpc2.id}"

  tags = {
    Name = "krastin-vpc2-gw1"
  }
}

resource "aws_default_route_table" "krastin-vpc2-rt1" {
  default_route_table_id = "${aws_vpc.krastin-vpc2.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.krastin-vpc2-gw1.id}"
  }

  tags = {
    Name = "krastin-vpc2-rt1"
  }
}

resource "aws_security_group" "krastin-vpc2-sg-permit" {
  name = "krastin-vpc2-sg-permit"
  description = "allow all inbound and outbound traffic"

  vpc_id = "${aws_vpc.krastin-vpc2.id}"

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
    Name = "krastin-vpc2-sg-permit"
  }
}

resource "aws_subnet" "krastin-vpc2-subnet-10-200" {
  vpc_id            = "${aws_vpc.krastin-vpc2.id}"
  cidr_block        = "10.200.0.0/16"
  map_public_ip_on_launch = true
  # availability_zone = "us-east-1"

  tags = {
    Name = "krastin-vpc2-subnet-10-200"
  }
}

output "vpc_id" {
  value = "${aws_vpc.krastin-vpc2.id}"
  description = "ID of this VPC"
  sensitive = false
}
