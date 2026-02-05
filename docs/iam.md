# IAM

## Purpose
Define IAM roles, trust relationships, and least-privilege policies for the MVP.

## Roles
Required roles:
- `csv-processor-api-role`
- `csv-processor-worker-role`

## Trust Relationships
Both roles must trust the Lambda service principal.

## API Role Permissions (Minimum)
S3:
- `s3:PutObject` on `raw/{dataset_id}/source.csv`
- `s3:PutObject` on `meta/{dataset_id}.json`

SQS:
- `sqs:SendMessage` to `worker-blue`
- `sqs:SendMessage` to `worker-green`

CloudWatch:
- `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`
- `cloudwatch:PutMetricData`

SNS (optional):
- `sns:Publish` to `csv-processor-alarms` (if API emits alerts)

## Worker Role Permissions (Minimum)
S3:
- `s3:GetObject` on `raw/{dataset_id}/source.csv`
- `s3:GetObject` on `meta/{dataset_id}.json`
- `s3:PutObject` on `meta/{dataset_id}.json`
- `s3:PutObject` on `profiles/{dataset_id}/profile.json`

SQS:
- `sqs:ReceiveMessage`, `sqs:DeleteMessage`, `sqs:GetQueueAttributes` on `worker-blue` and `worker-green`

CloudWatch:
- `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`
- `cloudwatch:PutMetricData`

SNS:
- `sns:Publish` to `csv-processor-alarms` (for alarm/test notifications)

## Policy Rules
- Least privilege only; no wildcard resource grants for S3, SQS, or SNS.
- Use explicit bucket/key prefixes for S3.
- Use explicit queue ARNs for SQS.
- Use explicit topic ARN for SNS.

## Change Control
Any change to required roles or permissions requires a new freeze marker entry.
