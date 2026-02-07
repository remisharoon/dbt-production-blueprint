# Installation Guide

This guide provides step-by-step instructions for setting up the dbt Production Blueprint project with DuckDB.

## Prerequisites

- Python 3.8 or higher
- pip (Python package manager)
- Git (for cloning the repository)

## Installation Steps

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd dbt-production-blueprint
```

### Step 2: Create a Virtual Environment (Recommended)

Creating a virtual environment isolates your project dependencies from your system Python.

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate

# On Windows:
venv\Scripts\activate
```

You should see `(venv)` in your terminal prompt when the virtual environment is active.

### Step 3: Install Python Dependencies (CRITICAL - Do This First!)

**IMPORTANT**: You MUST install Python dependencies BEFORE running `dbt deps`. This is the most common source of errors.

```bash
# Install all Python dependencies including dbt-duckdb adapter
pip install --upgrade pip
pip install -r requirements.txt
```

This installs:
- `dbt-core` - dbt framework
- `dbt-duckdb` - DuckDB adapter (Python package, NOT a dbt package)
- `mkdocs` and `mkdocs-material` - Documentation tools

**Why this order matters:**
- The DuckDB adapter is a Python package installed via `pip`
- It's NOT a dbt package (which would be installed via `dbt deps`)
- If you run `dbt deps` first, it will fail because the adapter isn't installed

### Step 4: Verify Installation

```bash
# Check dbt version
dbt --version

# Check if DuckDB adapter is installed
python -c "import dbt.adapters.duckdb; print('DuckDB adapter installed')"
```

You should see output like:
```
dbt version: 1.11.3
DuckDB adapter installed
```

### Step 5: Install dbt Packages

Now that the DuckDB adapter is installed, you can install dbt packages:

```bash
dbt deps
```

This installs:
- `dbt-labs/dbt_utils` - Utility macros and functions
- `metaplane/dbt_expectations` - Data quality tests
- `dbt-labs/audit_helper` - Audit and testing utilities

### Step 6: Verify Configuration

Check that [`profiles.yml`](profiles.yml) exists in the project root:

```bash
ls -la profiles.yml
```

The file should contain:
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

### Step 7: Test the Setup

```bash
# Test dbt configuration
dbt debug
```

You should see output like:
```
dbt version: 1.11.3
python version: 3.x.x
python path: /path/to/python
os info: macOS
Using profiles dir at /path/to/project
Using dbt_project.yml at /path/to/project/dbt_project.yml

Required dependencies:
 - duckdb: OK

Connection test: OK connection ok
```

### Step 8: Load Seed Data

```bash
dbt seed
```

This loads the CSV files from the `seeds/` directory into the DuckDB database.

### Step 9: Build All Models

```bash
dbt build
```

This runs all models, tests, and snapshots.

### Step 10: Generate Documentation

```bash
dbt docs generate
```

This generates the dbt documentation in the `target/` directory.

### Step 11: Serve Documentation

```bash
dbt docs serve
```

Open your browser to `http://localhost:8080` to view the documentation.

## Quick Start Script

For automated setup, use the provided script:

```bash
./quickstart.sh
```

This script performs all the steps above automatically.

## Common Installation Errors

### Error: "No module named 'dbt.adapters.duckdb'"

**Cause**: You ran `dbt deps` before installing Python dependencies.

**Solution**:
```bash
# Install Python dependencies first
pip install -r requirements.txt

# Then run dbt deps
dbt deps
```

### Error: "Package dbt-labs/dbt-duckdb was not found"

**Cause**: You're trying to install dbt-duckdb as a dbt package.

**Solution**: dbt-duckdb is installed via pip, not via `dbt deps`. Just run:
```bash
pip install dbt-duckdb
```

### Error: "calogica/dbt_expectations is deprecated"

**Cause**: The package has been migrated to a new organization.

**Solution**: This has been fixed in [`packages.yml`](packages.yml). Just run:
```bash
dbt deps
```

### Error: "Profile not found"

**Cause**: The profiles.yml file is missing.

**Solution**: Ensure [`profiles.yml`](profiles.yml) exists in the project root:
```bash
ls -la profiles.yml
```

If it doesn't exist, copy the template:
```bash
cp profiles_template.yml profiles.yml
```

## Verification Checklist

After installation, verify the following:

- [ ] Python 3.8+ is installed
- [ ] Virtual environment is created and activated (optional but recommended)
- [ ] `dbt-core` is installed (`dbt --version` works)
- [ ] `dbt-duckdb` adapter is installed
- [ ] `dbt deps` completed successfully
- [ ] `dbt debug` shows "Connection test: OK"
- [ ] `dbt seed` loaded seed data
- [ ] `dbt build` completed successfully
- [ ] `dbt docs generate` created documentation
- [ ] `dbt docs serve` works in browser

## Next Steps

After successful installation:

1. **Explore the models**: Check out the models in `models/` directory
2. **Run tests**: `dbt test`
3. **Generate documentation**: `dbt docs generate && dbt docs serve`
4. **Customize for your needs**: Modify models, add tests, update documentation

## Switching to Snowflake (Production)

To use Snowflake instead of DuckDB for production:

1. Install Snowflake adapter:
   ```bash
   pip install dbt-snowflake
   ```

2. Update [`dbt_project.yml`](dbt_project.yml):
   ```yaml
   profile: dbt_production_blueprint_snowflake
   ```

3. Create `~/.dbt/profiles.yml` with your Snowflake credentials (see [`profiles_template.yml`](profiles_template.yml))

4. Run dbt commands as usual

See [`SETUP_GUIDE.md`](SETUP_GUIDE.md) for detailed Snowflake setup instructions.

## Uninstallation

To remove the project and all dependencies:

```bash
# Deactivate virtual environment
deactivate

# Remove virtual environment
rm -rf venv

# Remove database files
rm *.duckdb *.duckdb.wal

# Remove dbt artifacts
rm -rf target/ dbt_packages/ logs/

# Remove project directory
cd ..
rm -rf dbt-production-blueprint
```

## Additional Resources

- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Detailed setup and configuration
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- [DUCKDB_SETUP.md](DUCKDB_SETUP.md) - DuckDB-specific information
- [README.md](README.md) - Project overview
- [AGENTS.md](AGENTS.md) - Project conventions and guidelines
- [dbt Documentation](https://docs.getdbt.com/)
- [DuckDB Documentation](https://duckdb.org/docs/)
