provider "aws" {
  region = "us-east-1"
}

locals {
  environment = terraform.workspace == "default" ? "staging" : terraform.workspace
}

module "infra_vpc" {
  source  = "./modules/vpc"
  app_env = local.environment
}

module "security_groups" {
  source = "./modules/security_groups"
  vpc_id = module.infra_vpc.vpc_id
}

module "ec2_app" {
  source = "./modules/ec2"

  private_subnet        = module.infra_vpc.private_subnet
  public_subnet_one     = module.infra_vpc.public_subnet_one
  public_subnet_two     = module.infra_vpc.public_subnet_two
  app_security_group_id = module.security_groups.web_access.id
  vpc_id                = module.infra_vpc.vpc_id
  app_env               = local.environment
}

