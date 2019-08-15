variable "peer_region" {
  default = ""
}

variable "peer_vpc_id" {}
variable "vpc_peering" {}
variable "vpc_peering_route" {}



# Requester's side of the connection.
resource "aws_vpc_peering_connection" "krastin-req1" {
  count = "${var.vpc_peering}"
  vpc_id        = "${aws_vpc.krastin-vpc2.id}"
  peer_vpc_id   = "${var.peer_vpc_id}"
  peer_region   = "${var.peer_region}"
  auto_accept   = false

  tags = {
    Side = "Requester"
  }
}

resource "aws_route" "vpc_peering_route" {
  count = "${var.vpc_peering}"
  route_table_id         = "${aws_vpc.krastin-vpc2.default_route_table_id}"
  destination_cidr_block = "${var.vpc_peering_route}"
  gateway_id             = "${aws_vpc_peering_connection.krastin-req1.id}"
}

output "vpc-peering-id" {
  value = "${aws_vpc_peering_connection.krastin-req1.*.id}"
  description = "the id of the peering request"
}

