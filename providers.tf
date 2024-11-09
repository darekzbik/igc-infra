terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.75.0"
    }

    acme = {
      source  = "vancluever/acme"
      version = "2.27.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
  #    server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
}