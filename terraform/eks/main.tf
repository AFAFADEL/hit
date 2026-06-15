data "aws_availability_zones" "available" {}

locals {
  name = "${var.project_name}-${var.environment}-eks"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-${var.environment}-vpc"
  cidr = "10.0.0.0/16"

  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  public_subnets = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      name = "ng"

      iam_role_name            = "sockshop-dev-ng-role"
      iam_role_use_name_prefix = false

      capacity_type  = "ON_DEMAND"
      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 2
      desired_size = 2

      disk_size = 30
    }
  }

  tags = local.tags
}