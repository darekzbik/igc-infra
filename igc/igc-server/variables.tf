variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the resources will be created."
}

variable "server_config" {
  type = object({
    name         = string
    cert         = string
    key          = string
    issuer_chain = string
  })
  description = "Configuration for the IGC server including DNS name, certificate, key, and issuer chain"
}
variable "domain_zone" {
  type        = string
  description = "Route53 zone id"
}

variable "docker_ecr" {
  type = object({
    repository_url = string
    aws_region     = string
  })
  description = "Docker ECR configuration including URL and AWS region ID"
}

variable "admin_key_pair_name" {
  type        = string
  description = "The name of the key pair to use for the instance"
}

variable "admin_ssh_security_group" {
  type        = string
  description = "id of a security group allowing admin access to running host"
}

variable "subnet" {
  type = object({
    id                = string
    availability_zone = string
  })
  description = "Subnet for instance"
}

variable "users" {
  type = list(object({
    login                = string
    passord = string
  }))
  description = "collection of users"
}