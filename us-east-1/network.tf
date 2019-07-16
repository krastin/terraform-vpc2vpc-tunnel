# prereqs: iam user for aws cli secrets; SSH key-pair for instances
# accept EULA for openvpn https://aws.amazon.com/marketplace/server/procurement?productId=fe8020db-5343-4c43-9e65-5ed4a825c931

# todo - fix up dependencies

provider "aws" {
  profile    = "default"
  region     = "us-east-1"
}

resource "aws_internet_gateway" "gw_vpc1" {
  vpc_id = "${aws_vpc.vpc1.id}"

  tags = {
    Name = "gw_vpc1"
  }

  depends_on = ["aws_vpc.vpc1"]
}

resource "aws_default_route_table" "vpc1_default_route_table" {
  default_route_table_id = "${aws_vpc.vpc1.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw_vpc1.id}"
  }

  route {
    cidr_block = "10.200.0.0/16"
    instance_id = "${aws_instance.vm_openvpn.id}"
  }

  tags = {
    Name = "default table"
  }

  depends_on = ["aws_vpc.vpc1", "aws_internet_gateway.gw_vpc1"]
}

resource "aws_security_group" "security_group_vpc1_allow_all" {
  name = "allow_all"
  description = "allow all inbound and outbound traffic"

  vpc_id = "${aws_vpc.vpc1.id}"

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
    Name = "allow_all"
  }
  
}

resource "aws_subnet" "subnet_vpc1" {
  vpc_id            = "${aws_vpc.vpc1.id}"
  cidr_block        = "10.100.0.0/16"
  map_public_ip_on_launch = true
  # availability_zone = "us-east-1"
  depends_on = ["aws_internet_gateway.gw_vpc1"]
}