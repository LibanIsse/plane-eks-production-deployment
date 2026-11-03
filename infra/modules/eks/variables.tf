variable "cluster_name" {
  type    = string
  default = "plane-eks"
}

variable "cluster_version" {
  type    = string
  default = "1.36"
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}