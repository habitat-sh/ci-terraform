provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_security_group" "allow_all" {
  name        = "nshamrell-allow-all"
  description = "allow all inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9631
    to_port     = 9631
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9638
    to_port     = 9638
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9638
    to_port     = 9638
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "postgres" {
  count         = 3
  ami           = "ami-79873901"
  instance_type = "t2.micro"
  key_name      = "${var.key_name}"
  security_groups = [
    "${aws_security_group.allow_all.name}"
  ]

  provisioner "habitat" {
    peer = "${aws_instance.postgres.0.private_ip}"
    use_sudo = true
    service_type = "systemd"
    
    service {
      name = "core/postgresql"
      topology = "leader"
    }

    connection {
      host       = "${self.public_ip}"
      type       = "ssh"
      user       = "ubuntu"
      private_key = "${file("${var.key_path}")}"
    }
  }
}

output "ips" {
  value = ["${aws_instance.postgres.*.public_ip}"]
}