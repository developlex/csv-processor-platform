# Observability

## Purpose
Define logging, metrics, and alerting requirements for MVP operations. This document is authoritative for observability behavior.

## Logging
- All Lambda logs must be structured (JSON).
- Every log line during worker processing must include `dataset_id`.
- Error logs must include a stable error code and a single-line message.
- No sensitive data should be logged.
- CloudWatch Logs retention is **7 days** for all log groups.
- API Gateway access logs must be enabled and retained for **7 days**.
- API Gateway must be configured with an account-level CloudWatch Logs role.

Required log fields:
- `service` (string) : `api` or `worker`
- `dataset_id` (string|null)
- `level` (string) : `DEBUG`, `INFO`, `WARN`, `ERROR`
- `message` (string)
- `error_code` (string|null)

## Metrics
All metrics must be published to CloudWatch under the namespace `CsvProcessor`.

Required metrics (default set):
- `DatasetsProcessed` (Count) : successful profiling completions
- `DatasetsFailed` (Count) : failed profiling completions
- `BytesProcessed` (Bytes) : raw CSV bytes processed
- `RowsProcessed` (Count) : rows processed (excluding header)
- `ProcessingDurationMs` (Milliseconds) : worker processing duration
- `QueueLagSeconds` (Seconds) : age of the oldest SQS message at start of processing

Required dimensions:
- `Service` : `api` or `worker`
- `Environment` : deployment environment name

## Alarms
All alarms must notify a single SNS topic for MVP operations.

Required alarms (defaults):
- **Worker Errors**: `Errors >= 1` over 5 minutes
- **API Errors**: `Errors >= 1` over 5 minutes
- **Worker Duration**: `Duration p95 >= 150000 ms` over 5 minutes
- **API Duration**: `Duration p95 >= 10000 ms` over 5 minutes
- **Throttles**: `Throttles >= 1` over 5 minutes
- **DLQ Messages**: `ApproximateNumberOfMessagesVisible >= 1` over 5 minutes
- **Queue Age**: `ApproximateAgeOfOldestMessage >= 300 seconds` over 5 minutes

Alarm scoping:
- Alarms must be scoped per Lambda alias where applicable.

Alarm actions:
- All alarms must notify the SNS topic `csv-processor-alarms`.

## Notifications
- All alarms must publish to an SNS topic named `csv-processor-alarms`.
- The SNS topic ARN must be provided to Lambdas as `ALARM_TOPIC_ARN`.

## Change Control
Any change to metric names, dimensions, or alarm thresholds requires a new freeze marker entry.
