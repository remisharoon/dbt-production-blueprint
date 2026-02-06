# dbt Production Blueprint

A production-grade dbt project that demonstrates real-world enterprise patterns for an e-commerce (retail) warehouse on Snowflake. This repository is intentionally "kitchen sink" and includes staging cleanup, intermediate logic, marts, incremental models, snapshots, macros, custom tests, exposures, selectors, operational hooks, and a full documentation site.

**Key Features**
- Snowflake-optimized SQL with dbt 1.8+.
- Layered model design: `staging` -> `intermediate` -> `marts`.
- Incremental fact processing with soft-delete handling.
- SCD Type 2 snapshots for customer history.
- Dynamic SQL generation via macros.
- Custom generic tests and data tests.
- Docs blocks and model descriptions.
- Run hooks and access grants.
- State-based CI selectors for `state:modified` workflows.
- MkDocs site with embedded dbt docs.

**Project Structure**
```
models/
  staging/
  intermediate/
  marts/
    core/
    finance/
seeds/
macros/
tests/
analyses/
snapshots/
```

**Prerequisites**
- `dbt-core>=1.8` and `dbt-snowflake` installed.
- A Snowflake account and a dbt profile named `dbt_production_blueprint`.

**Quick Start**
```bash
# Install dependencies
dbt deps

# Load seed data
dbt seed

# Build everything (models + tests + snapshots)
dbt build
```

**Common Workflows**
```bash
# Run only staging
dbt run --select staging_only

# Run marts only
dbt run --select marts_only

# Build modified nodes using a prior state
dbt build --select state_modified_plus --state path/to/previous/manifest

# Build just modified models (no downstream)
dbt build --select state_modified --state path/to/previous/manifest
```

**Selectors**
Selectors live in `selectors.yml` and include:
- `state_modified`, `state_modified_plus`, `state_modified_configs`
- `staging_only`, `marts_only`

**Seeds**
Seed data is intentionally dirty to showcase cleaning logic and data quality testing.
- `seeds/raw_customers.csv`
- `seeds/raw_orders.csv`
- `seeds/raw_payments.csv`

**Staging Models**
- `stg_customers`, `stg_orders`, `stg_payments`
- Standardized naming, type casting, null handling
- Surrogate keys via `dbt_utils.generate_surrogate_key`

**Intermediate Models**
- `int_order_payments` joins orders and payments with rollups.
- `int_order_status_categorized` demonstrates Jinja loop logic for CASE generation.

**Marts**
- `dim_customers` is a deduped dimension with a post-hook grant.
- `fct_orders` is incremental with merge, soft-deletes, and partitioned updates via `updated_at`.
- `fct_revenue` and `fct_customer_ltv` provide finance and lifecycle metrics.
- `region_summary` is generated dynamically by a macro.

**Snapshots**
- `snap_customers_history` is SCD Type 2 using `updated_at`.

**Macros**
- `log_run_start()` inserts run metadata into `audit_run` (on-run-start).
- `order_status_case()` generates CASE logic via Jinja.
- `generate_region_summary_sql()` builds dynamic SQL per region.

**Testing**
- Generic tests for `not_null`, `unique`, and `relationships` are applied across layers.
- `dbt_expectations` tests validate numeric ranges.
- Custom generic test `is_alphanumeric` for ID columns.
- Data test `revenue_consistency` validates core vs. finance revenue.

Note: some tests are set to `severity: warn` to demonstrate real-world data quality issues without failing every run.

**Documentation**
- Model and column-level docs live in `schema.yml` files.
- Doc blocks are defined in `models/docs.md` for `Total Revenue` and `LTV`.
- MkDocs site configuration is in `mkdocs.yml` and embeds dbt docs from `docs/dbt_artifacts`.

**Exposures**
Defined in `models/exposures.yml` for finance dashboards and customer LTV applications.

**Operational Hooks**
- `on-run-start` inserts run metadata into `audit_run` in the target schema.
- `post-hook` on `dim_customers` grants read access to role `reporter`.

**Documentation Site (MkDocs + dbt Docs)**
1. Install docs tooling.
```bash
pip install mkdocs mkdocs-material mkdocs-minify-plugin mkdocs-git-revision-date-localized-plugin
```
2. Generate dbt docs into the MkDocs tree.
```bash
dbt docs generate --target-dir docs/dbt_artifacts
```
3. Serve locally.
```bash
mkdocs serve
```

If your local environment does not have a warehouse connection, you can run:
```bash
dbt docs generate --target-dir docs/dbt_artifacts --empty-catalog
```

**GitHub Pages (Docs Deployment)**
Enable GitHub Pages with Actions:
1. Go to **Settings > Pages** in your GitHub repo.
2. Under **Source**, select **GitHub Actions**.
3. Push to `main` to trigger `.github/workflows/deploy-docs.yml`.

**CI Profiles for dbt Docs**
The workflow supports an optional secret named `DBT_PROFILES_YML` that should contain the full contents of a `profiles.yml`. This allows `dbt docs generate` to run in CI without checking profiles into the repo. If a live connection is not available, the workflow falls back to `--empty-catalog` but still requires a valid profile structure.

**Where to Add Things**
- New sources: `models/staging/_sources.yml`
- New staging models: `models/staging/`
- New business logic: `models/intermediate/`
- New marts: `models/marts/core` or `models/marts/finance`
- New macros: `macros/`
- New tests: `tests/`
- New snapshots: `snapshots/`

**Profiles Example**
A `profiles.yml` is not included. Create a local profile named `dbt_production_blueprint`.

Example profile key structure:
```yaml
# ~/.dbt/profiles.yml
# dbt_production_blueprint:
#   target: dev
#   outputs:
#     dev:
#       type: snowflake
#       account: <account>
#       user: <user>
#       password: <password>
#       role: <role>
#       database: <database>
#       warehouse: <warehouse>
#       schema: <schema>
#       threads: 4
```

**Recommended CI Pattern**
```bash
# Generate current state
dbt build

# Save manifest.json as CI baseline
# Next run:
dbt build --select state_modified_plus --state path/to/previous/manifest --defer
```

**License**
See `LICENSE`.
