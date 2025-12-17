# Set error action to Stop to mimic 'set -e' in Bash (stop script if any command fails)
$ErrorActionPreference = "Stop"

# 1. Configure Variables
$AwsProfile = "cna2"
$Region = "us-east-1"

# 2. Get AWS Account ID dynamically
Write-Host "Fetching AWS Account ID..." -ForegroundColor Cyan
$AccountId = (aws sts get-caller-identity --query Account --output text --profile $AwsProfile).Trim()

# 3. Define ECR URLs
$EcrBaseUrl = "$AccountId.dkr.ecr.$Region.amazonaws.com"
$ProductRepoUrl = "$EcrBaseUrl/product"
$OrderRepoUrl = "$EcrBaseUrl/order"

# 4. Login to Amazon ECR
Write-Host "--- Logging in to Amazon ECR ---" -ForegroundColor Cyan
aws ecr get-login-password --region $Region --profile $AwsProfile | docker login --username AWS --password-stdin $EcrBaseUrl

# 5. Build and Push Product Service
Write-Host "--- Building and Pushing Product Service ---" -ForegroundColor Cyan
# Check if directory exists before entering
if (Test-Path ".\src\ProductService") {
    Push-Location -Path ".\src\ProductService"
    
    docker build -t product-service .
    docker tag product-service:latest "$ProductRepoUrl`:latest"
    docker push "$ProductRepoUrl`:latest"
    
    Pop-Location
} else {
    Write-Error "Directory .\src\ProductService not found!"
}

# 6. Build and Push Order Service
Write-Host "--- Building and Pushing Order Service ---" -ForegroundColor Cyan
if (Test-Path ".\src\OrderService") {
    Push-Location -Path ".\src\OrderService"
    
    docker build -t order-service .
    docker tag order-service:latest "$OrderRepoUrl`:latest"
    docker push "$OrderRepoUrl`:latest"
    
    Pop-Location
} else {
    Write-Error "Directory .\src\OrderService not found!"
}

Write-Host "✅ Images successfully pushed to ECR." -ForegroundColor Green