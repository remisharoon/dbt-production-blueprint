# Troubleshooting Guide

<div class="stats-grid">
  <div class="stat-card">
    <span class="stat-number">10+</span>
    <span class="stat-label">Solutions</span>
  </div>
  <div class="stat-card">
    <span class="stat-number">5</span>
    <span class="stat-label">Categories</span>
  </div>
  <div class="stat-card">
    <span class="stat-number">100%</span>
    <span class="stat-label">Solved</span>
  </div>
</div>

This guide helps you resolve common issues when setting up and running the dbt project with DuckDB.

---

## :exclamation: Installation Issues

### Error: "No module named 'dbt.adapters.duckdb'"

**Problem:**
```
Error importing adapter: No module named 'dbt.adapters.duckdb'
Could not find adapter type duckdb!
```

**Cause:**
The dbt-duckdb adapter is not installed. This is a Python package that must be installed via pip, NOT via `dbt deps`.

**Solution:**
```bash
# Install dbt-duckdb adapter via pip
pip install dbt-duckdb

# Or install all dependencies from requirements.txt
pip install -r requirements.txt
```

!!! important "Order Matters"
    You must run `pip install -r requirements.txt` BEFORE running `dbt deps`.

---

### Error: "Package dbt-labs/dbt-duckdb was not found"

**Problem:**
```
Runtime Error
  Package dbt-labs/dbt-duckdb was not found in package index
```

**Cause:**
You're trying to install dbt-duckdb as a dbt package via `dbt deps`, but it's actually a Python package.

**Solution:**
Remove `dbt-labs/dbt-duckdb` from [`packages.yml`](packages.yml) and install it via pip:

```bash
pip install dbt-duckdb
```

The [`packages.yml`](packages.yml) should only contain dbt packages like:
- `dbt-labs/dbt_utils`
- `metaplane/dbt_expectations`
- `dbt-labs/audit_helper`

---

### Error: "dbt: command not found"

**Problem:**
```
/bin/sh: dbt: command not found
```

**Cause:**
dbt-core is not installed or not in your PATH.

**Solution:**
```bash
# Install dbt-core
pip install dbt-core

# Or install all dependencies
pip install -r requirements.txt

# Verify installation
dbt --version
```

If using a virtual environment, make sure it's activated:

```bash
source venv/bin/activate  # On macOS/Linux
# or
venv\Scripts\activate  # On Windows
```

---

## :warning: Configuration Issues

### Error: "Profile not found"

**Problem:**
```
Runtime Error
  Could not find profile named 'dbt_production_blueprint_duckdb'
```

**Cause:**
The profiles.yml file is not in the expected location.

**Solution:**
Ensure [`profiles.yml`](profiles.yml) exists in one of these locations:

1. Project root directory (recommended for this project)
2. `~/.dbt/profiles.yml`

Check if the file exists:

```bash
# Check project root
ls -la profiles.yml

# Check ~/.dbt/
ls -la ~/.dbt/profiles.yml
```

If it doesn't exist, copy the template:

```bash
cp profiles_template.yml profiles.yml
```

---

### Error: "404 Not Found: post dummy.snowflakecomputing.com"

**Problem:**
```
Database Error 290404 (08001): 404 Not Found: post dummy.snowflakecomputing.com:443/session/v1/login-request
```

**Cause:**
The project is trying to connect to Snowflake with placeholder credentials.

**Solution:**
Use DuckDB instead (recommended for demo/testing):

```bash
# Install dependencies
pip install -r requirements.txt

# Install dbt packages
dbt deps

# Run dbt commands
dbt seed
dbt build
```

Or configure Snowflake credentials in `~/.dbt/profiles.yml` (see [`profiles_template.yml`](profiles_template.yml)).

---

## :lock: Database Issues

### Error: "Database file locked"

**Problem:**
```
Runtime Error
  Database file is locked
```

**Cause:**
Another process is using the DuckDB file, or a previous dbt run didn't close properly.

**Solution:**
```bash
# Remove database file (it will be recreated)
rm dev.duckdb
rm ci.duckdb

# Or remove WAL files
rm *.duckdb.wal
```

---

### Error: "Module not found: duckdb"

**Problem:**
```
ModuleNotFoundError: No module named 'duckdb'
```

**Cause:**
The DuckDB Python library is not installed.

**Solution:**
```bash
# Install DuckDB
pip install duckdb

# Or install all dependencies
pip install -r requirements.txt
```

---

## :chart_with_downwards_trend: Snowflake Issues

