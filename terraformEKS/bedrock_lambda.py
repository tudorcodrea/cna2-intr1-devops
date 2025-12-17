import boto3
import json
import os
from datetime import datetime, timedelta

# Initialize clients
cloudwatch = boto3.client('cloudwatch')
logs = boto3.client('logs')
bedrock = boto3.client('bedrock-runtime')
s3 = boto3.client('s3')

# Constants
BUCKET_NAME = os.environ['S3_BUCKET_NAME']
METRIC_NAMESPACE = 'AWS/EKS'  # Adjust as needed
LOG_GROUP_NAME = '/aws/containerinsights/introspect1Eks/application'  # Log group for EKS

def lambda_handler(event, context):
    try:
        # Get current time and 1 hour ago
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(hours=1)

        # Query CloudWatch metrics
        metrics_data = query_cloudwatch_metrics(start_time, end_time)

        # Query CloudWatch logs for errors
        logs_data = query_cloudwatch_logs(start_time, end_time)

        # Combine data
        data_to_analyze = {
            'metrics': metrics_data,
            'logs': logs_data
        }

        # Send to Bedrock for analysis
        insights = analyze_with_bedrock(data_to_analyze)

        # Store insights in S3
        store_insights(insights)

        return {
            'statusCode': 200,
            'body': json.dumps('Analysis complete')
        }
    except Exception as e:
        print(f"Error in lambda_handler: {str(e)}")
        raise

def query_cloudwatch_metrics(start_time, end_time):
    # Example metrics: EKS pod CPU usage, SNS publish rates, ELB latency
    metrics = [
        {
            'Namespace': 'AWS/ContainerInsights',
            'MetricName': 'pod_cpu_utilization',
            'Dimensions': [
                {'Name': 'ClusterName', 'Value': 'introspect1Eks'},
                {'Name': 'Namespace', 'Value': 'microservices'}
            ]
        },
        {
            'Namespace': 'AWS/SNS',
            'MetricName': 'NumberOfMessagesPublished',
            'Dimensions': [
                {'Name': 'TopicName', 'Value': 'product-events-topic'}
            ]
        },
        {
            'Namespace': 'AWS/ELB',
            'MetricName': 'TargetResponseTime',
            'Dimensions': [
                {'Name': 'LoadBalancer', 'Value': 'app/microservices-alb/a542f9680c6644518afaf2c799e76c51-255023407'}
            ]
        }
    ]

    data = {}
    for metric in metrics:
        response = cloudwatch.get_metric_data(
            MetricDataQueries=[
                {
                    'Id': 'm1',
                    'MetricStat': {
                        'Metric': {
                            'Namespace': metric['Namespace'],
                            'MetricName': metric['MetricName'],
                            'Dimensions': metric['Dimensions']
                        },
                        'Period': 300,  # 5 minutes
                        'Stat': 'Average'
                    }
                }
            ],
            StartTime=start_time,
            EndTime=end_time
        )
        data[metric['MetricName']] = response['MetricDataResults'][0]['Values'] if response['MetricDataResults'] else []

    return data

def query_cloudwatch_logs(start_time, end_time):
    # Filter for error logs
    response = logs.filter_log_events(
        logGroupName=LOG_GROUP_NAME,
        startTime=int(start_time.timestamp() * 1000),
        endTime=int(end_time.timestamp() * 1000),
        filterPattern='ERROR'
    )
    return [event['message'] for event in response['events']]

def analyze_with_bedrock(data):
    prompt = f"""
    Analyze the following CloudWatch metrics and logs from our microservices deployment:

    Metrics: {json.dumps(data['metrics'])}

    Error Logs: {json.dumps(data['logs'])}

    Identify any anomalies, suggest optimizations, and provide insights on potential failures or improvements.
    """

    body = json.dumps({
        "prompt": f"\n\nHuman: {prompt}\n\nAssistant:",
        "max_tokens_to_sample": 1000,
        "temperature": 0.7
    })

    response = bedrock.invoke_model(
        modelId='anthropic.claude-v2:1',  # Use appropriate model ID
        body=body,
        contentType='application/json',
        accept='application/json'
    )

    response_body = json.loads(response['body'].read())
    return response_body.get('completion', 'No insights generated')

def store_insights(insights):
    key = f"insights/{datetime.utcnow().strftime('%Y-%m-%d-%H-%M-%S')}.txt"
    s3.put_object(
        Bucket=BUCKET_NAME,
        Key=key,
        Body=insights
    )