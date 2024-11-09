resource "tls_private_key" "letsencrypt_account_key" {
  algorithm   = "RSA"
  rsa_bits  = 4096
}

resource "acme_registration" "letsencrypt_reg" {
  account_key_pem = tls_private_key.letsencrypt_account_key.private_key_pem
  email_address   = var.letsencrypt_contact_email
}

variable "letsencrypt_contact_email" {
  type = string
  description = "contact email used for letsencrypt account"
}
