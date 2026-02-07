# Quick Reference Guide

This is a quick reference for common commands and configurations in the dbt Production Blueprint project.

## Installation Commands

```bash
# Install Python dependencies (includes dbt-duckdb adapter)
pip install -r requirements.txt

# Install dbt packages
dbt deps

# Verify installation
dbt debug
```

**Important**: Always run `pip install -r requirements.txt` BEFORE `dbt deps`.

## Common dbt Commands

### Development Workflow
```bash
# Load seed data
dbt seed

# Run all models
dbt run

# Run all tests
dbt test

# Build everything (models + tests + snapshots)
dbt build

# Run with specific target
dbt build --target ci
```

### Selective Execution
```bash
# Run specific model
dbt run --select stg_customers

# Run all staging models
dbt run --select stg_*

# Run all intermediate models
dbt run --select int_*

# Run all marts
dbt run --select marts_*

# Run tests for specific model
dbt test --select stg_customers

# Run with freshness checks
dbt source freshness
```

### State-Based CI
```bash
# Run modified nodes (requires --state flag)
dbt build --select state_modified_plus --state path/to/previous/manifest

# Run modified nodes with defer
dbt build --select state_modified_plus --state path/to/previous/manifest --defer
```

### Documentation
```bash
# Generate documentation
dbt docs generate

# Serve documentation locally
dbt docs serve

# Generate with empty catalog (no warehouse connection needed)
dbt docs generate --empty-catalog
```

### Debugging
```bash
# Check configuration and connection
dbt debug

# Show compilation details
dbt compile --select stg_customers

# Dry run (show what would run)
dbt run --select stg_customers --dry-run

# Run with verbose output
dbt run --debug
```

## Project Structure

```
dbt-production-blueprint/
├── profiles.yml              # DuckDB profiles configuration
├── dbt_project.yml          # Project configuration
├── packages.yml             # dbt packages (dbt_utils, dbt_expectations, audit_helper)
├── requirements.txt         # Python dependencies (dbt-core, dbt-duckdb, mkdocs)
├── quickstart.sh           # Automated setup script
├── models/                 # dbt models
│   ├── staging/           # Staging layer (stg_*)
│   ├── intermediate/      # Intermediate layer (int_*)
│   └── marts/           # Marts layer (dim_*, fct_*)
├── seeds/               # CSV seed data
├── snapshots/          # SCD Type 2 snapshots
├── tests/              # Custom tests
├── macros/             # Custom macros
├── analyses/           # Ad-hoc analyses
└── docs/               # MkDocs documentation
```

## Configuration Files

### profiles.yml
DuckDB configuration for local development:
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

### dbt_project.yml
Project configuration:
```yaml
name: dbt_production_blueprint
version: '1.0.0'
config-version: 2
profile: dbt_production_blueprint_duckdb
```

### packages.yml
dbt packages (installed via `dbt deps`):
```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: [">=1.1.0", "<2.0.0"]
  - package: metaplane/dbt_expectations
    version: [">=0.10.0", "<0.11.0"]
  - package: dbt-labs/audit_helper
    version: [">=0.11.0", "<0.12.0"]
```

### requirements.txt
Python dependencies (installed via `pip`):
```txt
dbt-core>=1.8.0,<2.0.0
dbt-duckdb>=1.8.0,<2.0.0
mkdocs>=1.5.0
mkdocs-material>=9.0.0
```

## Model Layers

### Staging (`stg_*`)
- Location: `models/staging/`
- Materialization: View
- Purpose: Raw data cleaning and standardization
- Examples: `stg_customers`, `stg_orders`, `stg_payments`

### Intermediate (`int_*`)
- Location: `models/intermediate/`
- Materialization: View
- Purpose: Business logic and transformations
- Examples: `int_order_payments`, `int_order_status_categorized`

### Marts (`dim_*`, `fct_*`)
- Location: `models/marts/`
- Materialization: Table
- Purpose: Business-ready data assets
- Examples: `dim_customers`, `fct_orders`, `fct_revenue`, `fct_customer_ltv`

## Common Issues and Solutions

### "No module named 'dbt.adapters.duckdb'"
```bash
pip install dbt-duckdb
```

### "Package dbt-labs/dbt-duckdb was not found"
This is expected - dbt-duckdb is installed via pip, not via `dbt deps`.

### "Profile not found"
Ensure [`profiles.yml`](profiles.yml) exists in project root.

### "Database file locked"
```bash
rm dev.duckdb
```

## Documentation

- [`README.md`](README.md) - Project overview
- [`INSTALL.md`](INSTALL.md) - Step-by-step installation
- [`SETUP_GUIDE.md`](SETUP_GUIDE.md) - Detailed setup and configuration
- [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) - Common issues and solutions
- [`DUCKDB_SETUP.md`](DUCKDB_SETUP.md) - DuckDB-specific information
- [`AGENTS.md`](AGENTS.md) - Project conventions and guidelines

## DuckDB vs Snowflake

| Feature | DuckDB | Snowflake |
|---------|---------|------------|
| Use Case | Local development, testing, demos | Production workloads |
| Installation | `pip install dbt-duckdb` | `pip install dbt-snowflake` |
| Configuration | [`profiles.yml`](profiles.yml) in project | `~/.dbt/profiles.yml` |
| Cost | Free | Pay-per-use |
| Performance | Fast for small datasets | Scalable for large datasets |
| Multi-user | No | Yes |

## Switching to Snowflake

1. Install Snowflake adapter:
   ```bash
   pip install dbt-snowflake
   ```

2. Update [`dbt_project.yml`](dbt_project.yml):
   ```yaml
   profile: dbt_production_blueprint_snowflake
   ```

3. Create `~/.dbt/profiles.yml` with Snowflake credentials (see [`profiles_template.yml`](profiles_template.yml))

4. Run dbt commands as usual

## Useful Tips

### Virtual Environment
```bash
# Create
python3 -m venv venv

# Activate (macOS/Linux)
source venv/bin/activate

# Activate (Windows)
venv\Scripts\activate

# Deactivate
deactivate
```

### Clean Slate
```bash
# Remove database files
rm *.duckdb *.duckdb.wal

# Remove dbt artifacts
rm -rf target/ dbt_packages/ logs/

# Reinstall dependencies
pip install -r requirements.txt --force-reinstall
dbt deps --clean
```

### Query DuckDB Directly
```bash
# Install DuckDB CLI
pip install duckdb

# Query database
duckdb dev.duckdb
```

## Keyboard Shortcuts (VS Code)

| Command | Shortcut |
|---------|----------|
| Open terminal | `Ctrl + `` ` |
| Toggle sidebar | `Ctrl + B` |
| Command palette | `Ctrl + Shift + P` |
| Quick open file | `Ctrl + P` |

## Environment Variables

You can use environment variables in profiles.yml:
```yaml
password: "{{ env_var('DBT_SNOWFLAKE_PASSWORD') }}"
```

Set environment variable:
```bash
export DBT_SNOWFLAKE_PASSWORD='your_password'
```

## Git Commands

```bash
# Check status
git status

# Add files
git add .

# Commit
git commit -m "Your message"

# Push
git push

# Pull
git pull
```

## Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [DuckDB Documentation](https://duckdb.org/docs/)
- [dbt DuckDB Adapter](https://docs.getdbt.com/reference/warehouse-setups/duckdb-setup)
- [dbt Snowflake Adapter](https://docs.getdbt.com/reference/warehouse-setups/snowflake-setup)
