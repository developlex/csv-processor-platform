# Audit Log

This file tracks infrastructure changes and documentation alignments made during the Terraform workshop.

## 2026-02-05
### Terraform
- Added core resources: S3 buckets, SQS queues (blue/green + DLQ), SNS topic, CloudWatch log groups.
- Added IAM roles and policies for API and Worker.
- Added Lambda functions (container images), aliases, and SQS event source mappings.
- Added CloudWatch alarms and SNS alarm actions.
- Added CodeDeploy app + deployment group (API).
- Added ECR repositories + lifecycle policies.
- Added API Gateway HTTP API with Lambda proxy integration and access logs.
- Added API Gateway account-level logging role.
- Added S3 hardening (SSE-S3, block public access, versioning).
- Added Terraform backend config and bootstrap (S3 state + DynamoDB locks).

### Outputs
- Added outputs for buckets, queues, SNS, API invoke URL, alarms, ECR repo URLs.

### Docs
- Aligned architecture, runtime, observability, CI/CD, and workshop docs with infrastructure.
- Added freezes for observability, deployment strategy, storage hardening, ECR lifecycle, API Gateway entrypoint, and logging role.

## Notes
- Apply is currently blocked by IAM permissions unless admin access is granted.
