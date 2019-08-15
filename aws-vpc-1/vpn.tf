variable "remote_vpn_address" {}
variable "remote_vpn_subnet" {}
variable "client_tunnel1_inside_cidr" {}
variable "client_tunnel2_inside_cidr" {}

resource "aws_vpn_gateway" "krastin-vpc1-vpngw1" {
  vpc_id = "${aws_vpc.krastin-vpc1.id}"

  tags = {
      Name = "krastin-vpc1-vpngw1"
  }
}

/*resource "aws_vpn_gateway_route_propagation" "krastin-vpc1-rp1" {
  vpn_gateway_id = "${aws_vpn_gateway.krastin-vpc1-vpngw1.id}"
  route_table_id = "${aws_vpc.krastin-vpc1.default_route_table_id}"
  depends_on = ["aws_vpn_gateway.krastin-vpc1-vpngw1", "aws_vpc.krastin-vpc1"]
}*/

resource "aws_route" "vpn_added_route" {
  route_table_id         = "${aws_vpc.krastin-vpc1.main_route_table_id}"
  destination_cidr_block = "${var.remote_vpn_subnet}"
  gateway_id             = "${aws_vpn_gateway.krastin-vpc1-vpngw1.id}"
}

resource "aws_customer_gateway" "krastin-vpc1-cgw1" {
  bgp_asn    = 65001
  ip_address = "${var.remote_vpn_address}"
  type       = "ipsec.1"

  tags = {
    Name = "krastin-vpc1-cgw1"
  }
}

resource "aws_vpn_connection" "krastin-vpc1-vpnconn1" {
  vpn_gateway_id      = "${aws_vpn_gateway.krastin-vpc1-vpngw1.id}"
  customer_gateway_id = "${aws_customer_gateway.krastin-vpc1-cgw1.id}"
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
      Name = "krastin-vpc1-vpnconn1"
  }

  #tunnel1_inside_cidr   = "${var.client_tunnel1_inside_cidr}"
  #tunnel2_inside_cidr   = "${var.client_tunnel2_inside_cidr}"

  depends_on = ["aws_vpn_gateway.krastin-vpc1-vpngw1"]
}

resource "aws_vpn_connection_route" "krastin-vpc1-vpnroute-10-150" {
  destination_cidr_block = "${var.remote_vpn_subnet}"
  vpn_connection_id      = "${aws_vpn_connection.krastin-vpc1-vpnconn1.id}"
}

output "vpn_configuration" {
    value = "${aws_vpn_connection.krastin-vpc1-vpnconn1.customer_gateway_configuration}"
    description = "XML configuration of VPN tunnels"
    sensitive = true
}
/*
resource "aws_vpc_peering_connection" "peering_vpc1_vpc2" {
  #peer_owner_id = "${var.peer_owner_id}"
  peer_vpc_id   = "${aws_vpc.vpc2.id}"
  vpc_id        = "${aws_vpc.vpc1.id}"
  auto_accept   = true
}
*/