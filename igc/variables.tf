variable "subnet" {
  type = object({
    id                = string
    availability_zone = string
  })
  description = "Subnet for instance"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the resources will be created."
}

variable "domain_zone" {
  type        = string
  description = "Route53 zone id"
}

variable "dns_name" {
  type = string
  description = "FQDN server name"
}


variable "admin_ssh_security_group" {
  type        = string
  description = "id of a security group allowing admin access to running host"
}

variable "admin_key_pair_name" {
  type        = string
  description = "The name of the key pair to use for the instance"
}