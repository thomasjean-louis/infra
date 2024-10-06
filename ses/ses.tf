variable "hosted_zone_name" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

variable "region" {
  type = string
}

resource "aws_ses_configuration_set" "ses_config" {
  name                       = "config_ses"
  reputation_metrics_enabled = true
}

resource "aws_ses_domain_identity" "domain_identity" {
  domain = var.hosted_zone_name
}

resource "aws_ses_domain_dkim" "dkim_identity" {
  domain = aws_ses_domain_identity.domain_identity.domain
}

resource "aws_route53_record" "amazonses_dkim_record" {
  count   = 3
  zone_id = var.hosted_zone_id
  name    = "${aws_ses_domain_dkim.dkim_identity.dkim_tokens[count.index]}._domainkey.${aws_ses_domain_identity.domain_identity.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_ses_domain_dkim.dkim_identity.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_ses_domain_identity_verification" "domain_identity_verification" {
  domain     = aws_ses_domain_identity.domain_identity.id
  depends_on = [aws_route53_record.amazonses_dkim_record]
}

resource "aws_ses_email_identity" "email_identity" {
  email = "contact@${var.hosted_zone_name}"
}

resource "aws_ses_domain_mail_from" "mail_domain_from" {
  domain           = aws_ses_domain_identity.domain_identity.domain
  mail_from_domain = "mail.${aws_ses_domain_identity.domain_identity.domain}"
}

resource "aws_route53_record" "example_ses_domain_mail_from_mx" {
  zone_id = var.hosted_zone_id
  name    = aws_ses_domain_mail_from.mail_domain_from.mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${var.region}.amazonses.com"] # Change to the region in which `aws_ses_domain_identity.example` is created
}

resource "aws_route53_record" "example_ses_domain_mail_from_txt" {
  zone_id = var.hosted_zone_id
  name    = aws_ses_domain_mail_from.mail_domain_from.mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com ~all"]
}



