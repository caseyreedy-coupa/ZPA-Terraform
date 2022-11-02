variable "ami" {}
variable "instance_type" {}
variable "key_name" {}
variable "vpc_id" {}
variable "subnets" {
  type    = list
  }
variable "zpa_key" {
  type    = string
  sensitive = true
}