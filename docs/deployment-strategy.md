# Deployment Strategy

## Purpose
Define blue/green and canary deployment mechanics for API and Worker from day one, with deterministic rollback behavior.

## Core Principles
- API traffic is shifted using Lambda aliases and CodeDeploy.
- Worker traffic is isolated using dual SQS queues and routing logic.
- All traffic shifting must be reversible without code changes.

## API (Blue/Green + Canary)
Mechanism: Lambda versions + alias + CodeDeploy traffic shifting.

Rules:
- API Gateway (or the HTTP entrypoint) must invoke the `api-live` alias, never `$LATEST`.
- Every release publishes a new Lambda version.
- CodeDeploy performs weighted traffic shifting between the old and new versions.
- Default canary policy: 10% for 10 minutes, then 100%.
- Rollback is automatic on alarm breach.

Required alarms for rollback:
- API Errors
- API Duration p95
- API Throttles

## Worker (Strict Isolation)
Mechanism: dual queues + routing by dataset_id.

Queues:
- `worker-blue`
- `worker-green`

Rules:
- Only one Worker Lambda processes each queue.
- API chooses the target queue at dataset creation time.
- Canary is implemented by routing a percentage of new dataset_ids to `worker-green`.
- Routing decisions are stable per dataset_id (no mid-flight switching).
- Rollback is immediate by routing 100% of new dataset_ids to `worker-blue`.

## Routing Algorithm (Deterministic)
Purpose: Ensure stable, deterministic routing for a given `dataset_id` based on `WORKER_TRAFFIC_SPLIT`.

Algorithm:
1. Compute `hash = SHA256(dataset_id)`.
2. Take the first 8 hex chars of `hash` and parse as an integer.
3. Compute `bucket = integer % 100` (range 0-99).
4. Route to `worker-green` if `bucket < WORKER_TRAFFIC_SPLIT`, else `worker-blue`.

Notes:
- `WORKER_TRAFFIC_SPLIT` is an integer 0-100.
- Routing must be consistent across API instances and deployments.

Required alarms:
- Worker Errors (per alias)
- Worker Duration p95
- Worker Throttles
- DLQ Messages
- Queue Age

## Traffic Shift Policy (Defaults)
- API: 10% for 10 minutes, then 100%.
- Worker: 5% of new dataset_ids to green for 30 minutes, then 100%.

## Rollback Policy
- API: CodeDeploy automatic rollback on any required alarm breach.
- Worker: routing switches to blue immediately on alarm breach; green processing may continue only for in-flight datasets.

## Change Control
Any change to traffic shift percentages, durations, queue model, or rollback criteria requires a new freeze marker entry.
