project        = "introspect1Eks"
region         = "us-east-1"
aws_profile    = "cna2"
cluster_name   = "introspect1Eks"
cluster_version = "1.29"

desired_size   = 1
min_size       = 1
max_size       = 3
instance_types = ["t3.medium"]
capacity_type  = "ON_DEMAND"

enable_k8s_resources = true
create_public_node_group = false
