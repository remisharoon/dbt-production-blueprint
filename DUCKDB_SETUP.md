# DuckDB Setup Summary

This document summarizes the changes made to configure the dbt project for DuckDB usage.

## What Changed

### 1. Package Configuration
- **Removed**: `dbt-labs/dbt-duckdb` from [`packages.yml`](packages.yml) (it's not a dbt package)
- **Updated**: Changed `calogica/dbt_expectations` to `metaplane/dbt_expectations` in [`packages.yml`](packages.yml) (the package was migrated)
- **Added**: `dbt-duckdb>=1.8.0,<2.0.0` to [`requirements.txt`](requirements.txt) (installed via pip)

### 2. Profile Configuration
- **Created**: [`profiles.yml`](profiles.yml) with DuckDB configuration for `dev` and `ci` targets
- **Modified**: [`dbt_project.yml`](dbt_project.yml) to use `dbt_production_blueprint_duckdb` profile

### 3. Deprecation Fixes
- **Fixed**: All `accepted_values` tests in [`models/staging/schema.yml`](models/staging/schema.yml) to use the new `arguments` property format

### 4. Documentation
- **Created**: [`SETUP_GUIDE.md`](SETUP_GUIDE.md) with comprehensive DuckDB setup instructions
- **Updated**: [`README.md`](README.md) with DuckDB quick start
- **Created**: [`quickstart.sh`](quickstart.sh) automated setup script

### 5. Git Configuration
- **Updated**: [`.gitignore`](.gitignore) to ignore `*.duckdb` and `*.duckdb.wal` files

## How It Works

### DuckDB Adapter Installation
The DuckDB adapter is a Python package that gets installed via pip:
```bash
pip install dbt-duckdb
```

It's **not** a dbt package (which would be installed via `dbt deps`). This is why it's in [`requirements.txt`](requirements.txt) and not [`packages.yml`](packages.yml).

### dbt Packages
The [`packages.yml`](packages.yml) file contains dbt packages that are installed via `dbt deps`:
- `dbt-labs/dbt_utils` - Utility macros and functions
- `metaplane/dbt_expectations` - Data quality tests (migrated from calogica)
- `dbt-labs/audit_helper` - Audit and testing utilities

### Profile Configuration
The [`profiles.yml`](profiles.yml) file defines connection settings:
```yaml
dbt_production_blueprint_duckdb:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: dev.duckdb
      schema: main
      threads: 4
```

## Quick Start

### Option 1: Automated Script
```bash
./quickstart.sh
```

### Option 2: Manual Steps
```bash
# Install Python dependencies (includes dbt-duckdb adapter)
pip install -r requirements.txt

# Install dbt packages
dbt deps

# Load seed data
dbt seed

# Build all models
dbt build

# Generate documentation
dbt docs generate
dbt docs serve
```

## Troubleshooting

### Error: "Package dbt-labs/dbt-duckdb was not found"
**Solution**: The DuckDB adapter is installed via pip, not as a dbt package. Run:
```bash
pip install dbt-duckdb
```

### Error: "calogica/dbt_expectations is deprecated"
**Solution**: The package has been migrated to `metaplane/dbt_expectations`. This has been updated in [`packages.yml`](packages.yml).

### Error: "Profile not found"
**Solution**: Ensure [`profiles.yml`](profiles.yml) exists in the project root or in `~/.dbt/`.

### Error: "Database file locked"
**Solution**: Close any open connections to the DuckDB file or remove it:
```bash
rm dev.duckdb
```

## Switching to Snowflake (Production)

To use Snowflake instead of DuckDB:

1. Update [`dbt_project.yml`](dbt_project.yml):
   ```yaml
   profile: dbt_production_blueprint_snowflake
   ```

2. Create `~/.dbt/profiles.yml` with your Snowflake credentials (see [`profiles_template.yml`](profiles_template.yml))

3. Install the Snowflake adapter:
   ```bash
   pip install dbt-snowflake
   ```

4. Run dbt commands as usual

## Benefits of DuckDB

- **No external database required** - Everything runs locally
- **Fast performance** - In-process SQL database
- **Easy setup** - No authentication or configuration needed
- **Perfect for demos and testing** - Quick to spin up and tear down
- **Single file database** - Easy to backup and share

## When to Use DuckDB vs Snowflake

| Use Case | Recommended |
|----------|------------|
| Local development | DuckDB |
| Testing and demos | DuckDB |
| Documentation generation | DuckDB |
| Production workloads | Snowflake |
| Multi-user environments | Snowflake |
| Large-scale data processing | Snowflake |

## Additional Resources

- [dbt DuckDB Adapter Documentation](https://docs.getdbt.com/reference/warehouse-setups/duckdb-setup)
- [DuckDB Documentation](https://duckdb.org/docs/)
- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Detailed setup instructions
- [README.md](README.md) - Project overview and quick start
