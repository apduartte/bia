variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "domain" {
  description = "Domain name for the ACM certificate"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
  default     = "ami-0c02fb55956c7d316"  # Amazon Linux 2 in us-east-1
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  env    = var.env
  cidr   = "10.0.0.0/16"
  azs    = ["us-east-1a", "us-east-1b"]
}

# Security Group Module (placeholder - to be created)
# module "sg" {
#   source = "../../modules/sg"
#   env    = var.env
#   vpc_id = module.vpc.vpc_id
# }

# EC2 Module
module "ec2" {
  source = "../../modules/ec2"

  env          = var.env
  vpc_id       = module.vpc.vpc_id
  subnet_id    = module.vpc.public_subnet_ids[0]
  alb_subnets  = module.vpc.public_subnet_ids
  domain       = var.domain
  ami_id       = var.ami_id
}