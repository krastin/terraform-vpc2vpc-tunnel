resource "aws_instance" "krastin-vpc2-vm1" {
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = "${aws_network_interface.krastin-vpc2-nwint1.id}"
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
    Name = "krastin-vpc2-vm1"
  }
}

resource "aws_network_interface" "krastin-vpc2-nwint1" {
  subnet_id   = "${aws_subnet.krastin-vpc2-subnet-10-200.id}"
  private_ips = ["10.200.0.10"]
  security_groups = ["${aws_security_group.krastin-vpc2-sg-permit.id}"]

  depends_on = ["aws_security_group.krastin-vpc2-sg-permit", "aws_subnet.krastin-vpc2-subnet-10-200"]
}

output "vm_ssh_target" {
    value = "${aws_instance.krastin-vpc2-vm1.public_ip}"
    description = "IP to SSH into for VM1"
    sensitive = false
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