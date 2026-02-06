# DuckDB Setup Guide for dbt Production Blueprint

This guide helps you set up the dbt project using DuckDB for local development, testing, and documentation generation.

## Quick Start

### 1. Install Dependencies

```bash
# Install dbt packages (includes DuckDB adapter)
dbt deps
```

### 2. Verify Configuration

The project is pre-configured to use DuckDB. Check that [`profiles.yml`](profiles.yml) exists in the project root:

```bash
cat profiles.yml
```

### 3. Run dbt Commands

```bash
# Load seed data
dbt seed

# Build all models
dbt build

# Run specific targets
dbt build --target ci
```

## Configuration Details

### Project Profile

The [`dbt_project.yml`](dbt_project.yml) file specifies:
```yaml
profile: dbt_production_blueprint_duckdb
```

### Profiles Configuration

The [`profiles.yml`](profiles.yml) file defines three targets:

| Target | Database File | Use Case |
|--------|--------------|----------|
| `dev` | `dev.duckdb` | Local development |
| `ci` | `ci.duckdb` | CI/CD testing |
| `snowflake` | N/A | Production Snowflake (requires credentials) |

### DuckDB Adapter

The DuckDB adapter is installed via pip (see [`requirements.txt`](requirements.txt)):
```txt
dbt-duckdb>=1.8.0,<2.0.0
```

Note: The DuckDB adapter is a Python package, not a dbt package, so it's installed via pip rather than `dbt deps`.

## DuckDB vs Snowflake

### DuckDB (Default - For Demo/Testing)
- ✅ No external database required
- ✅ Fast, in-process SQL database
- ✅ Perfect for local development and testing
- ✅ Single file database (`.duckdb`)
- ✅ No authentication needed
- ❌ Not suitable for production workloads
- ❌ Limited to single-machine processing

### Snowflake (Production)
- ✅ Cloud-native data warehouse
- ✅ Scalable for production workloads
- ✅ Multi-user support
- ✅ Advanced security features
- ❌ Requires account and credentials
- ❌ Costs money to run

## Switching to Snowflake (Optional)

If you want to use Snowflake instead of DuckDB:

### 1. Update dbt_project.yml

Change the profile:
```yaml
profile: dbt_production_blueprint_snowflake
```

### 2. Create ~/.dbt/profiles.yml

```bash
mkdir -p ~/.dbt
cat > ~/.dbt/profiles.yml << 'EOF'
dbt_production_blueprint_snowflake:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: <your_account_identifier>
      user: <your_username>
      password: <your_password>
      role: <your_role>
      database: <your_database>
      warehouse: <your_warehouse>
      schema: dbt_dev
      threads: 4
      query_tag: dbt_production_blueprint
EOF
```

### 3. Replace Placeholders

Edit `~/.dbt/profiles.yml` and replace:
- `<your_account_identifier>` - e.g., `xy12345.us-east-1`
- `<your_username>` - Your Snowflake username
- `<your_password>` - Your Snowflake password
- `<your_role>` - e.g., `ACCOUNTADMIN`, `SYSADMIN`
- `<your_database>` - e.g., `analytics`
- `<your_warehouse>` - e.g., `compute_wh`

### 4. Test Connection

```bash
dbt debug
```

## Common dbt Commands

### Development Workflow

```bash
# Install/update packages
dbt deps

# Load seed data (CSV files)
dbt seed

# Run all models, tests, and snapshots
dbt build

# Run only modified models (state-based)
dbt build --select state_modified_plus

# Run with specific target
dbt build --target ci

# Generate documentation
dbt docs generate

# Serve documentation locally
dbt docs serve
```

### Selective Execution

```bash
# Run specific model
dbt run --select stg_customers

# Run all staging models
dbt run --select stg_*

# Run all tests
dbt test

# Run tests for specific model
dbt test --select stg_customers

# Run with freshness checks
dbt source freshness
```

### Debugging

```bash
# Check configuration and connection
dbt debug

# Show compilation details
dbt compile --select stg_customers

# Dry run (show what would run)
dbt run --select stg_customers --dry-run
```

## Troubleshooting

### Error: "Profile not found"

Ensure [`profiles.yml`](profiles.yml) exists in the project root or in `~/.dbt/`:

```bash
# Check if profiles.yml exists
ls -la profiles.yml

# Or check in ~/.dbt/
ls -la ~/.dbt/profiles.yml
```

### Error: "Package not found"

Install dependencies:
```bash
dbt deps
```

### Error: "Database file locked"

Close any open connections to the DuckDB file:
```bash
# Remove the database file (will be recreated)
rm dev.duckdb
rm ci.duckdb
```

### Error: "Module not found: duckdb"

Ensure the DuckDB adapter is installed:
```bash
dbt deps
```

If issues persist, try:
```bash
pip install dbt-duckdb
```

### Slow Performance

DuckDB is fast, but you can optimize:
```yaml
# In profiles.yml, increase threads
threads: 8
```

## Data Persistence

### DuckDB Files

- `dev.duckdb` - Development database
- `ci.duckdb` - CI/CD database

These files are created automatically when you run dbt commands. They contain all your tables, views, and data.

### Resetting the Database

To start fresh:
```bash
# Remove database files
rm dev.duckdb ci.duckdb

# Rebuild from scratch
dbt seed
dbt build
```

### Backing Up Data

```bash
# Copy database file
cp dev.duckdb dev.duckdb.backup
```

## Documentation

### Generate Documentation

```bash
dbt docs generate
```

This creates documentation in the `target/` directory.

### Serve Documentation Locally

```bash
dbt docs serve
```

Open your browser to `http://localhost:8080` to view the documentation.

### Build Static Docs with MkDocs

The project includes MkDocs configuration for static documentation:

```bash
# Install MkDocs (if not already installed)
pip install mkdocs mkdocs-material

# Build static site
mkdocs build

# Serve locally
mkdocs serve
```

Open your browser to `http://localhost:8000` to view the MkDocs site.

## Project Structure

```
dbt-production-blueprint/
├── profiles.yml              # DuckDB profiles configuration
├── dbt_project.yml          # Project configuration
├── packages.yml             # dbt packages (includes DuckDB adapter)
├── models/                  # dbt models
│   ├── staging/            # Staging layer (stg_*)
│   ├── intermediate/       # Intermediate layer (int_*)
│   └── marts/              # Marts layer (dim_*, fct_*)
├── seeds/                  # CSV seed data
├── snapshots/              # SCD Type 2 snapshots
├── tests/                  # Custom tests
├── macros/                 # Custom macros
├── analyses/               # Ad-hoc analyses
└── docs/                   # MkDocs documentation
```

## Next Steps

1. **Run the project**: `dbt seed && dbt build`
2. **Explore the data**: Use DuckDB CLI or Python to query `dev.duckdb`
3. **Generate documentation**: `dbt docs generate && dbt docs serve`
4. **Review the models**: Check out the models in `models/` directory
5. **Customize for your needs**: Modify models, add tests, update documentation

## Additional Resources

- [dbt DuckDB Adapter Documentation](https://docs.getdbt.com/reference/warehouse-setups/duckdb-setup)
- [dbt Documentation](https://docs.getdbt.com/)
- [DuckDB Documentation](https://duckdb.org/docs/)
- [Project README](README.md)
- [AGENTS.md](AGENTS.md) - Project conventions and guidelines
