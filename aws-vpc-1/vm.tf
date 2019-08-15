resource "aws_instance" "krastin-vpc1-vm1" {
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = "${aws_network_interface.krastin-vpc1-nwint1.id}"
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
    Name = "krastin-vpc1-vm1"
  }
}

resource "aws_network_interface" "krastin-vpc1-nwint1" {
  subnet_id   = "${aws_subnet.krastin-vpc1-subnet-10-100.id}"
  private_ips = ["10.100.0.10"]
  security_groups = ["${aws_security_group.krastin-vpc1-sg-permit.id}"]

  depends_on = ["aws_security_group.krastin-vpc1-sg-permit", "aws_subnet.krastin-vpc1-subnet-10-100"]
}

output "vm_ssh_target" {
    value = "${aws_instance.krastin-vpc1-vm1.public_ip}"
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