# S3 bucket for storing Bedrock insights
resource "aws_s3_bucket" "bedrock_insights" {
  bucket = "${lower(var.project)}-bedrock-insights-${random_string.suffix.result}"

  tags = local.tags
}

resource "random_string" "suffix" {
  length  = 8
  lower   = true
  upper   = false
  numeric = true
  special = false
}

# IAM role for Lambda
resource "aws_iam_role" "bedrock_lambda_role" {
  name = "${var.project}-bedrock-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

# IAM policy for Lambda
resource "aws_iam_role_policy" "bedrock_lambda_policy" {
  name = "${var.project}-bedrock-lambda-policy"
  role = aws_iam_role.bedrock_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "logs:FilterLogEvents",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "bedrock:InvokeModel"
        Resource = "arn:aws:bedrock:*:*:model/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.bedrock_insights.arn}/*"
      },
      {
        Effect = "Allow"
        Action = "logs:CreateLogGroup"
        Resource = "arn:aws:logs:${var.region}:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:*:log-group:/aws/lambda/${var.project}-bedrock-analysis:*"
      }
    ]
  })
}

# Lambda function
resource "aws_lambda_function" "bedrock_analysis" {
  function_name = "${var.project}-bedrock-analysis"
  runtime       = "python3.9"
  handler       = "bedrock_lambda.lambda_handler"
  filename      = data.archive_file.bedrock_lambda_zip.output_path

  role = aws_iam_role.bedrock_lambda_role.arn

  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.bedrock_insights.bucket
    }
  }

  tags = local.tags

  depends_on = [aws_iam_role_policy.bedrock_lambda_policy]
}

# Package the Lambda code
data "archive_file" "bedrock_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/bedrock_lambda.py"
  output_path = "${path.module}/bedrock_lambda.zip"
}

# EventBridge rule for scheduling
resource "aws_cloudwatch_event_rule" "bedrock_analysis_schedule" {
  name                = "${var.project}-bedrock-analysis-schedule"
  description         = "Schedule for Bedrock analysis Lambda"
  schedule_expression = "rate(1 hour)"

  tags = local.tags
}

# EventBridge target
resource "aws_cloudwatch_event_target" "bedrock_analysis_target" {
  rule      = aws_cloudwatch_event_rule.bedrock_analysis_schedule.name
  target_id = "bedrock-analysis-lambda"
  arn       = aws_lambda_function.bedrock_analysis.arn
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bedrock_analysis.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.bedrock_analysis_schedule.arn
}