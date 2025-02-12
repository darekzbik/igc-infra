# disabled to save money

# module "igc" {
#   source = "./igc"
#   acme_account = {
#     key_pem = tls_private_key.letsencrypt_account_key.private_key_pem,
#     email   = var.letsencrypt_contact_email
#   }
#   vpc_id                   = aws_vpc.vpc.id
#   subnet                   = aws_subnet.sub1
#   domain_zone              = aws_route53_zone.sp4114.zone_id
#   admin_ssh_security_group = aws_security_group.ssh_from_home.id
#   admin_key_pair_name      = aws_key_pair.admin.id
#   dns_name                 = "igc.sp4114.com"
# }