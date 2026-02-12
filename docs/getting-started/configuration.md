# Configuration Guide

Detailed configuration for dbt Production Blueprint.

## Project Configuration (dbt_project.yml)

The main project configuration file defines paths, variables, and model settings.

### Key Settings

```yaml title="dbt_project.yml"
name: dbt_production_blueprint
version: 1.0.0
config-version: 2

# Profile to use (references profiles.yml)
profile: dbt_production_blueprint_duckdb

# Directory paths
model-paths: ["models"]
analysis-paths: ["analyses"]
test-paths: ["tests"]
seed-paths: ["seeds"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]
docs-paths: ["docs"]
```

### Model Materialization

```yaml title="dbt_project.yml"
models:
  dbt_production_blueprint:
    staging:
      +materialized: view
      +schema: stg
    intermediate:
      +materialized: view
      +schema: int
    marts:
      core:
        +materialized: table
        +schema: mart_core
      finance:
        +materialized: table
        +schema: mart_finance
```

### Contracts and Schema

```yaml title="dbt_project.yml"
models:
  dbt_production_blueprint:
    +contract:
      enforced: true
    +on_schema_change: fail
```

!!! tip "Contract Enforcement"
    Contracts ensure that column data types match the schema definition. If a model produces a different type, the run fails. This prevents breaking changes.

### Documentation Persistence

```yaml title="dbt_project.yml"
models:
  dbt_production_blueprint:
    +persist_docs:
      relation: true
      columns: true
```

This persists documentation to the data warehouse, making it available in BI tools.

## Variables

### Region Configuration

Set in `dbt_project.yml`:

```yaml title="dbt_project.yml"
vars:
  regions:
    - North America
    - EMEA
    - APAC
    - LATAM
```

Used in `region_summary` model for dynamic SQL generation.

### Using Variables in Models

```jinja
-- region_summary.sql
{{ generate_region_summary_sql(var('regions')) }}
```

### Overriding Variables

```bash
# Override at runtime
dbt run --vars '{regions: ["North America", "EMEA"]}'

# Or in dbt_project.yml
dbt run --vars regions:['North America']
```

## Loading Data

### Seed Data

```bash
# Load seed files
dbt seed

# Full refresh (reload all data)
dbt seed --full-refresh
```

Seed files:
- `seeds/raw_customers.csv` (11 rows)
- `seeds/raw_orders.csv` (12 rows)
- `seeds/raw_payments.csv` (12 rows)

### Seed Configuration

```yaml title="dbt_project.yml"
seeds:
  dbt_production_blueprint:
    +schema: seeds
    +materialized: table
```

## Running Models

### Full Build

```bash
dbt build
```

This runs:
1. All seeds
2. All models in dependency order
3. All tests
4. All snapshots

### Selective Runs

```bash
# Run specific model
dbt run --select stg_customers

# Run model + all downstream
dbt run --select stg_customers+

# Run model + all upstream
dbt run --select +stg_customers

# Run staging models only
dbt run --select staging_only

# Run marts only
dbt run --select marts_only

# Exclude specific models
dbt run --exclude fct_orders
```

## State-Based Selection

For efficient CI/CD, use state comparison to only build modified nodes.

### Setup

```bash
# 1. Save current state
dbt build

# 2. Copy manifest.json to state directory
cp target/manifest.json state/previous/

# 3. Make code changes...

# 4. Build only modified nodes + downstream
dbt build --select state_modified_plus --state state/previous/ --defer
```

### Selectors

Pre-defined selectors in `selectors.yml`:

| Selector | Description |
|----------|-------------|
| `state_modified` | Only modified nodes |
| `state_modified_plus` | Modified nodes + downstream |
| `state_modified_configs` | Nodes with config changes |
| `staging_only` | All staging models |
| `marts_only` | All marts models |

## Testing

### Run All Tests

```bash
dbt test
```

### Run Specific Tests

```bash
# Run all generic tests
dbt test --select test_type:generic

# Run all singular tests
dbt test --select test_type:singular

# Run tests for specific model
dbt test --select stg_customers

# Run tests + downstream models
dbt test --select stg_customers+
```

### Test Severity

Some tests use `severity: warn` because seed data has intentional issues:

```yaml title="models/staging/schema.yml"
models:
  - name: stg_customers
    columns:
      - name: customer_id
        tests:
          - not_null
          - unique:
              severity: warn  # Known duplicates in seed data
```

!!! info "Expected Warnings"
    These warnings are intentional and demonstrate data quality monitoring. They won't fail the build.

## Debugging

### Verbose Output

```bash
# Show detailed SQL and execution
dbt --debug run
```

### Dry Run

```bash
# Show SQL without executing (simulated)
dbt compile
```

### List Models

```bash
# Show all models
dbt ls

# Show with dependencies
dbt ls --select stg_customers+
```

## Environment Configuration

### Development Environment

```yaml title="profiles.yml"
dbt_production_blueprint_duckdb:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: dev.duckdb
      schema: dev
      threads: 4
```

### CI/CD Environment

```yaml title="profiles.yml"
dbt_production_blueprint_duckdb:
  target: ci
  outputs:
    ci:
      type: duckdb
      path: ':memory:'
      schema: ci
      threads: 2
```

### Production Environment

```yaml title="profiles.yml"
dbt_production_blueprint_snowflake:
  target: prod
  outputs:
    prod:
      type: snowflake
      account: prod.snowflakecomputing.com
      user: dbt_prod
      password: '{{ env_var("DBT_SNOWFLAKE_PASSWORD") }}'
      role: prod_role
      database: production
      warehouse: prod_wh
      schema: analytics
      threads: 8
```

## Best Practices

### Profile Management

1. **Never commit passwords** - Use environment variables
2. **Use separate profiles** - One for dev, staging, prod
3. **Limit threads** - Don't overwhelm the warehouse
4. **Test connections** - Run `dbt debug` after changes

### Variable Usage

1. **Document variables** - Add descriptions in schema.yml
2. **Provide defaults** - Set sensible defaults in dbt_project.yml
3. **Override carefully** - Document when runtime overrides are needed
4. **Validate inputs** - Add tests for variable values

### State-Based CI

1. **Always save state** - Copy manifest.json after successful builds
2. **Use --defer** - Avoid rebuilding unchanged upstream models
3. **Test changes** - Run modified models before merging
4. **Monitor failures** - Track state comparison failures

## Next Steps

- [Architecture Overview](../architecture/index.md) - Understand the data model
- [Testing Strategy](../reference/tests.md) - Learn about comprehensive testing
- [CI/CD Setup](../operations/ci-cd.md) - Configure automated deployment
