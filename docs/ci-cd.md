# CI/CD

## Purpose
This document defines the CI contract for the MVP. CI is the enforcement layer; no deploy or merge may bypass these rules.

## Required for MVP Acceptance (Must Pass)
- Unit tests for profiler logic, data contracts, and S3 key layout
- Lint/format checks (if enabled)
- Container image build for API and Worker

## Blocking Failures
The following failures must block merge and deploy:
- Any unit test failure
- Any lint/format failure (if enabled)
- Any image build failure

## Required Checks Before Merge
- All required tests pass
- No failing required checks
- CI status is green

## Image Build Rules
- Images are immutable and tagged by commit SHA
- Image builds must be reproducible in CI

## Deployment Strategy
Deployment must follow the blue/green + canary strategy defined in `docs/deployment-strategy.md`.

## Secrets and Credentials
- Secrets must be stored only in GitHub Secrets
- Secrets must not be committed to the repo
- Required secrets for deploy workflow:
  - `AWS_REGION`
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`

## Deployment Workflow
- `deploy.yml` runs `terraform plan` on pull requests.
- `deploy.yml` runs `terraform apply` on `main` and requires manual approval via the `dev` environment.

## Not Required for MVP (Explicitly Deferred)
- Integration tests (LocalStack or AWS dev)
- Load/performance tests
- Chaos/failure injection
- Security scanning beyond basic secret scanning

## Terraform Apply Rules (Deferred)
Terraform apply is deferred for the MVP and is not required in CI until explicitly enabled by a new freeze marker.
