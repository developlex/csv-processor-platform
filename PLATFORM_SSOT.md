# PLATFORM SSOT
SSOT Version: v1
Status: FINAL

## Authority Order
Authority (highest → lowest):
1. PLATFORM_SSOT.md
2. docs/freeze-markers.md
3. docs/architecture.md
4. README.md
5. All other documentation

## Project Scope (MVP)
This MVP provides:
- CSV upload via HTTP API
- Asynchronous CSV profiling
- Schema inference and basic statistics
- S3-based storage for raw data, metadata, and profiles
- Completion/failure notification via a platform event

This MVP explicitly does NOT provide:
- AI or LLM-based analysis
- Data transformations or exports
- User authentication or multi-tenancy
- Persistent databases (RDS, DynamoDB, etc.)
- Interactive UI or dashboards

Scope (User-Visible Capabilities): This section defines externally observable behavior only. No implementation details belong here.

## Architectural Invariants (NON-NEGOTIABLE)
Architectural Invariants: This section defines mandatory internal constraints (e.g., async queue, storage model, deployment model). Any change requires a new SSOT version + freeze marker.

- Serverless only (AWS Lambda)
- Container-based Lambdas only
- S3 is the only persistent storage
- Async processing via SQS
- No database in MVP
- CSV processing must be chunked (no full-file memory loads)
- Data behavior is defined exclusively in `docs/data-contracts.md`
- Runtime limits and assumptions are defined exclusively in `docs/runtime.md`
SSOT governs scope and invariants; `docs/data-contracts.md` governs externally observable data formats and semantics.

## Lifecycle Model
Dataset states:
`UPLOADED` → `PROCESSING` → `READY`
Failure path: `FAILED`

## Ownership
Platform owns infrastructure, pipeline, and profiling.
No user-level ownership in MVP.

## Change Policy
Any change that violates this document requires:
- A new SSOT version
- A new freeze marker

## Future Reference (Non-Binding)
The following items are explicitly out of scope for MVP and are noted for future consideration only:
- Load balancer for API traffic management
- RDS with sharding for persistent metadata storage
- KMS encryption and key management controls
