#!/bin/bash
set -e
 
echo "Starting application deployment..."
 
# Load infrastructure variables
source ./deployed_env.sh
 
echo "Using cluster: $CLUSTER_NAME"
echo "Using ECR repositories: $ECR_PRODUCT_REPO, $ECR_ORDER_REPO"
 
# Configure kubectl for EKS cluster
echo "Configuring kubectl for EKS cluster..."
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
 
# Verify cluster access
echo "Verifying cluster access..."
kubectl get nodes
 
# Install Dapr (skip if already installed)
echo "Installing Dapr..."
helm repo add dapr https://dapr.github.io/helm-charts/ 2>/dev/null || true
helm repo update
if ! helm list -n dapr-system | grep -q dapr; then
    helm upgrade --install dapr dapr/dapr \
      --version=1.12.0 \
      --namespace dapr-system \
      --create-namespace \
      --set global.ha.enabled=false \
      --wait
else
    echo "Dapr already installed"
fi
 
# Build and push Docker images
echo "Building and pushing product-service..."
cd nexus-shop/code/product-service
docker build -t $ECR_PRODUCT_REPO:latest .
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_PRODUCT_REPO
docker push $ECR_PRODUCT_REPO:latest
 
echo "Building and pushing order-service..."
cd ../order-service
docker build -t $ECR_ORDER_REPO:latest .
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_ORDER_REPO
docker push $ECR_ORDER_REPO:latest
 
cd ../../..
 
# Deploy using Helm
echo "Deploying applications with Helm..."
helm upgrade --install nexus-shop ./nexus-shop/helm/nexus-shop \
  --set global.region=$AWS_REGION \
  --set global.roleArn=$IAM_ROLE_ARN \
  --set pubsub.topicArn=$SNS_TOPIC_ARN \
  --set pubsub.queueUrl=$SQS_QUEUE_URL \
  --set images.product=$ECR_PRODUCT_REPO \
  --set images.order=$ECR_ORDER_REPO
 
# Wait for rollout
echo "Waiting for deployment rollout..."
kubectl rollout status deployment/product-service
kubectl rollout status deployment/order-service
 
echo "Application deployment complete!"
echo "Product service will be available via LoadBalancer"
echo "Check status with: kubectl get pods,svc"