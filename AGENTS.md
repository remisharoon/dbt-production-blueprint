# AGENTS.md

This repository is a production-grade dbt blueprint for Snowflake. Use this file as the source of truth for working conventions, run commands, and project layout.

**Stack**
- Warehouse: Snowflake
- dbt: 1.8+
- Project domain: E-commerce (Retail)

**Key Files**
- `dbt_project.yml` for project config, contracts, schemas, hooks.
- `packages.yml` for dbt packages.
- `selectors.yml` for state-based selection.
- `models/docs.md` for doc blocks.
- `models/exposures.yml` for dashboards/apps.
- `snapshots/` for SCD Type 2 logic.

**Run Commands**
```bash
# Install dependencies
dbt deps

# Load seed data
dbt seed

# Build everything (models + tests + snapshots)
dbt build

# Run modified nodes (state-based)
dbt build --select state_modified_plus --state path/to/previous/manifest
```

**State-Based CI**
- Use selectors in `selectors.yml`.
- `state_modified` requires `--state` pointing at a prior `manifest.json`.
- Prefer `state_modified_plus` with `--defer` for CI.

**Conventions**
- Staging models: `stg_*` in `models/staging/`.
- Intermediate models: `int_*` in `models/intermediate/`.
- Marts: `dim_*` and `fct_*` in `models/marts/core` or `models/marts/finance`.
- Add/maintain `schema.yml` descriptions and tests for every model.
- Column `data_type` is required because contracts are enforced in `dbt_project.yml`.

**Data Quality**
- Seeds intentionally include data issues for demo purposes.
- Several tests are set to `severity: warn` to avoid failing the full build on known bad data.
- Custom generic test: `tests/is_alphanumeric.sql`.
- Data test for revenue parity: `tests/revenue_consistency.sql`.

**Operational Hooks**
- `on-run-start` inserts run metadata into `audit_run` via `macros/audit.sql`.
- `dim_customers` includes a post-hook grant: `grant select on {{ this }} to role reporter`.

**Adding New Models**
- Place SQL in the appropriate layer directory.
- Add or update the corresponding `schema.yml` with full documentation and tests.
- If materializing as incremental, include `unique_key`, strategy, and update logic.

**Snapshots**
- Snapshot logic lives in `snapshots/`.
- `snap_customers_history` uses `updated_at` and `strategy: timestamp`.

**Docs**
- Doc blocks live in `models/docs.md`.
- Use `{{ doc('...') }}` references in model descriptions.

**Profiles**
- `profiles.yml` is not included. Create a local profile named `dbt_production_blueprint` in `~/.dbt/profiles.yml`.

**Safe Changes**
- Do not remove seeds or tests without replacing their intent.
- Keep model contracts and column data types aligned with SQL output.
- Update exposures when marts or dashboards change.
