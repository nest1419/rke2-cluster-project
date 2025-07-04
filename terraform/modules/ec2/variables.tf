variable "ami_id" {
  type = string
}

variable "instance_master" {
  type = string
}

variable "instance_workers" {
  type = string
}

variable "instance_micro" {
  type = string
}
variable "key_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ssh_ingress_cidr" {
  type = string
}

variable "aws_region" {
  type = string
}
