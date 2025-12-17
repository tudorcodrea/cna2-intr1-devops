variable "project" {
  type        = string
  description = "Project identifier used in names and tags"
  default     = "introspect1"
}

variable "region" {
  type        = string
  description = "AWS region for EKS"
  default     = "us-east-1"
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile name"
  default     = "cna2"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
  default     = "introspect1Eks"
}

variable "cluster_version" {
  type        = string
  description = "EKS Kubernetes version (e.g., 1.30)"
  default     = "1.29"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  type        = list(string)
  description = "Private subnet CIDRs (for worker nodes)"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  type        = list(string)
  description = "Public subnet CIDRs (for NAT/ingress)"
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "desired_size" {
  type        = number
  default     = 1
}

variable "min_size" {
  type        = number
  default     = 1
}

variable "max_size" {
  type        = number
  default     = 3
}

variable "instance_types" {
  type        = list(string)
  default     = ["t3.medium"]
}

variable "capacity_type" {
  type        = string
  description = "ON_DEMAND or SPOT"
  default     = "ON_DEMAND"
}

# Feature toggles / names
variable "enable_ecr" {
  type        = bool
  description = "Create ECR repositories for microservices"
  default     = true
}

variable "enable_pubsub" {
  type        = bool
  description = "Create SNS topic for Dapr pub/sub"
  default     = true
}

variable "pubsub_topic_name" {
  type        = string
  description = "SNS topic name used for Dapr pub/sub"
  default     = "orders-events"
}

variable "enable_dapr" {
  type        = bool
  description = "Install Dapr via Helm"
  default     = true
}

variable "microservices_namespace" {
  type        = string
  description = "Kubernetes namespace for product/order services"
  default     = "microservices"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of AZs to use for VPC subnets (fallback when DescribeAvailabilityZones is not permitted)."
  default     = ["us-east-1a", "us-east-1b"]
}

variable "enable_k8s_resources" {
  type        = bool
  description = "Whether to create Kubernetes namespace/service accounts & Dapr component on initial apply (set false for first run to avoid cluster not ready issues)."
  default     = true
}

variable "eks_admin_principal_arn" {
  type        = string
  description = "IAM user or role ARN to grant cluster admin access via EKS access entry (AmazonEKSClusterAdminPolicy)."
  default     = "" # supply via tfvars if needed
}

variable "create_public_node_group" {
  type        = bool
  description = "Whether to create an additional public managed node group for lab (eks-lt-ng-public)."
  default     = true
}

# --- VPC Discovery ---
variable "use_existing_vpc" {
  type        = bool
  description = "Set to true to use an existing VPC instead of creating a new one."
  default     = false
}

variable "vpc_id" {
  type        = string
  description = "The ID of the existing VPC to use (if use_existing_vpc is true)."
  default     = ""
}

variable "existing_private_subnets" {
  type        = list(string)
  description = "A list of existing private subnet IDs to use."
  default     = []
}

variable "existing_public_subnets" {
  type        = list(string)
  description = "A list of existing public subnet IDs to use."
  default     = []
}
