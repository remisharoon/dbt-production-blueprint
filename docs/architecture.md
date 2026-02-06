# Project Architecture

This repository is intentionally designed as a "kitchen sink" for production-grade dbt patterns on Snowflake. The goal is to demonstrate how enterprise teams structure, document, test, and operate dbt projects at scale.

## Layered Model Architecture

Staging (`models/staging`): Raw sources are standardized, typed, and lightly cleaned. Surrogate keys are generated and raw columns are preserved where useful.

Intermediate (`models/intermediate`): Business logic is normalized and reusable. Complex joins, rollups, and status categorization are implemented once and reused in marts.

Marts (`models/marts/core`, `models/marts/finance`): Final, consumer-facing models optimized for analytics, reporting, and data products. Core marts contain dimensions and facts; finance marts contain revenue aggregates.

## Incremental Processing

`fct_orders` is an incremental model using a merge strategy keyed by `order_id`, with updates filtered by `updated_at`. Soft-deleted records are tracked using `is_deleted`, `deleted_at`, and `net_order_total` to preserve history without inflating revenue.

## SCD Type 2 (Snapshots)

`snap_customers_history` tracks customer changes over time using the `timestamp` strategy on `updated_at`. This produces a full change history while preserving the current state in `dim_customers`.

## Dynamic SQL Generation

Macros generate SQL dynamically to support patterns like region-level rollups without hand-writing repetitive queries. This is used for the `region_summary` model in the finance mart.

## Testing & Quality

The project uses built-in dbt tests (`not_null`, `unique`, `relationships`), `dbt_expectations` for numeric and range checks, custom generic tests for ID validation, and cross-mart reconciliation tests for revenue consistency.

## Documentation & Exposures

Column-level documentation is enforced using dbt contracts. Doc blocks define metrics like **Total Revenue** and **LTV**. Exposures document key dashboards and applications that depend on models.
