# Troubleshooting Guide

This guide helps you resolve common issues when setting up and running the dbt project with DuckDB.

## Error: "No module named 'dbt.adapters.duckdb'"

### Problem
```
Error importing adapter: No module named 'dbt.adapters.duckdb'
Could not find adapter type duckdb!
```

### Cause
The dbt-duckdb adapter is not installed. This is a Python package that must be installed via pip, NOT via `dbt deps`.

### Solution
```bash
# Install the dbt-duckdb adapter via pip
pip install dbt-duckdb

# Or install all dependencies from requirements.txt
pip install -r requirements.txt
```

**Important**: You must run `pip install -r requirements.txt` BEFORE running `dbt deps`.

## Error: "Package dbt-labs/dbt-duckdb was not found"

### Problem
```
Runtime Error
  Package dbt-labs/dbt-duckdb was not found in the package index
```

### Cause
You're trying to install dbt-duckdb as a dbt package via `dbt deps`, but it's actually a Python package.

### Solution
Remove `dbt-labs/dbt-duckdb` from [`packages.yml`](packages.yml) and install it via pip:
```bash
pip install dbt-duckdb
```

The [`packages.yml`](packages.yml) should only contain dbt packages like:
- `dbt-labs/dbt_utils`
- `metaplane/dbt_expectations`
- `dbt-labs/audit_helper`

## Error: "calogica/dbt_expectations is deprecated"

### Problem
```
The `calogica/dbt_expectations` package is deprecated in favor of
`metaplane/dbt_expectations`.
```

### Cause
The dbt_expectations package has been migrated to a new organization.

### Solution
Update [`packages.yml`](packages.yml):
```yaml
# Old (deprecated)
- package: calogica/dbt_expectations
  version: [">=0.10.0", "<0.11.0"]

# New (correct)
- package: metaplane/dbt_expectations
  version: [">=0.10.0", "<0.11.0"]
```

Then run:
```bash
dbt deps
```

## Error: "Profile not found"

### Problem
```
Runtime Error
  Could not find profile named 'dbt_production_blueprint_duckdb'
```

### Cause
The profiles.yml file is not in the expected location.

### Solution
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

## Error: "Database file locked"

### Problem
```
Runtime Error
  Database file is locked
```

### Cause
Another process is using the DuckDB file, or a previous dbt run didn't close properly.

### Solution
```bash
# Remove the database file (it will be recreated)
rm dev.duckdb
rm ci.duckdb

# Or remove WAL files
rm *.duckdb.wal
```

## Error: "Module not found: duckdb"

### Problem
```
ModuleNotFoundError: No module named 'duckdb'
```

### Cause
The DuckDB Python library is not installed.

### Solution
```bash
# Install DuckDB
pip install duckdb

# Or install all dependencies
pip install -r requirements.txt
```

## Error: "dbt: command not found"

### Problem
```
/bin/sh: dbt: command not found
```

### Cause
dbt-core is not installed or not in your PATH.

### Solution
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

## Error: "MissingArgumentsPropertyInGenericTestDeprecation"

### Problem
```
Found top-level arguments to test `accepted_values` defined on 'stg_customers'
Arguments to generic tests should be nested under the `arguments` property.
```

### Cause
The test configuration uses the old format for accepted_values tests.

### Solution
Update the test configuration in schema.yml files:

**Old format:**
```yaml
tests:
  - accepted_values:
      values: ['active', 'inactive']
```

**New format:**
```yaml
tests:
  - accepted_values:
      arguments:
        values: ['active', 'inactive']
```

This has been fixed in [`models/staging/schema.yml`](models/staging/schema.yml).

## Error: "404 Not Found: post dummy.snowflakecomputing.com"

### Problem
```
Database Error 290404 (08001): 404 Not Found: post dummy.snowflakecomputing.com:443/session/v1/login-request
```

### Cause
The project is trying to connect to Snowflake with placeholder credentials.

### Solution
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

## Error: "Insufficient privileges"

### Problem
```
Insufficient privileges to complete operation
```

### Cause
Your Snowflake role doesn't have the necessary permissions.

### Solution
Grant necessary permissions in Snowflake:
```sql
GRANT USAGE ON WAREHOUSE <your_warehouse> TO ROLE <your_role>;
GRANT USAGE ON DATABASE <your_database> TO ROLE <your_role>;
GRANT CREATE SCHEMA ON DATABASE <your_database> TO ROLE <your_role>;
```

## Error: "Object does not exist"

### Problem
```
Object '<database>.<schema>.<table>' does not exist
```

### Cause
The database or schema doesn't exist in Snowflake.

### Solution
Create the database in Snowflake:
```sql
CREATE DATABASE IF NOT EXISTS <your_database>;
CREATE SCHEMA IF NOT EXISTS <your_database>.<schema>;
```

## Error: "Authentication failed"

### Problem
```
Authentication failed for user '<username>'
```

### Cause
Incorrect username or password.

### Solution
1. Verify your credentials in `~/.dbt/profiles.yml`
2. Try using browser-based SSO:
   ```yaml
   authenticator: externalbrowser
   ```
3. Reset your password in Snowflake if needed

## Performance Issues

### Problem
dbt runs are slow.

### Solution
1. Increase threads in [`profiles.yml`](profiles.yml):
   ```yaml
   threads: 8
   ```

2. Use DuckDB for faster local development (it's much faster than Snowflake for small datasets)

3. Run only what you need:
   ```bash
   # Run specific model
   dbt run --select stg_customers

   # Run only modified models
   dbt run --select state_modified_plus
   ```

## Documentation Issues

### Problem
Documentation doesn't show up correctly.

### Solution
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

## General Debugging

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

## Getting Help

If you're still having issues:

1. Check the [dbt documentation](https://docs.getdbt.com/)
2. Check the [DuckDB documentation](https://duckdb.org/docs/)
3. Review the [SETUP_GUIDE.md](SETUP_GUIDE.md)
4. Review the [DUCKDB_SETUP.md](DUCKDB_SETUP.md)
5. Check the [AGENTS.md](AGENTS.md) for project conventions

## Common Mistakes

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

### 3. Not activating virtual environment
If you created a virtual environment, you must activate it:
```bash
source venv/bin/activate
```

### 4. Using the wrong profile
Make sure [`dbt_project.yml`](dbt_project.yml) references the correct profile:
```yaml
profile: dbt_production_blueprint_duckdb
```

## Clean Slate

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
