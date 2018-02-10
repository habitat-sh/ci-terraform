provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_security_group" "concourse_db_sg" {
  name        = "concourse-db-allow-all"
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

  ingress {
    from_port   = 5432
    to_port     = 5432
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

resource "aws_security_group" "concourse_web_sg" {
  name        = "concourse-web-allow-all"
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

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "concourse_db" {
  ami           = "ami-79873901"
  instance_type = "t2.micro"
  key_name      = "${var.key_name}"
  security_groups = [
    "${aws_security_group.concourse_db_sg.name}"
  ]

  tags {
    Name = "concourse_db"
  }

  provisioner "habitat" {
    use_sudo = true
    service_type = "systemd"

    service {
      name = "core/postgresql"
    }

    connection {
      host       = "${self.public_ip}"
      type       = "ssh"
      user       = "ubuntu"
      private_key = "${file("${var.key_path}")}"
    }
  }
}

resource "aws_instance" "concourse_web" {
  ami           = "ami-79873901"
  instance_type = "t2.micro"
  key_name      = "${var.key_name}"
  security_groups = [
    "${aws_security_group.concourse_web_sg.name}"
  ]

  tags {
    Name = "concourse_web"
  }

  provisioner "habitat" {
    use_sudo = true
    service_type = "systemd"
    peer = "${aws_instance.concourse_db.private_ip}"

    service {
      name = "habitat/concourse-web"
      binds = ["database:postgresql.default"]
    }

    connection {
      host       = "${self.public_ip}"
      type       = "ssh"
      user       = "ubuntu"
      private_key = "${file("${var.key_path}")}"
    }
  }
}

resource "aws_instance" "concourse_worker" {
  ami           = "ami-79873901"
  instance_type = "t2.micro"
  key_name      = "${var.key_name}"
  security_groups = [
    "${aws_security_group.concourse_web_sg.name}"
  ]

  tags {
    Name = "concourse_worker"
  }

  provisioner "habitat" {
    use_sudo = true
    service_type = "systemd"
    peer = "${aws_instance.concourse_web.private_ip}"

    service {
      name = "habitat/concourse-worker"
      binds = ["web:concourse-web.default"]
    }

    connection {
      host       = "${self.public_ip}"
      type       = "ssh"
      user       = "ubuntu"
      private_key = "${file("${var.key_path}")}"
    }
  }
}