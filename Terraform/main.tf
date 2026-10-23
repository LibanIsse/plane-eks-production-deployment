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

module "elasticache" {
  source = "./modules/elasticache"

  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  eks_node_security_group_id = module.eks.node_security_group_id
}

module "amazon_mq" {
  source                     = "./modules/amazon-mq"
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  eks_node_security_group_id = module.eks.node_security_group_id
}

module "s3" {
  source = "./modules/s3"

  cluster_name = "plane-eks"
}

module "iam" {
  source = "./modules/iam"

  cluster_name = "plane-eks"

  secret_arns = [
    module.rds.master_user_secret_arn,
    module.amazon_mq.secret_arn
  ]
}








