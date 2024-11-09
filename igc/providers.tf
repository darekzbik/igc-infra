terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.75.0"
    }

    acme = {
      source  = "vancluever/acme"
      version = ">=2.27.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">=4.0.6"
    }
  }
}