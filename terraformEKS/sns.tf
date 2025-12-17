# SNS Topic for product events
resource "aws_sns_topic" "product_events" {
  name = "product-events-topic"
}

# SQS Queue for order service
resource "aws_sqs_queue" "order_service_queue" {
  name = "order-service-queue"
}

# Subscribe SQS to SNS
resource "aws_sns_topic_subscription" "order_service_subscription" {
  topic_arn = aws_sns_topic.product_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.order_service_queue.arn
}

# Policy for SNS to send messages to SQS
resource "aws_sqs_queue_policy" "order_service_queue_policy" {
  queue_url = aws_sqs_queue.order_service_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "SQS:SendMessage"
        Resource = aws_sqs_queue.order_service_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.product_events.arn
          }
        }
      }
    ]
  })
}