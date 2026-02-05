# Freeze Markers

## Freeze v1 — Data Contracts
Status: FINAL
Date: 2026-02-04

Frozen:
- S3 key layout
- `meta.json` schema and lifecycle semantics
- `profile.json` schema and statistical guarantees
- Contract version `v1`

Rationale: Establish a stable, externally observable data contract before implementation to prevent silent drift and enable deterministic testing.

Change policy:
- Any change to this freeze requires a new freeze marker entry and SSOT update.

## Freeze v1 — Platform SSOT
Status: FINAL
Date: 2026-02-04

Frozen:
- MVP scope and exclusions
- Architectural invariants
- Lifecycle model
- Authority order and change policy

Rationale: Lock platform scope and non-negotiable architectural decisions before implementation to prevent drift and scope creep.

## Freeze v1 — CI/CD Contract
Status: FINAL
Date: 2026-02-04

Frozen:
- CI merge and deploy requirements for MVP
- Required and deferred test categories
- Image build and immutability rules
- Secrets handling rules

Rationale: Establish CI as the enforcement layer and prevent scope creep or inconsistent quality gates during MVP implementation.

## Freeze v1 — Installation
Status: FINAL
Date: 2026-02-04

Frozen:
- Installation prerequisites
- Environment variable contract
- Local test expectations
- High-level deploy process

Rationale: Provide a deterministic, low-ambiguity setup path without embedding implementation or infrastructure details.

## Freeze v1 — README
Status: FINAL
Date: 2026-02-04

Frozen:
- README scope and content
- Documentation authority disclaimer
- Repository structure overview

Rationale: Establish a minimal, deferential entry point that does not duplicate or override authoritative documentation.

## Freeze v1 — Architecture
Status: FINAL
Date: 2026-02-04

Frozen:
- System overview (API Lambda vs Worker Lambda)
- Event flow (upload → SQS → worker → S3 → event)
- Storage layout and failure handling narrative
- Scaling model and cost control notes

Rationale: Provide a stable architectural narrative that matches the SSOT and contracts without embedding implementation details.

## Freeze v2 — Observability
Status: FINAL
Date: 2026-02-04

Frozen:
- CloudWatch logging requirements and retention
- Metrics namespace, names, and required dimensions
- Alarm thresholds and notification routing

Rationale: Lock observability behavior so operations and alerts are deterministic during MVP implementation.

## Freeze v2 — Runtime and Architecture Observability Addendum
Status: FINAL
Date: 2026-02-04

Frozen:
- Runtime environment variable for alarm notifications
- Architecture references to observability requirements

Rationale: Keep runtime and architecture docs aligned with the observability contract.

## Freeze v3 — Deployment Strategy
Status: FINAL
Date: 2026-02-04

Frozen:
- Blue/green + canary deployment model for API and Worker
- Dual-queue worker isolation and routing rules
- Default traffic shift and rollback policy

Rationale: Lock deployment mechanics and rollback behavior before implementation.

## Freeze v4 — Storage Hardening
Status: FINAL
Date: 2026-02-04

Frozen:
- S3 buckets must enforce SSE-S3
- S3 buckets must block public access
- S3 bucket versioning must be enabled

Rationale: Prevent accidental exposure and ensure recoverability for stored datasets.

## Freeze v5 — ECR Lifecycle
Status: FINAL
Date: 2026-02-04

Frozen:
- Expire untagged images after 7 days
- Retain last 20 tagged images

Rationale: Prevent container image storage bloat and reduce cost drift.

## Freeze v6 — API Gateway Entrypoint
Status: FINAL
Date: 2026-02-04

Frozen:
- API Gateway (HTTP API) as public entrypoint
- Lambda proxy integration to API Lambda alias
- Default route via `$default`

Rationale: Lock the external entrypoint to align routing and deployment strategy.

## Freeze v7 — API Gateway Access Logs
Status: FINAL
Date: 2026-02-04

Frozen:
- API Gateway access logs enabled
- Access log retention set to 7 days

Rationale: Ensure HTTP entrypoint logs are retained for operational visibility.

## Freeze v8 — API Gateway Logging Role
Status: FINAL
Date: 2026-02-04

Frozen:
- API Gateway account-level CloudWatch Logs role

Rationale: Ensure access logs can be written consistently.

## Freeze v2 — MVP2 Roadmap (Future Reference)
Status: DRAFT
Date: 2026-02-04

Frozen (planned, not yet active):
- Introduce a load balancer for API traffic management
- Add RDS with sharding for persistent metadata storage
- Add KMS encryption and key management controls

Rationale: Capture future MVP2 targets without altering MVP scope or invariants.

## Freeze v1 — IAM
Status: FINAL
Date: 2026-02-04

Frozen:
- Required IAM roles and trust relationships
- Minimum permissions for API and Worker
- Least-privilege rules for S3, SQS, SNS, and CloudWatch

Rationale: Lock IAM boundaries early to prevent privilege creep.
