variable "hosted_zone_name" {
  type = string
}



resource "aws_route53_record" "alb_record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.hosted_zone_name
  type    = "A"
  ttl     = 300
  records = [aws_eip.lb.public_ip]
}
