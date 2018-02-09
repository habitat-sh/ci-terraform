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
}

resource "aws_instance" "postgres" {
  ami           = "ami-79873901"
  instance_type = "t2.micro"
  key_name      = "${var.key_name}"
  security_groups = [
    "${aws_security_group.allow_all.name}"
  ]

  provisioner "remote-exec" {
    inline = [
      "echo bite me"
    ]

    connection {
      host       = "${self.public_ip}"
      type       = "ssh"
      user       = "ubuntu"
      private_key = "${file("${var.key_path}")}"
    }
  }
}

output "ip" {
  value = ["${aws_instance.postgres.public_ip}"]
}