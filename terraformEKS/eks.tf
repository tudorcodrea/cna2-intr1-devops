module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  cluster_endpoint_public_access  = true

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnets

  # Enable IAM Roles for Service Accounts (IRSA)
  enable_irsa = true

  # Disable KMS encryption to avoid kms:TagResource permission requirement
  create_kms_key = false
  cluster_encryption_config = {}

  # Create and manage aws-auth ConfigMap so your IAM user/role has access
  # turns out in v20 by default it is ConfigMap + API
  #authentication_mode = CONFIG_MAP

  # Map the currently-authenticated caller to system:masters (admin).
  # Useful for first-time access; for prod, map granular roles instead.
  # --- V20 CHANGE ---
  # This grants the user creating the cluster (current caller) admin access.
  # This replaces your manual "aws_auth_roles" block for the current user.
  enable_cluster_creator_admin_permissions = true

  cluster_addons = merge(
    local.manage_dapr ? {
      dapr = {
        most_recent = true
        manage      = true
      }
    } : {},
    {
      amazon-cloudwatch-observability = {
        most_recent = true
        manage      = true
      }
    }
  )

  # Disable recommended node SG rules to avoid duplicate webhook 443 rules
  # The Dapr addon (when managed) will create the needed rule from cluster SG to node SG.
  node_security_group_enable_recommended_rules = false

  # Note: The EKS module does not have a
  # `cluster_security_group_enable_recommended_rules` input.
  # We only disable node SG recommended rules above.

  # Explicitly override the module-managed rule key to prevent creation
  # Some module versions still attempt to create `ingress_cluster_443`.
  node_security_group_additional_rules = {
    ingress_cluster_443 = {
      description                   = "Ingress 443 from cluster SG (disabled)"
      protocol                      = "tcp"
      from_port                     = 443
      to_port                       = 443
      type                          = "ingress"
      source_cluster_security_group = true
      create                        = false
    },
    ingress_node_ports = {
      description = "Node ports from VPC for LoadBalancer health checks"
      protocol    = "tcp"
      from_port   = 30000
      to_port     = 32767
      type        = "ingress"
      cidr_blocks = [local.vpc_cidr]
    }
  }

  eks_managed_node_groups = {
    default = {
      instance_types = var.instance_types
      min_size       = var.min_size
      max_size       = var.max_size
      desired_size   = var.desired_size
      capacity_type  = var.capacity_type # ON_DEMAND or SPOT
      disk_size      = 20
      use_custom_launch_template = false
      subnet_ids     = local.public_subnets
    }
  }

  tags = local.tags
}

data "aws_caller_identity" "current" {}