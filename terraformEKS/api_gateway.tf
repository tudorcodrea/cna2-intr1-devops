# API Gateway for Product Service

resource "aws_api_gateway_rest_api" "product_api" {
  name        = "product-service-api"
  description = "API Gateway for Product Service"
}

resource "aws_api_gateway_resource" "products" {
  rest_api_id = aws_api_gateway_rest_api.product_api.id
  parent_id   = aws_api_gateway_rest_api.product_api.root_resource_id
  path_part   = "products"
}

resource "aws_api_gateway_method" "post_product" {
  rest_api_id   = aws_api_gateway_rest_api.product_api.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_product_integration" {
  rest_api_id             = aws_api_gateway_rest_api.product_api.id
  resource_id             = aws_api_gateway_resource.products.id
  http_method             = aws_api_gateway_method.post_product.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "POST"
  uri                     = "http://a2c1fcf330e564589a8bfc4b315bee1d-833279991.us-east-1.elb.amazonaws.com/products/prod"
}

resource "aws_api_gateway_method" "get_products" {
  rest_api_id   = aws_api_gateway_rest_api.product_api.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_products_integration" {
  rest_api_id             = aws_api_gateway_rest_api.product_api.id
  resource_id             = aws_api_gateway_resource.products.id
  http_method             = aws_api_gateway_method.get_products.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "GET"
  uri                     = "http://a2c1fcf330e564589a8bfc4b315bee1d-833279991.us-east-1.elb.amazonaws.com/products/health"
}

resource "aws_api_gateway_deployment" "product_deployment" {
  depends_on = [aws_api_gateway_integration.post_product_integration, aws_api_gateway_integration.get_products_integration]
  rest_api_id = aws_api_gateway_rest_api.product_api.id
  stage_name  = "prod"
}

output "api_gateway_url" {
  value = "${aws_api_gateway_deployment.product_deployment.invoke_url}/products"
}