terraform {
  backend "s3" {
    bucket       = "eks-iac-1-tfstate-8220"
    key          = "bootstrap/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}