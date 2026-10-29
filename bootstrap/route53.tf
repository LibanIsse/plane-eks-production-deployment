resource "aws_route53_zone" "eks" {
  name    = "eks.libancloud.co.uk"
  comment = "DNS zone for plane"


  lifecycle {
    prevent_destroy = true
  }
}