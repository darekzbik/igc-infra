terraform {
  backend "s3" {
    bucket = "zbik-state-sandbox"
    key = "infrastructure/infrastructure.tfstate"
    region = "eu-west-1"
    profile = "zbik-sandbox-state"
    encrypt = true
  }
}