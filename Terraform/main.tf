module "vpc" {
  source = "./modules/vpc"
}

module "eks" {
  source = "./modules/eks"

  cluster_name       = "plane-eks"
  cluster_version    = "1.36"
  private_subnet_ids = module.vpc.private_subnet_ids
}

