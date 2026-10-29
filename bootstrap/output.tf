output "eks_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.eks.zone_id
}

output "eks_name_servers" {
  description = "Route 53 nameservers for Cloudflare delegation"
  value       = aws_route53_zone.eks.name_servers
}