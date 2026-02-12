# Installation Guide

Complete installation instructions for dbt Production Blueprint.

## System Requirements

| Component | Minimum Version | Recommended |
|-----------|----------------|-------------|
| Python | 3.8 | 3.10+ |
| dbt-core | 1.8.0 | Latest |
| Git | 2.30 | Latest |
| Operating System | Windows 10, macOS 10.15, Ubuntu 20.04 | Latest |

## Option 1: DuckDB (Recommended for Development)

DuckDB is the default for local development and testing. It requires no external database setup.

### Install Python Dependencies

```bash
# Clone the repository
git clone https://github.com/remisharoon/dbt-production-blueprint.git
cd dbt-production-blueprint

# Install Python packages
pip install -r requirements.txt
```

??? info "What's in requirements.txt?"
    ```text
    dbt-core>=1.8.0
    dbt-duckdb>=1.8.0
    mkdocs-material>=9.5.0
    mkdocs-minify-plugin>=0.8.0
    mkdocs-git-revision-date-localized-plugin>=1.2.0
    mermaid-js
    ```

### Verify Installation

```bash
# Check dbt installation
dbt --version

# Expected output:
# Core:
#   - installed: 1.8.x
#   - latest:    1.8.x
#
# Plugins:
#   - duckdb: 1.8.x
```

### Configure Profile

The project includes a pre-configured `profiles.yml` file:

```yaml title="profiles.yml"
dbt_production_blueprint_duckdb:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: dev.duckdb
      schema: main
      threads: 4
```

No additional configuration needed! The profile is ready to use.

## Option 2: Snowflake (Production)

For production use, configure a Snowflake connection.

### Install Python Dependencies

```bash
# Install core dependencies
pip install dbt-core>=1.8.0

# Install Snowflake adapter
pip install dbt-snowflake>=1.8.0

# Install dbt packages
dbt deps
```

### Configure Profile

Create or edit `~/.dbt/profiles.yml`:

```yaml title="~/.dbt/profiles.yml"
dbt_production_blueprint_snowflake:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: <your_account>.snowflakecomputing.com
      user: <your_username>
      password: <your_password>
      role: <your_role>
      database: <your_database>
      warehouse: <your_warehouse>
      schema: <your_schema>
      threads: 4
      
    prod:
      type: snowflake
      account: <your_account>.snowflakecomputing.com
      user: <your_username>
      password: <your_password>
      role: <your_role>
      database: PRODUCTION
      warehouse: PROD_WAREHOUSE
      schema: ANALYTICS
      threads: 8
```

!!! warning "Security Best Practice"
    Never commit passwords to version control. Use environment variables:
    ```bash
    export DBT_SNOWFLAKE_PASSWORD='your-password'
    ```
    
    Then reference in profiles.yml:
    ```yaml
    password: "{{ env_var('DBT_SNOWFLAKE_PASSWORD') }}"
    ```

### Update Project Configuration

Change the profile in `dbt_project.yml`:

```yaml title="dbt_project.yml"
name: dbt_production_blueprint
version: 1.0.0
profile: dbt_production_blueprint_snowflake  # Change this line
```

### Verify Connection

```bash
# Test connection
dbt debug

# Expected output:
# Connection:
#   account: <your_account>
#   user: <your_username>
#   database: <your_database>
#   schema: <your_schema>
#   Connection test: [OK connection ok]
```

## Environment Setup

### Python Virtual Environment (Recommended)

```bash
# Create virtual environment
python -m venv venv

# Activate
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

# Install dependencies
pip install -r requirements.txt
```

### Using pipx (Alternative)

```bash
# Install pipx
pip install pipx

# Install dbt with duckdb
pipx install dbt-duckdb

# Run dbt from anywhere
dbt --version
```

## Package Installation

### Install dbt Packages

```bash
# Install all packages from packages.yml
dbt deps
```

This installs:
- `dbt-labs/dbt_utils` - Utility macros
- `metaplane/dbt_expectations` - Advanced data tests
- `dbt-labs/audit_helper` - Audit utilities

### Verify Packages

```bash
# List installed packages
dbt deps --packages-dir

# Expected packages:
# dbt_utils
# dbt_expectations
# audit_helper
```

## Post-Installation Setup

### 1. Initialize Database

```bash
# Create schema and load seeds
dbt seed
```

### 2. Run Initial Build

```bash
# Build all models and run tests
dbt build
```

### 3. Generate Documentation

```bash
# Generate and serve docs
dbt docs generate
dbt docs serve
```

## Troubleshooting Installation

### Python Version Issues

```bash
# Check Python version
python --version

# If wrong version, use pyenv or conda
pyenv install 3.10.0
pyenv local 3.10.0
```

### Permission Errors

```bash
# Use --user flag
pip install --user -r requirements.txt

# Or use virtual environment (recommended)
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Connection Issues (Snowflake)

```bash
# Verify account format
dbt debug --connection

# Check network connectivity
# Test with Snowflake web UI
```

### Package Conflicts

```bash
# Clear dbt packages
dbt clean

# Reinstall
dbt deps
```

## Next Steps

- [Configuration Guide](configuration.md) - Learn about profiles, variables, and settings
- [Quick Start](quickstart.md) - Get running in 5 minutes
- [Architecture Overview](../architecture/index.md) - Understand the data model
