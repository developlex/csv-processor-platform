# Data Contracts

## Contract Authority
The formats and semantics defined in this document are part of the platform contract.

Change Control: Any change to:
- S3 key layout, or
- `meta.json` schema/semantics, or
- `profile.json` schema/semantics
requires:
- SSOT version increment, and
- new freeze marker entry, and
- explicit compatibility note (backward compatible vs breaking).
This document defines externally observable data behavior and is considered part of the public platform contract.

## S3 Key Contracts
All artifacts are stored in S3 with the following exact keys:
- `raw/{dataset_id}/source.csv`
- `meta/{dataset_id}.json`
- `profiles/{dataset_id}/profile.json`

Notes:
- `dataset_id` is a UUIDv4 string.
- Keys are case-sensitive and must be exact.
`dataset_id` values are immutable and must not be reused. Artifacts for a given `dataset_id` may be overwritten only as part of a valid lifecycle transition for that dataset.

## `meta.json` Schema

Purpose: Track dataset state, source metadata, and processing outcomes.

Required top-level fields:
- `contract_version` (string) : Must be `v1`.
- `dataset_id` (string) : UUIDv4.
- `status` (string) : One of `UPLOADED`, `PROCESSING`, `READY`, `FAILED`.
- `created_at` (string) : ISO-8601 UTC timestamp.
- `updated_at` (string) : ISO-8601 UTC timestamp.
- `source` (object) : Source file metadata (see below).
- `processing` (object) : Processing metadata (see below).

`source` object (required fields):
- `original_filename` (string)
- `content_type` (string) : Must be `text/csv`.
- `content_length_bytes` (integer) : File size at upload time.
- `etag` (string) : S3 ETag for `raw/{dataset_id}/source.csv`.
- `delimiter` (string) : Must be `,` (comma).

`processing` object (required fields):
- `started_at` (string|null) : ISO-8601 UTC timestamp when worker starts.
- `completed_at` (string|null) : ISO-8601 UTC timestamp when worker completes.
- `rows` (integer|null) : Total rows processed (excluding header).
- `columns` (integer|null) : Total columns detected.
- `profile_key` (string|null) : S3 key for profile output. Must be `profiles/{dataset_id}/profile.json` when `status=READY`.
- `error` (object|null) : Present only when `status=FAILED` (see below).

`error` object (required when present):
- `code` (string) : Stable, uppercase error code.
- `message` (string) : Human-readable, single-line message.

Semantics:
- `created_at`: Time the dataset record was first created (upload accepted).
- `updated_at`: Time of last state mutation.
- `started_at`: Time worker began processing.
- `completed_at`: Time worker finished processing (success or failure).
- `status=UPLOADED`: `started_at`, `completed_at`, `rows`, `columns`, `profile_key`, `error` must be `null`.
- `status=PROCESSING`: `started_at` must be set; others may be `null`.
- `status=READY`: `completed_at`, `rows`, `columns`, `profile_key` must be set; `error` must be `null`.
- `status=FAILED`: `completed_at` and `error` must be set; `profile_key` must be `null`.
Error codes must be chosen from a finite, documented set (for example: `CSV_PARSE_ERROR`, `CSV_TOO_LARGE`, `SCHEMA_INFERENCE_FAILED`, `INTERNAL_ERROR`). Error codes are part of the contract and must not change meaning.

## `profile.json` Schema

Purpose: Provide deterministic column-level profiling for the dataset.

Required top-level fields:
- `contract_version` (string) : Must be `v1`.
- `dataset_id` (string) : UUIDv4.
- `generated_at` (string) : ISO-8601 UTC timestamp.
- `rows` (integer) : Total rows processed (excluding header).
- `columns` (array) : Column descriptors (see below).

Column descriptor (required fields):
- `index` (integer) : Zero-based column index.
- `name` (string) : Column header name.
- `inferred_type` (string) : One of `string`, `integer`, `float`, `boolean`, `date`, `datetime`, `empty`, `mixed`.
- `nullable` (boolean) : `true` if any null/empty value observed.
- `count` (integer) : Non-null value count for the column.
- `null_count` (integer) : Null/empty value count for the column.
- `distinct_count` (integer) : Count of distinct non-null values.
- `stats` (object) : Type-specific stats (see below).

Null definition:
- An empty string after trimming whitespace is null.
Whitespace trimming is applied after delimiter parsing.

Type definitions:
- `empty`: Column contains only null values.
- `mixed`: Column contains non-null values of incompatible inferred types.

Type-specific stats:

For numeric types (`integer`, `float`):
- `min` (number)
- `max` (number)
- `mean` (number)
- `stddev` (number)
- `p50` (number)
- `p95` (number)

For non-numeric types (`string`, `boolean`, `date`, `datetime`, `mixed`, `empty`):
- `min_length` (integer|null) : Min string length (null if no non-null values).
- `max_length` (integer|null) : Max string length (null if no non-null values).
- `top_values` (array) : Up to 5 most frequent values, each `{value: string, count: integer}`.

Rounding rules:
- All floating-point outputs in `profile.json` must be rounded to 4 decimal places.
Rounding is applied after all aggregations are computed, not incrementally.

Ordering:
- `columns` must be ordered by `index` ascending.

Distinct counts:
- `distinct_count` may be approximate for large datasets. If approximate, accuracy guarantees must be documented in `docs/runtime.md`.

Percentiles:
- Percentiles may be computed using approximation algorithms for large datasets. Exactness is not guaranteed unless explicitly stated.

Top values ordering:
- `top_values` must be ordered by descending frequency. Ties may be broken arbitrarily but deterministically.

## Compatibility Notes
Any change to a field name, type, allowed values, or semantics is a breaking change unless explicitly declared backward compatible in a freeze marker.
Additive fields may be backward compatible only if explicitly declared so in a freeze marker.

## Versioning
`contract_version` is a hard lock. Only `v1` is valid for this MVP.
Consumers must reject any `contract_version` they do not explicitly support.

## Runtime Constraints
All guarantees in this document are subject to runtime limits defined in `docs/runtime.md`.
Exceeding those limits must result in `status=FAILED` with an appropriate error code.
