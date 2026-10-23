module "vpc" {
  source = "./modules/vpc"
}

module "eks" {
  source = "./modules/eks"

  cluster_name       = "plane-eks"
  cluster_version    = "1.36"
  private_subnet_ids = module.vpc.private_subnet_ids
}

module "rds" {
  source = "./modules/rds"

  vpc_id                     = module.vpc.vpc_id
  database_subnet_ids        = module.vpc.database_subnet_ids
  eks_node_security_group_id = module.eks.node_security_group_id
}