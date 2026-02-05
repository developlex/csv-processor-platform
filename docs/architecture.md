# Architecture

## System Overview
The system consists of three serverless components:
- API Gateway (HTTP API): public entrypoint.
- API Lambda: receives CSV uploads and creates dataset metadata.
- Worker Lambda: profiles CSVs asynchronously and writes results to S3.

## Event Flow
1. Client sends request to API Gateway (HTTP API).
2. API Gateway invokes API Lambda (alias).
3. API stores the raw file in S3 at `raw/{dataset_id}/source.csv`.
4. API writes `meta/{dataset_id}.json` with status `UPLOADED`.
5. API enqueues a message to SQS with `dataset_id` using the blue/green routing policy.
5. Worker reads the message, sets status to `PROCESSING`, and profiles the CSV in chunks.
6. Worker writes `profiles/{dataset_id}/profile.json`.
7. Worker updates `meta/{dataset_id}.json` to `READY` or `FAILED`.
8. A platform event is emitted on completion or failure.

## Storage Layout
All persistent artifacts are stored in S3 using the key contracts defined in `docs/data-contracts.md`:
- `raw/{dataset_id}/source.csv`
- `meta/{dataset_id}.json`
- `profiles/{dataset_id}/profile.json`

## Failure Handling
- Any runtime limit violation results in `FAILED` status with an error code.
- CSV parsing or profiling errors result in `FAILED` status with an error code.
- Failures always set `completed_at` and populate `meta.json.error`.

## Scaling Model
- API Lambda scales with request volume.
- Worker Lambda scales with SQS queue depth.
- Chunked processing enables bounded memory usage.

## Cost Control Notes
- Use S3 for all persistent storage (no database costs).
- Keep Lambdas right-sized for the fixed limits in `docs/runtime.md`.
- Prefer short-lived processing to minimize compute time.

## Observability
- CloudWatch Logs and metrics are required for both API and Worker.
- Alarms for errors, duration, throttles, and DLQ conditions are required.
- Observability contracts are defined in `docs/observability.md`.

## Deployment Strategy
- API traffic shifting uses Lambda aliases and CodeDeploy.
- Worker traffic is isolated using dual SQS queues.
- Deployment rules are defined in `docs/deployment-strategy.md`.
