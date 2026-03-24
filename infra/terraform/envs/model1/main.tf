provider "aws" {
  region = var.region
}

module "vpc" {
  source = "../../modules/vpc"
}

module "security" {
  source = "../../modules/security"
  vpc_id = module.vpc.vpc_id
}

module "rds" {
  source      = "../../modules/rds"
  vpc_id      = module.vpc.vpc_id
  db_password = var.db_password
  sg_id       = module.security.rds_sg
}

module "ec2" {
  source        = "../../modules/ec2"
  subnet_id     = module.vpc.subnet_id
  sg_id         = module.security.ec2_sg
  db_host       = module.rds.db_host
  db_password   = var.db_password
}

module "alb" {
  source     = "../../modules/alb"
  vpc_id     = module.vpc.vpc_id
  subnet_id  = module.vpc.subnet_id
  target_id  = module.ec2.instance_id
}

module "cloudfront" {
  source  = "../../modules/cloudfront"
  alb_dns = module.alb.alb_dns
}
