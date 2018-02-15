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

resource "aws_security_group" "concourse_elb_sg" {
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_elb" "concourse_elb" {
  name               = "concourse-elb"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  instances = ["${aws_instance.concourse_web.*.id}"]

  listener {
    instance_port      = 8080
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${aws_iam_server_certificate.ssl.arn}"
  }

  listener {
    instance_port      = 8080
    instance_protocol  = "http"
    lb_port            = 80
    lb_protocol        = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    target              = "HTTP:8080/"
    interval            = 30
  }

  tags {
    X-Name        = "concourse_elb"
    X-ManagedBy   = "Terraform"
  }
}

resource "aws_iam_server_certificate" "ssl" {
  name_prefix       = "concourse.acceptance.habitat.sh"
  certificate_body  = "${file("${var.ssl_certificate}")}"
  private_key       = "${file("${var.ssl_private_key}")}"
  certificate_chain = "${file("${var.ssl_cert_chain}")}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "concourse_dns" {
  zone_id = "${var.dns_zone_id}"
  name = "concourse.acceptance"
  type = "CNAME"
  ttl = 300
  records = ["${aws_elb.concourse_elb.dns_name}"]
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
    permanent_peer = true

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
    permanent_peer = true

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
    concourse_user_name = "${var.concourse_user_name}"
    concourse_user_password = "${var.concourse_user_password}"
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

output "elb_dns" {
  value = "${aws_elb.concourse_elb.dns_name}"
}
