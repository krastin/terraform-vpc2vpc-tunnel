# prereqs: iam user for aws cli secrets; SSH key-pair for instances
# accept EULA for openvpn https://aws.amazon.com/marketplace/server/procurement?productId=fe8020db-5343-4c43-9e65-5ed4a825c931

provider "aws" {
  profile    = "default"
  region     = "us-east-1"
}

resource "aws_vpc" "vpc1" {
  cidr_block = "10.100.0.0/16"
  enable_dns_hostnames = true
}

/*
resource "aws_vpn_gateway" "vpc1_vpn_gw" {
  vpc_id = "${aws_vpc.vpc1.id}"
}
*/

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

resource "aws_subnet" "subnet_vpc1" {
  vpc_id            = "${aws_vpc.vpc1.id}"
  cidr_block        = "10.100.0.0/16"
  map_public_ip_on_launch = true
  # availability_zone = "us-east-1"
  depends_on = ["aws_internet_gateway.gw_vpc1"]
}

resource "aws_network_interface" "vm_vpc1_int0" {
  subnet_id   = "${aws_subnet.subnet_vpc1.id}"
  private_ips = ["10.100.0.10"]
  security_groups = ["${aws_security_group.security_group_vpc1_allow_all.id}"]
}

resource "aws_network_interface" "vm_vpn_vpc1_int0" {
  subnet_id   = "${aws_subnet.subnet_vpc1.id}"
  private_ips = ["10.100.0.254"]
  security_groups = ["${aws_security_group.security_group_vpc1_allow_all.id}"]
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
  ami = "ami-032dce3e6d4a4f47f" # openvpn access server
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = "${aws_network_interface.vm_vpn_vpc1_int0.id}"
    device_index = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  depends_on = ["aws_internet_gateway.gw_vpc1", "aws_vpc.vpc1"]

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
*/

/*
resource "aws_customer_gateway" "customer_gw1" {
  bgp_asn    = 65001
  ip_address = "84.107.74.65"
  type       = "ipsec.1"

  tags = {
    Name = "main-customer-gateway"
  }
}
*/