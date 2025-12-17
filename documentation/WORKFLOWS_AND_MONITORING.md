# Microservices Workflows, Runtime, and CloudWatch Monitoring

This document describes the workflows and runtime behavior of the AWS Kubernetes microservices project, focusing on the communication between the Product Service and Order Service via SNS/SQS. It also details how CloudWatch monitors the deployment.

## Overview

The project consists of two microservices deployed on Amazon EKS:
- **Product Service**: Handles product creation and publishes events to Amazon SNS.
- **Order Service**: Listens to Amazon SQS for events and processes them (e.g., creates orders).

Communication is asynchronous via pub/sub messaging: Product Service → SNS Topic → SQS Queue → Order Service.

## Workflows

### 1. Product Creation Workflow
- **Trigger**: A client sends a POST request to the Product Service (e.g., via API Gateway or direct endpoint).
- **Processing**:
  - Product Service validates and saves the product.
  - Publishes a "product created" event to the SNS topic (`product-events-topic`).
- **Outcome**: Event is broadcast to subscribers (e.g., SQS queue for Order Service).

### 2. Order Processing Workflow
- **Trigger**: Order Service polls the SQS queue (`order-service-queue`) every 5 seconds.
- **Processing**:
  - Receives messages from SQS (which are SNS notifications wrapped in JSON).
  - Parses the message to extract the product details.
  - Processes the event (e.g., creates an order based on the product).
  - Deletes the message from SQS upon successful processing.
- **Outcome**: Order is created, and the event is consumed.

### End-to-End Flow
1. Client → Product Service (POST /products) → Publishes to SNS.
2. SNS → Delivers to SQS (via subscription).
3. Order Service → Polls SQS → Processes message → Deletes from queue.

This ensures decoupling: Product Service doesn't wait for Order Service, and vice versa.

## Runtime Behavior

### Deployment and Execution
- **Infrastructure**: Provisioned via Terraform (EKS cluster, VPC, SNS/SQS, API Gateway, CloudWatch).
- **Services**:
  - Product Service: Runs in a pod, exposes REST API on port 8080.
  - Order Service: Runs in a pod, uses scheduled polling for SQS.
- **Authentication**: Services use IAM roles (via service account `pubsub-sa`) for AWS access.
- **Scaling**: Services can scale via Kubernetes deployments; monitoring alerts on high resource usage.
- **Error Handling**:
  - Publishing failures: Logged as errors; CloudWatch alarms trigger.
  - Consumption failures: Messages remain in SQS for retry; logged for debugging.

### Key Runtime Components
- **SNS Topic**: `product-events-topic` – Central hub for events.
- **SQS Queue**: `order-service-queue` – Buffers messages for Order Service.
- **API Gateway**: Exposes Product Service externally with load balancing.
- **Load Balancer**: Routes traffic to service pods.

At runtime, the system is event-driven: Events flow asynchronously, allowing for high availability and fault tolerance.

## CloudWatch Monitoring

CloudWatch provides comprehensive monitoring for the deployment, focusing on performance, errors, and the pub/sub flow.

### Dashboard: Microservices-Monitoring-Dashboard
- **Widgets**:
  - **SNS Metrics**: Tracks messages published, delivered, failed, and size for `product-events-topic`. Monitors the publishing workflow.
  - **ELB Metrics**: Healthy/unhealthy hosts, request count, latency, 4XX/5XX errors. Ensures service availability.
  - **API Gateway Metrics**: Request count, latency, 4XX/5XX errors for `product-service-api`. Tracks external API usage.
  - **EKS Pod Metrics**: CPU/memory utilization, network I/O for pods in `microservices` namespace. Monitors runtime health.
- **Purpose**: Visualize the end-to-end flow – e.g., correlate SNS publishes with ELB requests and EKS pod activity.

### Alarms
- **SNS High Publish Rate**: Alerts if >10 messages published in 5 minutes (indicates high load or issues).
- **ELB Unhealthy Hosts**: Alerts if any hosts are unhealthy (service downtime).
- **API Gateway 5XX Errors**: Alerts if >5 server errors in 5 minutes (processing failures).
- **ELB High Latency**: Alerts if average latency >1 second (performance issues).
- **EKS High Node CPU**: Alerts if node CPU >80% (resource exhaustion).

### Log Monitoring
- **Application Logs**: Accessible via `kubectl logs` or CloudWatch Logs (if Fluent Bit is installed).
- **Metric Filters** (if enabled):
  - Error Logs: Counts "ERROR" occurrences for troubleshooting.
  - Product Published: Counts "Published product event" logs from Product Service.
  - Product Processed: Counts "Product event processed successfully" logs from Order Service.
- **Integration**: Logs help trace the workflow – e.g., confirm publishing and consumption.

### Monitoring the Pub/Sub Flow
- **Publishing (Product Service)**: Monitored via SNS metrics and logs; alarms on failures.
- **Consumption (Order Service)**: Monitored via SQS metrics (if added to dashboard) and logs; alarms on errors.
- **Overall Health**: Dashboard provides a holistic view – e.g., if SNS deliveries drop, check Order Service logs.

To access: AWS Console → CloudWatch → Dashboards → Microservices-Monitoring-Dashboard.

This setup ensures proactive monitoring, allowing quick identification of issues in the Product Service → SNS → Order Service flow.