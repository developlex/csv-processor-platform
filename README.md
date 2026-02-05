# CSV Processor

This project provides an MVP platform for uploading CSV files, profiling them asynchronously, and storing raw data, metadata, and profiles in S3.
This repository implements MVP scope only.

If this file conflicts with `PLATFORM_SSOT.md` or `docs/data-contracts.md`, this file is wrong.

## Documentation
- `PLATFORM_SSOT.md` (highest authority)
- `docs/data-contracts.md`
- `docs/runtime.md`
- `docs/installation.md`
- `docs/ci-cd.md`
- `docs/deployment-strategy.md`
- `docs/iam.md`
- `docs/architecture.md`

## Repo Structure
- `app/api/` : API Lambda
- `app/worker/` : Worker Lambda
- `infra/terraform/` : Infrastructure as code
- `docker/` : Container images

## Non-Goals
- AI or LLM-based analysis
- Data transformations or exports
- Interactive UI or dashboards

## Run Tests
Run unit tests locally before opening a PR. See `docs/ci-cd.md`.

## Deploy
Deployment is documented in `docs/installation.md`.
