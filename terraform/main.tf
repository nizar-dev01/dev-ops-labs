provider "aws" {
  region = "us-east-1"
}

module "ec2_app" {
  source = "./modules/ec2"
}
