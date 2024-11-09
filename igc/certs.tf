resource "tls_private_key" "site_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "site_req" {
  private_key_pem = tls_private_key.site_key.private_key_pem
  subject {
    common_name  = var.dns_name
  }
  dns_names = [var.dns_name]
}

resource "acme_registration" "letsencrypt_reg" {
  account_key_pem = var.acme_account.key_pem
  email_address   = var.acme_account.email
}

resource "acme_certificate" "site_cert" {
  account_key_pem           = acme_registration.letsencrypt_reg.account_key_pem
  certificate_request_pem = tls_cert_request.site_req.cert_request_pem

  dns_challenge {
    provider = "route53"
  }
}

variable "acme_account" {
  type = object({ key_pem : string, email : string })
  description = "Let's encrypt ACME account details"
}