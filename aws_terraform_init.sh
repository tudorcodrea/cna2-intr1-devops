#!/bin/bash
# aws_terraform_init.sh
# Initializes AWS resources for Terraform backend (S3, DynamoDB, KMS)
# Uses AWS CLI profile 'cna2' and region 'eu-central-1'

set -e

PROFILE="cna2"
REGION="us-east-1"
BUCKET="introspect1-bucket"
DYNAMO_TABLE="introspect1-tf-locks"
KMS_ALIAS="alias/introspect1-tf-key"

echo "Creating S3 bucket: $BUCKET in $REGION"
if [ "$REGION" = "us-east-1" ]; then
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" --profile "$PROFILE"
else
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION" --profile "$PROFILE"
fi

echo "Enabling versioning on bucket"
aws s3api put-bucket-versioning --bucket "$BUCKET" \
--versioning-configuration Status=Enabled --profile "$PROFILE" --region "$REGION"

echo "Blocking public access on bucket"
aws s3api put-public-access-block --bucket "$BUCKET" \
--public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
--profile "$PROFILE" --region "$REGION"

echo "Enabling default encryption (SSE-S3)"
aws s3api put-bucket-encryption --bucket "$BUCKET" \
--server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' \
--profile "$PROFILE" --region "$REGION"

echo "Creating DynamoDB table for state locking: $DYNAMO_TABLE"
aws dynamodb create-table --table-name "$DYNAMO_TABLE" \
--attribute-definitions AttributeName=LockID,AttributeType=S \
--key-schema AttributeName=LockID,KeyType=HASH \
--billing-mode PAY_PER_REQUEST --region "$REGION" --profile "$PROFILE"

echo "Creating ECR repositories for microservices..."
aws ecr create-repository --repository-name introspect1eks-product --region "$REGION" --profile "$PROFILE"
aws ecr create-repository --repository-name introspect1eks-order --region "$REGION" --profile "$PROFILE"

echo "Attaching AmazonVPCFullAccess policy to the IAM user for EC2 permissions"
aws iam attach-user-policy --user-name c04-vlabuser168@stackroute.in --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess --profile "$PROFILE"

# Optional: create KMS key for bucket encryption
# echo "Creating KMS key and alias (optional, for SSE-KMS)"
# KMS_KEY_ARN=$(aws kms create-key --description "Terraform state key" --region "$REGION" --profile "$PROFILE" --query 'KeyMetadata.Arn' --output text)
# aws kms create-alias --alias-name "$KMS_ALIAS" --target-key-id "$KMS_KEY_ARN" --region "$REGION" --profile "$PROFILE"
# echo "KMS Key ARN: $KMS_KEY_ARN"

# IAM policy creation (attach to your Terraform user/role)
echo "Creating IAM policy for Terraform backend access..."
aws iam create-policy --policy-name TerraformLabPolicy --policy-document "file://C:\Work\Documentation\Architecture\CNA 2\AWS kubernetes\introspect1\terraform-lab-policy.json" --profile "$PROFILE"

echo "Creating IAM policy for GitHub Actions ECR access..."
aws iam create-policy --policy-name GitHubActionsECRPolicy --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:PutImage"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "eks:DescribeCluster",
            "Resource": "arn:aws:eks:us-east-1:660633971866:cluster/introspect1Eks"
        }
    ]
}' --profile "$PROFILE"
# aws iam attach-user-policy --user-name c04-vlabuser168@stackroute.in --policy-arn arn:aws:iam::660633971866:policy/GitHubActionsECRPolicy --profile "$PROFILE"

aws iam attach-user-policy --user-name "c04-vlabuser168@stackroute.in" --policy-arn arn:aws:iam::660633971866:policy/TerraformLabPolicy
aws iam attach-user-policy --user-name "c04-vlabuser168@stackroute.in" --policy-arn arn:aws:iam::660633971866:policy/GitHubActionsECRPolicy --profile "$PROFILE"

# aws iam list-attached-user-policies --user-name "c04-vlabuser168@stackroute.in" --query 'AttachedPolicies[*].PolicyName'

aws iam create-role --role-name introspect1Eks-pubsub-role --assume-role-policy-document "file://C:\Work\Documentation\Architecture\CNA 2\AWS kubernetes\introspect1\assume-role-policy.json" --profile "$PROFILE"
aws iam attach-role-policy --role-name introspect1Eks-pubsub-role --policy-arn arn:aws:iam::aws:policy/AmazonSNSFullAccess --profile cna2 --region us-east-1
aws iam attach-role-policy --role-name introspect1Eks-pubsub-role --policy-arn arn:aws:iam::aws:policy/AmazonSQSFullAccess --profile cna2 --region us-east-1

aws iam update-assume-role-policy --role-name introspect1Eks-pubsub-role --policy-document "file://C:\Work\Documentation\Architecture\CNA 2\AWS kubernetes\introspect1\assume-role-policy-corrected.json" --profile "$PROFILE"
aws iam list-attached-role-policies --role-name introspect1Eks-pubsub-role --profile "$PROFILE"

echo "Attaching SNS and SQS policies to EKS node group role..."
NODE_ROLE=$(aws iam list-roles --query 'Roles[?starts_with(RoleName, `default-eks-node-group`)].RoleName' --output text --profile "$PROFILE")
aws iam attach-role-policy --role-name "$NODE_ROLE" --policy-arn arn:aws:iam::aws:policy/AmazonSNSFullAccess --profile "$PROFILE"
aws iam attach-role-policy --role-name "$NODE_ROLE" --policy-arn arn:aws:iam::aws:policy/AmazonSQSFullAccess --profile "$PROFILE"

echo "Done. Resources created for Terraform backend."