### Error: "Insufficient privileges"

**Problem:**
```
Insufficient privileges to complete operation
```

**Cause:**
Your Snowflake role doesn't have the necessary permissions.

**Solution:**
Grant necessary permissions in Snowflake:

```sql
GRANT USAGE ON WAREHOUSE <your_warehouse> TO ROLE <your_role>;
GRANT USAGE ON DATABASE <your_database> TO ROLE <your_role>;
GRANT CREATE SCHEMA ON DATABASE <your_database> TO ROLE <your_role>;
```

---

### Error: "Object does not exist"

**Problem:**
```
Object '<database>.<schema>.<table>' does not exist
```

**Cause:**
The database or schema doesn't exist in Snowflake.

**Solution:**
Create the database in Snowflake:

```sql
CREATE DATABASE IF NOT EXISTS <your_database>;
CREATE SCHEMA IF NOT EXISTS <your_database>.<schema>;
```

---

### Error: "Authentication failed"

**Problem:**
```
Authentication failed for user '<username>'
```

**Cause:**
Incorrect username or password.

**Solution:**
1. Verify your credentials in `~/.dbt/profiles.yml`
2. Try using browser-based SSO:
   ```yaml
   authenticator: externalbrowser
   ```
3. Reset your password in Snowflake if needed

---

## :zap: Performance Issues

### Problem: dbt runs are slow

**Solution:**

1. **Increase threads in [`profiles.yml`](profiles.yml):**
   ```yaml
   threads: 8
   ```

2. **Use DuckDB for faster local development:**
   DuckDB is much faster than Snowflake for small datasets.

3. **Run only what you need:**
   ```bash
   # Run specific model
   dbt run --select stg_customers

   # Run only modified models
   dbt run --select state_modified_plus
   ```

---

## :page_facing_up: Documentation Issues

### Problem: Documentation doesn't show up correctly

**Solution:**
```bash
# Regenerate documentation
dbt docs generate

# Serve documentation
dbt docs serve
```

If using MkDocs:

```bash
# Build MkDocs site
mkdocs build

# Serve MkDocs site
mkdocs serve
```

---

## :gear: General Debugging

### Check Configuration

```bash
# Verify dbt configuration
dbt debug
```

### Show Compilation Details

```bash
# Show what SQL would be run
dbt compile --select <model_name>
```

### Dry Run

```bash
# Show what would run without executing
dbt run --select <model_name> --dry-run
```

### Verbose Output

```bash
# Run with verbose output
dbt run --debug
```

---

## :book: Common Mistakes

### 1. Running `dbt deps` before installing Python dependencies

**Wrong:**
```bash
dbt deps  # This will fail if dbt-duckdb isn't installed
pip install -r requirements.txt
```

**Correct:**
```bash
pip install -r requirements.txt  # Install dbt-duckdb first
dbt deps  # Then install dbt packages
```

---

### 2. Trying to install dbt-duckdb as a dbt package

**Wrong:**
```yaml
# packages.yml
- package: dbt-labs/dbt-duckdb  # This doesn't exist
```

**Correct:**
```bash
# Install via pip
pip install dbt-duckdb
```

---

### 3. Not activating virtual environment

If you created a virtual environment, you must activate it:

```bash
source venv/bin/activate
```

---

### 4. Using wrong profile

Make sure [`dbt_project.yml`](dbt_project.yml) references the correct profile:

```yaml
profile: dbt_production_blueprint_duckdb
```

---

## :wastebasket: Clean Slate

If everything is broken and you want to start fresh:

```bash
# Remove database files
rm *.duckdb *.duckdb.wal

# Remove dbt artifacts
rm -rf target/ dbt_packages/ logs/

# Reinstall dependencies
pip install -r requirements.txt --force-reinstall

# Reinstall dbt packages
dbt deps --clean

# Start fresh
dbt seed
dbt build
```

---

## :link: Getting Help

If you're still having issues:

1. Check [dbt documentation](https://docs.getdbt.com/)
2. Check [DuckDB documentation](https://duckdb.org/docs/)
3. Review [Setup Guide](setup.md)
4. Review [Project Architecture](architecture.md)
5. Check [AGENTS.md](AGENTS.md) for project conventions

---

## :link: Related Guides

- [Setup Guide](setup.md) - Installation and configuration
- [Quick Reference](reference.md) - Commands and conventions
- [Features Guide](features.md) - Complete feature documentation
- [Project Architecture](architecture.md) - Deep dive into layered design
