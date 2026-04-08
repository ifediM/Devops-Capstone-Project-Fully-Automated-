locals {
  region       = var.region
  project_name = var.project_name
  environment  = var.environment
}

module "vpc" {
  source                      = "git::https://github.com/ifediM/Terraform--EKS-Infrastructure.git//vpc"
  region                      = local.region
  project_name                = local.project_name
  environment                 = local.environment
  vpc_cidr                    = var.vpc_cidr
  public_subnet_az1_cidr      = var.public_subnet_az1_cidr
  public_subnet_az2_cidr      = var.public_subnet_az2_cidr
  private_app_subnet_az1_cidr = var.private_app_subnet_az1_cidr
  private_app_subnet_az2_cidr = var.private_app_subnet_az2_cidr
}

# Create Nat-gateways
module "nat-gateway" {
  source                    = "git::https://github.com/ifediM/Terraform--EKS-Infrastructure.git//nat-gateway"
  project_name              = local.project_name
  environment               = local.environment
  public_subnet_az1_id      = module.vpc.public_subnet_az1_id
  internet_gateway          = module.vpc.internet_gateway
  vpc_id                    = module.vpc.vpc_id
  private_app_subnet_az1_id = module.vpc.private_app_subnet_az1_id
  private_app_subnet_az2_id = module.vpc.private_app_subnet_az2_id
}

#Create Security-group
module "security-group" {
  source       = "git::https://github.com/ifediM/Terraform--EKS-Infrastructure.git//security-group"
  project_name = local.project_name
  environment  = local.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = module.vpc.vpc_cidr
}



#Request SSL Certificate
module "ssl_certificate" {
  source            = "git::https://github.com/ifediM/Terraform--EKS-Infrastructure.git//certificate-manager"
  domain_name       = var.domain_name
  alternative_names = var.alternative_names
}

# Create application load balancer
module "application_load_balancer" {
  source                       = "git::https://github.com/ifediM/Terraform--EKS-Infrastructure.git//alb"
  project_name                 = local.project_name
  environment                  = local.environment
  app_server_security_group_id = module.security-group.app_server_security_group_id
  public_subnet_az1_id         = module.vpc.public_subnet_az1_id
  public_subnet_az2_id         = module.vpc.public_subnet_az2_id
  target_type                  = var.target_type
  vpc_id                       = module.vpc.vpc_id
  certificate_arn              = module.ssl_certificate.certificate_arn
}



module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "devops-capstone-project"
  cluster_version = "1.33"

  # 1. Ensure Public Access is open for your Jumpbox/Actions
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = [module.vpc.public_subnet_az1_id, module.vpc.public_subnet_az2_id]
  control_plane_subnet_ids = [module.vpc.public_subnet_az1_id, module.vpc.public_subnet_az2_id]

  # 2. Authentication Strategy
  # This enables the new "API" based access instead of the old configmap
  authentication_mode = "API_AND_CONFIG_MAP"

  # Automatically give the person running Terraform admin rights
  enable_cluster_creator_admin_permissions = true

  access_entries = {
    # This allows your Ubuntu user to authenticate
    ubuntu_admin = {
      principal_arn = var.user_arn # <-- Replace with the ARN of the user you want to have admin access
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  eks_managed_node_groups = {
    green = {
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      instance_types = ["t3.medium"]
    }
  }
}


# Create record set in route 53
module "route53" {
  source                             = "git::https://github.com/ifediM/Terraform--EKS-Infrastructure.git//route53"
  domain_name                        = module.ssl_certificate.domain_name
  record_name                        = var.record_name
  application_load_balancer_dns_name = module.application_load_balancer.application_load_balancer_dns_name
  application_load_balancer_zone_id  = module.application_load_balancer.application_load_balancer_zone_id
}


