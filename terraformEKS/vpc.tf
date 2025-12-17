# --- VPC Discovery ---
data "aws_vpc" "existing" {
  count = var.use_existing_vpc ? 1 : 0
  id    = var.vpc_id
}

data "aws_subnets" "private" {
  count = var.use_existing_vpc ? 1 : 0
  filter {
    name   = "subnet-id"
    values = var.existing_private_subnets
  }
}

data "aws_subnets" "public" {
  count = var.use_existing_vpc ? 1 : 0
  filter {
    name   = "subnet-id"
    values = var.existing_public_subnets
  }
}

# --- VPC Creation ---
module "vpc" {
  count   = var.use_existing_vpc ? 0 : 1
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project}-vpc"
  cidr = var.vpc_cidr
  # Use provided AZ list to avoid needing ec2:DescribeAvailabilityZones permission.
  azs  = var.availability_zones

  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = false
  single_nat_gateway = true

  map_public_ip_on_launch = true

  # Helpful tags for legacy Kubernetes LBs; ALB Controller uses different annotations,
  # but these don't hurt and are often still useful.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = local.tags
}
