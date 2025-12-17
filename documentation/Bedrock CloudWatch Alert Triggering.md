# Bedrock CloudWatch Alert Triggering

## Overview
This document describes how Amazon Bedrock is integrated with CloudWatch for automated analysis of microservices metrics and logs. The system uses AWS Lambda to query CloudWatch data and generate AI-powered insights using Amazon Bedrock.

## Current Implementation

### Scheduled Analysis
- **Trigger**: EventBridge rule runs every hour
- **Lambda Function**: `introspect1Eks-bedrock-analysis`
- **Data Sources**:
  - CloudWatch Metrics: EKS pod CPU utilization, SNS publish rates, ELB latency
  - CloudWatch Logs: Application error logs from Container Insights
- **AI Analysis**: Anthropic Claude v2 via Bedrock Runtime
- **Storage**: Insights stored in S3 bucket `introspect1eks-bedrock-insights-*`

### Workflow
1. EventBridge triggers Lambda every hour
2. Lambda queries CloudWatch metrics and logs for the past hour
3. Data is sent to Bedrock for analysis with a custom prompt
4. AI-generated insights are stored in S3
5. Results can be viewed or integrated into dashboards

## Alert-Based Triggering (Future Enhancement)

### Proposed Setup
To trigger Bedrock analysis on specific alerts:

#### 1. Create CloudWatch Alarms
```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "microservices-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "pod_cpu_utilization"
  namespace           = "AWS/ContainerInsights"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when pod CPU exceeds 80%"
  alarm_actions       = [aws_sns_topic.bedrock_alert_topic.arn]
}
```

#### 2. SNS Topic for Alerts
```hcl
resource "aws_sns_topic" "bedrock_alert_topic" {
  name = "bedrock-analysis-alerts"
}

resource "aws_sns_topic_subscription" "bedrock_lambda_subscription" {
  topic_arn = aws_sns_topic.bedrock_alert_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.bedrock_analysis.arn
}
```

#### 3. Lambda Permission for SNS
```hcl
resource "aws_lambda_permission" "sns_invoke" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bedrock_analysis.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.bedrock_alert_topic.arn
}
```

### Benefits of Alert-Based Triggering
- **Proactive Analysis**: Analyze issues immediately when they occur
- **Cost Optimization**: Only run analysis when needed
- **Real-time Insights**: Get AI insights during incidents

## Monitoring Bedrock Activity

### Check Lambda Invocations
```bash
aws logs tail /aws/lambda/introspect1Eks-bedrock-analysis --region us-east-1
```

### View Stored Insights
```bash
aws s3 ls s3://introspect1eks-bedrock-insights-*/insights/ --region us-east-1
```

### Sample Insight Output
```
Analysis of microservices metrics for the past hour:

Metrics Summary:
- Pod CPU Utilization: Average 45%, Peak 78%
- SNS Messages Published: 150
- ELB Latency: Average 120ms

Anomalies Detected:
- CPU spike at 14:30, possibly due to increased traffic

Recommendations:
- Consider horizontal pod autoscaling if CPU > 70% sustained
- Monitor ELB latency trends for performance optimization
```

## Troubleshooting

### Common Issues
1. **Lambda Fails**: Check CloudWatch logs for errors
2. **No Data**: Verify metric dimensions and log group names
3. **Bedrock Errors**: Ensure model access and IAM permissions
4. **S3 Upload Fails**: Check bucket permissions

### Permissions Required
- `cloudwatch:GetMetricData`
- `logs:FilterLogEvents`
- `bedrock:InvokeModel`
- `s3:PutObject`

## Future Enhancements
- Integrate with CloudWatch Dashboards
- Add Slack/Teams notifications for insights
- Implement ML-based anomaly detection
- Create custom Bedrock models for microservices domain

---
*Last Updated: December 15, 2025*