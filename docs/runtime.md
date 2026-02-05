# Runtime

## Purpose
This document defines runtime assumptions, limits, and operational constraints for the MVP. All guarantees in `docs/data-contracts.md` are subject to these limits.

## Execution Model
- API and Worker run as AWS Lambda functions.
- Worker processing is asynchronous and event-driven.
- Processing must be chunked; full-file in-memory loads are not permitted.

## Resource Limits (MVP)
The following bounds are mandatory. Exceeding any bound must fail fast, set dataset status to `FAILED`, and include a stable error code in `meta.json`.

- Max upload size: 25 MB
- Max columns: 200
- Chunk size: 50,000 rows
- Max processing time (worker): 180 seconds
- Max worker memory: 2048 MB
- Max `/tmp` usage: 512 MB
- CSV delimiter: comma only (`,`)

## Storage Hardening
- S3 buckets must enforce server-side encryption (SSE-S3).
- S3 buckets must block all public access.
- S3 bucket versioning must be enabled.

## Container Image Retention
- ECR repositories must expire untagged images after 7 days.
- ECR repositories must retain at least the last 20 tagged images.

Provisional limits may be adjusted only via a new freeze marker entry.

## Parsing and Chunking Rules
- The header row is required and defines column names.
- Rows must be streamed and processed in chunks of at most 50,000 rows.
- Empty lines are ignored.
- Whitespace trimming occurs after delimiter parsing.

## Environment Variables Contract
Required environment variables:
- `RAW_BUCKET` : S3 bucket for raw uploads.
- `META_BUCKET` : S3 bucket for metadata.
- `PROFILE_BUCKET` : S3 bucket for profiles.
- `QUEUE_URL_BLUE` : SQS queue URL for blue worker processing.
- `QUEUE_URL_GREEN` : SQS queue URL for green worker processing.
- `AWS_REGION` : AWS region for service clients.

Optional environment variables:
- `LOG_LEVEL` : One of `DEBUG`, `INFO`, `WARN`, `ERROR`. Default `INFO`.
- `ALARM_TOPIC_ARN` : SNS topic ARN for CloudWatch alarm notifications.
- `WORKER_TRAFFIC_SPLIT` : Integer percent (0-100) routed to green for new dataset_ids. Default `0`.

## /tmp Usage Rules
- Temporary files must be cleaned up before function exit.
- Total `/tmp` usage must not exceed 512 MB.
- A single dataset must not write more than 512 MB to `/tmp`.

## Logging Expectations
- Logs must be structured and include `dataset_id` on every line during worker processing.
- Errors must include a stable error code and a single-line message.
- No sensitive data should be logged.
Additional observability requirements are defined in `docs/observability.md`.

## Failure Behavior
- Any runtime limit violation must fail fast and set status to `FAILED`.
- `meta.json.error.code` must be stable and from the documented error code set.
- `completed_at` must be set on failure.
