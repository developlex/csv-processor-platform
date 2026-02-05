# Terraform Workshop (Student-Led)

You will implement everything. I will provide step-by-step instructions and review your output before each next step.

## Ground Rules
- You run the commands.
- You edit the files.
- You paste back outputs or diffs when asked.
- We don’t skip steps.

## Step 0 — Environment Check (You Run)
Run these and paste results:

```bash
terraform version
aws --version
docker --version
python3 --version
```

If any are missing, stop and install before proceeding.

## Step 1 — Scaffold Terraform Layout (You Do)
Create the base files under `infra/terraform/`:
- `versions.tf`
- `main.tf`
- `variables.tf`
- `outputs.tf`

We will define providers and backend in `versions.tf` first.

## Step 2 — Define Provider and Backend (You Do)
We will:
- Pin Terraform and AWS provider versions
- Configure the AWS provider
- Define a backend (we’ll start with local state, then move to S3 if desired)

Required fields:
- `terraform.required_version`
- `terraform.required_providers.aws`
- `provider "aws" { region = var.aws_region }`

Backend approach:
- Use a separate bootstrap config in `infra/terraform/bootstrap/` to create:
  - S3 state bucket
  - DynamoDB lock table
- Then configure the main backend in `infra/terraform/backend.tf`.

Bootstrap variables (required):
- `aws_region`
- `state_bucket_name`
- `lock_table_name`

## Step 3 — Core Resources (You Do)
We will create:
- S3 buckets (raw, meta, profiles)
- SQS queues (worker-blue, worker-green)
- CloudWatch log groups with 7-day retention
- SNS topic for alarms

Required variables (examples):
- `raw_bucket_name`, `meta_bucket_name`, `profile_bucket_name`
- `queue_name_blue`, `queue_name_green`, `queue_name_dlq`
- `log_group_api_name`, `log_group_worker_name`
- `log_retention_days`
- `sns_topic_name`

Outputs we expect:
- `raw_bucket_name`, `meta_bucket_name`, `profile_bucket_name`
- `queue_url_blue`, `queue_url_green`, `queue_url_dlq`
- `sns_topic_arn`
- Alarm outputs (names): `alarm_api_errors`, `alarm_api_duration_p95`, `alarm_api_throttles`, `alarm_worker_errors`, `alarm_worker_duration_p95`, `alarm_worker_throttles`, `alarm_dlq_messages`, `alarm_queue_age`

## Step 4 — IAM Roles (You Do)
We will implement the policies defined in `docs/iam.md`.

Approach:
- Use `data "aws_iam_policy_document"` for trust and permissions
- Create `aws_iam_role` + `aws_iam_role_policy` for API and Worker

## Step 5 — Lambda + Image Wiring (You Do)
We will wire Lambda functions to container images (placeholders first).

Required fields:
- `package_type = "Image"`
- `image_uri`
- `publish = true` (for aliases)
- environment variables: buckets, queues, region, alarm topic, traffic split

Required variables:
- `api_ecr_repo_name`, `worker_ecr_repo_name`
- `image_tag`
- `lambda_memory_mb`, `lambda_timeout_seconds`
- `worker_traffic_split`
- `api_gateway_name`, `api_gateway_stage`
- `api_gateway_log_retention_days`
- `apigw_log_role_name`

## Step 6 — CodeDeploy + Alias Strategy (You Do)
We will configure:
- Lambda aliases
- CodeDeploy deployment groups
- Traffic shifting policies

Approach:
- Create `aws_lambda_alias` for API and Worker
- Create CloudWatch alarms (API + Worker + SQS)
- Use CodeDeploy with canary policy for API only

## Step 7 — Init and Validation (You Do)
We will run:
- `terraform init`
- `terraform fmt`
- `terraform validate`
- `terraform plan`

Bootstrap commands (run once):
```bash
cd infra/terraform/bootstrap
terraform init
terraform fmt
terraform validate
terraform plan
```

Main backend init (after bootstrap is applied):
```bash
cd infra/terraform
terraform init -reconfigure
```

## Step 8 — Debug & Iterate (You Do)
We will fix any issues and re-run the plan.

## Field Reference (What Each Field Means)

