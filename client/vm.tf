resource "aws_eip" "krastin-vpc-client-eip1" {
  vpc = true

  instance                  = "${aws_instance.krastin-vpc-client-vm1.id}"
  associate_with_private_ip = "10.150.0.10"
#  depends_on                = ["aws_internet_gateway.krastin-vpc-client-gw1"]

  tags = {
      Name = "krastin-vpc-client-eip1"
  }
}

resource "aws_instance" "krastin-vpc-client-vm1" {
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = "${aws_network_interface.krastin-vpc-client-nwint1.id}"
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
  }

  key_name = "krastin-key1"

  tags = {
    Name = "krastin-vpc-client-vm1"
  }
}

resource "aws_network_interface" "krastin-vpc-client-nwint1" {
  subnet_id   = "${aws_subnet.krastin-vpc-client-subnet-10-150.id}"
  private_ips = ["10.150.0.10"]
  security_groups = ["${aws_security_group.krastin-vpc-client-sg-permit.id}"]

  depends_on = ["aws_security_group.krastin-vpc-client-sg-permit", "aws_subnet.krastin-vpc-client-subnet-10-150"]
}

data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"] # Canonical
}

output "vm_eip" {
    value = "${aws_eip.krastin-vpc-client-eip1.public_ip}"
    description = "Public IP of VPN client"
    sensitive = false
}