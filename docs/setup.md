# Setup Guide

Complete guide to setting up and running the dbt Production Blueprint project.

<div class="stats-grid">
  <div class="stat-card">
    <span class="stat-number">5 min</span>
    <span class="stat-label">Setup Time</span>
  </div>
  <div class="stat-card">
    <span class="stat-number">3</span>
    <span class="stat-label">Steps</span>
  </div>
  <div class="stat-card">
    <span class="stat-number">100%</span>
    <span class="stat-label">Free</span>
  </div>
</div>

---

## :rocket: Quick Start

Follow these three simple steps to get started:

### 1. Clone and Install Dependencies

```bash
# Clone the repository
git clone https://github.com/remisharoon/dbt-production-blueprint.git
cd dbt-production-blueprint

# Install Python dependencies (includes dbt-duckdb adapter)
pip install -r requirements.txt
```

!!! important "Important: Order Matters"
    Always run `pip install -r requirements.txt` **BEFORE** running `dbt deps`. The DuckDB adapter is a Python package that must be installed via pip, NOT via `dbt deps`.

### 2. Install dbt Packages

```bash
# Install dbt packages (dbt_utils, dbt_expectations, audit_helper)
dbt deps
```

### 3. Run the Project

```bash
# Load seed data
dbt seed

# Build all models, tests, and snapshots
dbt build
```

That's it! You now have a fully functional dbt project running with DuckDB.

---

## :wrench: Configuration Details

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

!!! note "Note"
    The DuckDB adapter is a Python package, not a dbt package, so it's installed via pip rather than `dbt deps`.

---

## :building_construction: DuckDB vs Snowflake

### DuckDB (Default - For Demo/Testing)

✅ **Pros:**
- No external database required
- Fast, in-process SQL database
- Perfect for local development and testing
- Single file database (`.duckdb`)
- No authentication needed

❌ **Cons:**
- Not suitable for production workloads
- Limited to single-machine processing

### Snowflake (Production)

✅ **Pros:**
- Cloud-native data warehouse
- Scalable for production workloads
- Multi-user support
- Advanced security features

❌ **Cons:**
- Requires account and credentials
- Costs money to run

---

## :snowflake: Switching to Snowflake (Optional)

If you want to use Snowflake instead of DuckDB:

### 1. Update dbt_project.yml

Change profile:

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

---

## :terminal: Common dbt Commands

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

---

## :bug: Common Issues

### Error: "Profile not found"

Ensure [`profiles.yml`](profiles.yml) exists in project root or in `~/.dbt/`:

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

Close any open connections to DuckDB file:

```bash
# Remove database file (will be recreated)
rm dev.duckdb
rm ci.duckdb
```

### Error: "Module not found: duckdb"

Ensure the DuckDB adapter is installed:

```bash
pip install dbt-duckdb
```

### Slow Performance

DuckDB is fast, but you can optimize:

```yaml
# In profiles.yml, increase threads
threads: 8
```

---

## :file_folder: Data Persistence

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

---

## :page_facing_up: Documentation

### Generate Documentation

```bash
dbt docs generate
```

This creates documentation in `target/` directory.

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

---

## :link: Learn More

- [Troubleshooting Guide](troubleshooting.md) - Common issues and solutions
- [Quick Reference](reference.md) - Commands and conventions
- [Project Architecture](architecture.md) - Deep dive into layered design
- [dbt Documentation](dbt_artifacts/index.html) - Interactive data lineage
