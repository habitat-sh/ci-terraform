variable "access_key" {}
variable "secret_key" {}
variable "region" {
    default = "us-west-2"
}
variable "key_path" {}
variable "key_name" {}
variable "ami" {}
variable "db_node_size" {}
variable "web_node_size" {}
variable "worker_node_size" {}
variable "concourse_user_name" {}
variable "concourse_user_password" {}
variable "ssl_certificate" {
  description = "File path to the public key certificate in PEM-encoded format"
}

variable "ssl_private_key" {
  description = "File path to the private key certificate in PEM-encoded format"
}

variable "ssl_cert_chain" {
  description = "File path to the site certificate chain"
}

variable "dns_zone_id" {
  description = "DNS zone id for habitat.sh (get from the Habitat AWS account)"
}