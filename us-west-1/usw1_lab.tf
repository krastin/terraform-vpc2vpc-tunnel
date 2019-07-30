# prereqs: iam user for aws cli secrets; SSH key-pair for instances

provider "aws" {
  profile    = "default"
  region     = "us-east-1"
}

provider "aws" {
  profile = "default"
  alias = "usw1"
  region = "us-west-1"
}

resource "aws_vpc" "vpc1" {
  cidr_block = "10.100.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_vpc" "vpc2" {
  cidr_block = "10.200.0.0/16"
  provider = "aws.usw1"
  enable_dns_hostnames = true
}

/*
resource "aws_vpn_gateway" "vpc1_vpn_gw" {
  vpc_id = "${aws_vpc.vpc1.id}"
}

resource "aws_vpn_gateway" "vpc2_vpn_gw" {
  vpc_id = "${aws_vpc.vpc2.id}"
}
*/

resource "aws_internet_gateway" "gw_vpc1" {
  vpc_id = "${aws_vpc.vpc1.id}"

  tags = {
    Name = "gw_vpc1"
  }

  depends_on = ["aws_vpc.vpc1"]
}

resource "aws_internet_gateway" "gw_vpc2" {
  provider = "aws.usw1"

  vpc_id = "${aws_vpc.vpc2.id}"

  tags = {
    Name = "gw_vpc2"
  }

  depends_on = ["aws_vpc.vpc2"]
}

resource "aws_default_route_table" "vpc1_default_route_table" {
  default_route_table_id = "${aws_vpc.vpc1.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw_vpc1.id}"
  }

  tags = {
    Name = "default table"
  }
}

resource "aws_default_route_table" "vpc2_default_route_table" {
  provider = "aws.usw1"

  default_route_table_id = "${aws_vpc.vpc2.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw_vpc2.id}"
  }

  tags = {
    Name = "default table"
  }
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

resource "aws_security_group" "security_group_vpc2_allow_all" {
  provider = "aws.usw1"

  name = "allow_all"
  description = "allow all inbound and outbound traffic"

  vpc_id = "${aws_vpc.vpc2.id}"

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

resource "aws_subnet" "subnet_vpc2" {
  provider = "aws.usw1"

  vpc_id            = "${aws_vpc.vpc2.id}"
  cidr_block        = "10.200.0.0/16"
  map_public_ip_on_launch = true
  # availability_zone = "us-west-1"
  depends_on = ["aws_internet_gateway.gw_vpc2"]
}

resource "aws_network_interface" "vm_vpc1_int0" {
  subnet_id   = "${aws_subnet.subnet_vpc1.id}"
  private_ips = ["10.100.0.10"]
  security_groups = ["${aws_security_group.security_group_vpc1_allow_all.id}"]
}

resource "aws_network_interface" "vm_vpc2_int0" {
  provider = "aws.usw1"

  subnet_id   = "${aws_subnet.subnet_vpc2.id}"
  private_ips = ["10.200.0.10"]
  security_groups = ["${aws_security_group.security_group_vpc2_allow_all.id}"]
}

resource "aws_eip" "vm_vpc1_eip" {
  vpc = true

  instance                  = "${aws_instance.vm_vpc1.id}"
  associate_with_private_ip = "10.100.0.10"
  depends_on                = ["aws_internet_gateway.gw_vpc1"]
}

resource "aws_eip" "vm_vpn_vpc1_eip" {
  vpc = true

  instance                  = "${aws_instance.vm_vpn_vpc1.id}"
  associate_with_private_ip = "10.100.0.254"
  depends_on                = ["aws_internet_gateway.gw_vpc1"]
}

resource "aws_eip" "vm_vpc2_eip" {
  provider = "aws.usw1"

  vpc = true

  instance                  = "${aws_instance.vm_vpc2.id}"
  associate_with_private_ip = "10.200.0.10"
  depends_on                = ["aws_internet_gateway.gw_vpc2"]
}

resource "aws_instance" "vm_vpc1" {
  ami           = "ami-0cfee17793b08a293"
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = "${aws_network_interface.vm_vpc1_int0.id}"
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  depends_on = ["aws_internet_gateway.gw_vpc1", "aws_vpc.vpc1"]

  key_name = "default_keypair"
}

resource "aws_instance" "vm_vpn_vpc1" {
  ami = "ami-07a8d85046c8ecc99" # openvpn access server
  instance_type = "t2.micro"

  private_ip = "10.100.0.254/16"    
}


resource "aws_instance" "vm_vpc2" {
  provider = "aws.usw1"

  ami           = "ami-09eb5e8a83c7aa890"
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = "${aws_network_interface.vm_vpc2_int0.id}"
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  depends_on = ["aws_internet_gateway.gw_vpc2", "aws_vpc.vpc2"]

  key_name = "default_keypair"
}

/*
resource "aws_vpc_peering_connection" "peering_vpc1_vpc2" {
  #peer_owner_id = "${var.peer_owner_id}"
  peer_vpc_id   = "${aws_vpc.vpc2.id}"
  vpc_id        = "${aws_vpc.vpc1.id}"
  auto_accept   = true
}
*/

/*
resource "aws_vpn_gateway_route_propagation" "vpc1_route_propagation" {
  vpn_gateway_id = "${aws_vpn_gateway.vpc1_vpn_gw.id}"
  route_table_id = "${aws_route_table.vpc1_route_table.id}"
}

resource "aws_vpn_gateway_route_propagation" "vpc2_route_propagation" {
  vpn_gateway_id = "${aws_vpn_gateway.vpc2_vpn_gw.id}"
  route_table_id = "${aws_route_table.vpc2_route_table.id}"
}
*/

