data "aws_region" "current" {}

module "igc" {
  source = "./igc-server"

  vpc_id       = var.vpc_id

  domain_zone = var.domain_zone
  server_config = {
    name         = var.dns_name
    key          = tls_private_key.site_key.private_key_pem
    cert         = acme_certificate.site_cert.certificate_pem
    issuer_chain = acme_certificate.site_cert.issuer_pem
  }

  docker_ecr = {
    repository_url = aws_ecr_repository.ecr[local.igc_ecr_name].repository_url
    aws_region     = data.aws_region.current.name
  }

  admin_key_pair_name      = var.admin_key_pair_name
  admin_ssh_security_group = var.admin_ssh_security_group
  subnet = var.subnet

  users = [
    { login = "epba", passord = "sp4114" },
    { login = "helga", passord = "SP4114" },
    { login = "helga2", passord = "SP4114" }
  ]
}