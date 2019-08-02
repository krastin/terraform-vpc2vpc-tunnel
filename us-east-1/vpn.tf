variable "remote_vpn_address" {}

resource "aws_vpn_gateway" "krastin-vpc1-vpngw1" {
  vpc_id = "${aws_vpc.krastin-vpc1.id}"

  tags = {
      Name = "krastin-vpc1-vpngw1"
  }
}

resource "aws_vpn_gateway_route_propagation" "krastin-vpc1-rp1" {
  vpn_gateway_id = "${aws_vpn_gateway.krastin-vpc1-vpngw1.id}"
  route_table_id = "${aws_route_table.krastin-vpc1-rt1.id}"

  tags = {
      Name = "krastin-vpc1-rp1"
  }
}

resource "aws_customer_gateway" "krastin-vpc1-cgw1" {
  bgp_asn    = 65001
  ip_address = "${remote_vpn_address}"
  type       = "ipsec.1"

  tags = {
    Name = "krastin-vpc1-cgw1"
  }
}

/*
resource "aws_vpc_peering_connection" "peering_vpc1_vpc2" {
  #peer_owner_id = "${var.peer_owner_id}"
  peer_vpc_id   = "${aws_vpc.vpc2.id}"
  vpc_id        = "${aws_vpc.vpc1.id}"
  auto_accept   = true
}
*/