### CloudWatch Alarm Fields
- `alarm_name`: Human-readable identifier for the alarm.
- `namespace`: AWS service namespace (`AWS/Lambda` or `AWS/SQS`).
- `metric_name`: Metric to evaluate (e.g., `Errors`, `Duration`, `Throttles`, `ApproximateAgeOfOldestMessage`).
- `statistic` / `extended_statistic`: Aggregation for the period (`Sum`, `Maximum`, or `p95`).
- `threshold`: Value that triggers the alarm when exceeded.
- `period`: Evaluation window in seconds (e.g., `300` = 5 minutes).
- `evaluation_periods`: Number of periods that must breach before alarm fires.
- `treat_missing_data`: Behavior when there is no data (`notBreaching` avoids false alarms).
- `dimensions`: Filters metric to a specific function/alias or queue (e.g., Lambda `FunctionName` + `Resource`, SQS `QueueName`).
- `comparison_operator`: Comparison applied to the metric (e.g., `GreaterThanOrEqualToThreshold`).
- `alarm_description`: Human-readable context for the alarm.
- `alarm_actions`: SNS topic ARNs to notify on alarm.

### Lambda Fields Used
- `function_name`: Name of the Lambda function.
- `role`: IAM role ARN the function assumes.
- `package_type`: `Image` for container-based Lambda.
- `image_uri`: ECR image URL plus tag.
- `memory_size`: Memory allocation in MB.
- `timeout`: Max execution time in seconds.
- `publish`: Creates a new version on each update (required for aliases).
- `environment.variables`: Runtime environment variables for the function.

### Lambda Alias Fields
- `name`: Alias name (e.g., `api-live`).
- `function_name`: Target function.
- `function_version`: Version the alias points to.

### SQS Queue Fields Used
- `name`: Queue name.
- `redrive_policy`: DLQ config (`deadLetterTargetArn`, `maxReceiveCount`).

### S3 Bucket Fields Used
- `bucket`: Bucket name.

### ECR Repo Fields Used
- `name`: Repository name.

### CodeDeploy Fields Used
- `compute_platform`: `Lambda` for Lambda deployments.
- `deployment_style`: Blue/green with traffic control.
- `deployment_config_name`: Canary policy (e.g., `CodeDeployDefault.LambdaCanary10Percent10Minutes`).
- `alarm_configuration`: Alarms that trigger rollback.
- `auto_rollback_configuration`: Events that trigger rollback.

### Event Source Mapping Fields
- `event_source_arn`: SQS queue ARN.
- `function_name`: Lambda ARN.
- `batch_size`: Max records per invocation.
- `enabled`: Whether the mapping is active.

### API Gateway Fields Used
- `protocol_type`: `HTTP` for HTTP API.
- `route_key`: `$default` for catch-all routing.
- `integration_type`: `AWS_PROXY` for Lambda proxy.
- `payload_format_version`: `2.0` for HTTP API.
- `auto_deploy`: Auto-deploys route changes to stage.
- `access_log_settings`: Enables API Gateway access logs.

### Why These Defaults
- `period = 300` and `evaluation_periods = 1` keep alarms responsive without long delays.
- `p95` on duration catches tail latency that average metrics hide.
- `thresholds` match the runtime limits in `docs/runtime.md` and `docs/observability.md`.
- `publish = true` is required for alias-based traffic shifting.
- `batch_size = 10` is a safe starter for SQS-to-Lambda throughput without large payloads.

## Troubleshooting (Common Issues)

### Access Denied (403)
Symptoms:
- `AccessDenied` errors when creating S3, SQS, IAM, SNS, CodeDeploy, or CloudWatch.

Cause:
- Your AWS principal lacks required permissions.

Fix:
- Use a role/profile with the needed permissions or request them from an admin.
- Verify with `aws sts get-caller-identity`.

### CloudWatch Log Group Tagging Error
Symptoms:
- `AccessDeniedException` when creating log groups with tags.

Cause:
- Missing `logs:TagResource`.

Fix:
- Add `logs:TagResource` to the IAM principal permissions.

### Undefined Variable Warnings
Symptoms:
- `Value for undeclared variable` warnings in `terraform plan`.

Cause:
- Stale variables in `terraform.tfvars`.

Fix:
- Remove unused variables or add the corresponding `variable` block.

### CodeDeploy Validation Errors
Symptoms:
- Unknown block type errors in deployment group.

Cause:
- Using EC2/ECS-only blocks for Lambda.

Fix:
- Remove `load_balancer_info` and `deployment_group_blue_green_deployment_config` for Lambda deployments.

### S3 Bucket Name Conflicts
Symptoms:
- `BucketAlreadyExists` or `BucketAlreadyOwnedByYou`.

Cause:
- S3 bucket names are globally unique.

Fix:
- Change bucket names (include account or environment suffix).
