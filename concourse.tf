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

resource "aws_security_group" "concourse_web_worker_sg" {
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
  ami           = "${var.ami}"
  instance_type = "${var.db_node_size}"
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
      user_toml = "${file("conf/postgres.toml")}"
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
  count         = "3"
  ami           = "${var.ami}"
  instance_type = "${var.worker_node_size}"
  key_name      = "${var.key_name}"
  security_groups = [
    "${aws_security_group.concourse_web_worker_sg.name}"
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


resource "aws_instance" "concourse_web" {
  ami           = "${var.ami}"
  instance_type = "${var.web_node_size}"
  key_name      = "${var.key_name}"
  security_groups = [
    "${aws_security_group.concourse_web_worker_sg.name}"
  ]

  tags {
    Name = "concourse_web"
  }

  provisioner "habitat" {
    use_sudo = true
    service_type = "systemd"
    peer = "${aws_instance.concourse_db.public_ip}"

    service {
      name = "habitat/concourse-web"
      binds = ["database:postgresql.default"]
      user_toml = "${data.template_file.concourse_web_toml.rendered}"
    }

    connection {
      host       = "${self.public_ip}"
      type       = "ssh"
      user       = "ubuntu"
      private_key = "${file("${var.key_path}")}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p keys/web keys/worker",
      "ssh-keygen -t rsa -f ./keys/web/tsa_host_key -N ''",
      "ssh-keygen -t rsa -f ./keys/web/session_signing_key -N ''",
      "ssh-keygen -t rsa -f ./keys/worker/worker_key -N ''",
      "cp ./keys/worker/worker_key.pub ./keys/web/authorized_worker_keys",
      "cp ./keys/web/tsa_host_key.pub ./keys/worker",
      "sudo hab file upload concourse-web.default $(date +%s) ~/keys/web/authorized_worker_keys",
      "sudo hab file upload concourse-web.default $(date +%s) ~/keys/web/session_signing_key",
      "sudo hab file upload concourse-web.default $(date +%s) ~/keys/web/session_signing_key.pub",
      "sudo hab file upload concourse-web.default $(date +%s) ~/keys/web/tsa_host_key",
      "sudo hab file upload concourse-web.default $(date +%s) ~/keys/web/tsa_host_key.pub",
      "sudo hab file upload concourse-worker.default $(date +%s) ~/keys/worker/worker_key.pub",
      "sudo hab file upload concourse-worker.default $(date +%s) ~/keys/worker/worker_key",
      "sudo hab file upload concourse-worker.default $(date +%s) ~/keys/worker/tsa_host_key.pub",
      "sudo hab stop habitat/concourse-web",
      "sudo hab start habitat/concourse-web"
    ]

    connection {
      host       = "${self.public_ip}"
      type       = "ssh"
      user       = "ubuntu"
      private_key = "${file("${var.key_path}")}"
    }
  }
}

data "template_file" "concourse_web_toml" {
  template = "${file("conf/web.toml.tpl")}"
  vars {
    db_ip = "${aws_instance.concourse_db.public_ip}"
  }
}

output "web_ip" {
  value = "${aws_instance.concourse_web.public_ip}"
}

output "db_ip" {
  value = "${aws_instance.concourse_db.public_ip}"
}

output "worker_ips" {
  value = "${aws_instance.concourse_worker.*.public_ip}"
}
