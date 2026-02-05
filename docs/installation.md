# Installation

## Purpose
Provide a deterministic setup path for any developer to run and deploy the MVP without informal guidance.

## Prerequisites
- AWS account with permissions for Lambda, S3, SQS, and IAM
- Docker
- Terraform
- Python 3.11+
- AWS CLI configured with credentials

## Environment Variables
Required:
- `RAW_BUCKET` : S3 bucket for raw uploads
- `META_BUCKET` : S3 bucket for metadata
- `PROFILE_BUCKET` : S3 bucket for profiles
- `QUEUE_URL_BLUE` : SQS queue URL for blue worker processing
- `QUEUE_URL_GREEN` : SQS queue URL for green worker processing
- `AWS_REGION` : AWS region

Optional:
- `LOG_LEVEL` : `DEBUG`, `INFO`, `WARN`, `ERROR` (default `INFO`)

## Local Setup
1. Install prerequisites listed above.
2. Create S3 buckets and SQS queue in your AWS account.
3. Set required environment variables.

## Local Test Execution
- Run unit tests locally before opening a PR.
- Unit tests must not require network access or cloud resources.

## CI Expectations
CI must be green before merge. See `docs/ci-cd.md` for required checks.

## Deploy (High-Level)
1. Build and push container images (API and Worker) tagged by commit SHA.
2. Apply infrastructure changes via Terraform (when enabled).
3. Deploy Lambda functions using the built images.
4. API Gateway will expose the HTTP entrypoint for the API Lambda.

## Notes
- This document is not authoritative for scope or architecture; defer to `PLATFORM_SSOT.md` and `docs/runtime.md`.
- This document does not define infrastructure topology or networking details.
- Local execution does not emulate the full AWS runtime.
