variable "secret_arns" {
  description = "Secrets Manager ARNs is permitted to read"
  type        = list(string)
}

variable "cluster_name" {
  description = "EKS cluster name for External Secrets Pod Identity"
  type        = string
}

variable "route53_zone_name" {
  description = "Public Route 53 hosted zone managed by ExternalDNS"
  type        = string
}