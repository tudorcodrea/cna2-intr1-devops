terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "introspect1-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "introspect1-tf-locks"
    profile        = "cna2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}