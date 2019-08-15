variable "vpc_peering" {
    default = 0
}

variable "vpc_peering_connection_id" {}
variable "vpc_peering_route" {}


resource "aws_vpc_peering_connection_accepter" "peer" {
  count = "${var.vpc_peering}"
  vpc_peering_connection_id = "${var.vpc_peering_connection_id}"
  auto_accept = true

  tags = {
    Side = "Accepter"
  }
}

resource "aws_route" "vpc_peering_route" {
  count = "${var.vpc_peering}"
  route_table_id         = "${aws_vpc.krastin-vpc1.main_route_table_id}"
  destination_cidr_block = "${var.vpc_peering_route}"
  gateway_id             = "${var.vpc_peering_connection_id}"
}