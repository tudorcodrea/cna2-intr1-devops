output "sns_topic_arn" {
  value = aws_sns_topic.product_events.arn
}

output "sqs_queue_url" {
  value = aws_sqs_queue.order_service_queue.url
}