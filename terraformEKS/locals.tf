locals {
  tags = {
    Project     = var.project
    Environment = "dev"
    Terraform   = "true"
  }
  manage_dapr = false

  # VPC locals
  vpc_id           = var.use_existing_vpc ? tostring(data.aws_vpc.existing[0].id) : tostring(module.vpc[0].vpc_id)
  private_subnets  = var.use_existing_vpc ? data.aws_subnets.private[0].ids : module.vpc[0].private_subnets
  public_subnets   = var.use_existing_vpc ? data.aws_subnets.public[0].ids : module.vpc[0].public_subnets
  vpc_cidr         = var.vpc_cidr
}