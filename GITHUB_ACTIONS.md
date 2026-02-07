# GitHub Actions CI/CD Guide

This guide explains the GitHub Actions workflow for automatically generating and deploying dbt documentation to GitHub Pages.

## Overview

The project uses GitHub Actions to automatically:
1. Install dependencies (dbt-core, dbt-duckdb, MkDocs)
2. Install dbt packages (dbt_utils, dbt_expectations, audit_helper)
3. Generate dbt documentation using DuckDB
4. Deploy documentation to GitHub Pages via MkDocs

## Workflow File

Location: [`.github/workflows/deploy-docs.yml`](.github/workflows/deploy-docs.yml)

### Trigger

The workflow runs automatically when:
- Code is pushed to the `main` branch

### Permissions

```yaml
permissions:
  contents: write
```

This allows the workflow to deploy to GitHub Pages.

## Workflow Steps

### 1. Checkout Repository

```yaml
- name: Checkout repository
  uses: actions/checkout@v4
```

Checks out the repository code.

### 2. Set Up Python

```yaml
- name: Set up Python
  uses: actions/setup-python@v5
  with:
    python-version: '3.11'
```

Sets up Python 3.11 environment.

### 3. Install Dependencies

```yaml
- name: Install dependencies
  run: |
    python -m pip install --upgrade pip
    pip install \
      dbt-core \
      dbt-duckdb \
      mkdocs \
      mkdocs-material \
      mkdocs-minify-plugin \
      mkdocs-git-revision-date-localized-plugin
```

Installs:
- `dbt-core` - dbt framework
- `dbt-duckdb` - DuckDB adapter (replaced dbt-snowflake)
- `mkdocs` - Documentation generator
- `mkdocs-material` - Material theme for MkDocs
- `mkdocs-minify-plugin` - Minifies HTML/CSS/JS
- `mkdocs-git-revision-date-localized-plugin` - Adds git revision dates

### 4. Install dbt Packages

```yaml
- name: Install dbt packages
  run: dbt deps
```

Installs dbt packages from [`packages.yml`](packages.yml):
- `dbt-labs/dbt_utils`
- `metaplane/dbt_expectations`
- `dbt-labs/audit_helper`

### 5. Generate dbt Docs

```yaml
- name: Generate dbt docs
  run: |
    mkdir -p ~/.dbt

    # Use DuckDB for documentation generation (no external database needed)
    printf "%s\n" \
      "dbt_production_blueprint_duckdb:" \
      "  target: ci" \
      "  outputs:" \
      "    ci:" \
      "      type: duckdb" \
      "      path: ci.duckdb" \
      "      schema: main" \
      "      threads: 4" > ~/.dbt/profiles.yml

    # Generate dbt docs with DuckDB
    dbt docs generate --target-path docs/dbt_artifacts
```

Creates a DuckDB profile and generates dbt documentation.

### 6. Deploy with MkDocs

```yaml
- name: Deploy with MkDocs
  run: mkdocs gh-deploy --force
```

Deploys the documentation site to GitHub Pages.

## Changes Made

### Before (Snowflake with Dummy Credentials)

```yaml
- name: Install dependencies
  run: |
    pip install \
      dbt-core \
      dbt-snowflake \
      mkdocs \
      mkdocs-material \
      mkdocs-minify-plugin \
      mkdocs-git-revision-date-localized-plugin

- name: Generate dbt docs
  env:
    DBT_PROFILES_YML: ${{ secrets.DBT_PROFILES_YML }}
  run: |
    if [ -n "$DBT_PROFILES_YML" ]; then
      printf "%s" "$DBT_PROFILES_YML" > ~/.dbt/profiles.yml
      dbt docs generate --target-path docs/dbt_artifacts
    else
      printf "%s\n" \
        "dbt_production_blueprint:" \
        "  target: ci" \
        "  outputs:" \
        "    ci:" \
        "      type: snowflake" \
        "      account: dummy" \
        "      user: dummy" \
        "      password: dummy" \
        "      role: dummy" \
        "      database: dummy" \
        "      warehouse: dummy" \
        "      schema: dummy" \
        "      threads: 4" > ~/.dbt/profiles.yml
      dbt docs generate --target-path docs/dbt_artifacts --empty-catalog
    fi
```

**Problems:**
- Required Snowflake adapter installation
- Required `DBT_PROFILES_YML` secret for full catalog
- Fallback used dummy Snowflake credentials (caused errors)
- Fallback used `--empty-catalog` flag (limited documentation)

### After (DuckDB)

```yaml
- name: Install dependencies
  run: |
    pip install \
      dbt-core \
      dbt-duckdb \
      mkdocs \
      mkdocs-material \
      mkdocs-minify-plugin \
      mkdocs-git-revision-date-localized-plugin

- name: Generate dbt docs
  run: |
    mkdir -p ~/.dbt

    # Use DuckDB for documentation generation (no external database needed)
    printf "%s\n" \
      "dbt_production_blueprint_duckdb:" \
      "  target: ci" \
      "  outputs:" \
      "    ci:" \
      "      type: duckdb" \
      "      path: ci.duckdb" \
      "      schema: main" \
      "      threads: 4" > ~/.dbt/profiles.yml

    # Generate dbt docs with DuckDB
    dbt docs generate --target-path docs/dbt_artifacts
```

**Benefits:**
- Uses DuckDB adapter (faster, no external database)
- No secrets required
- Full catalog generation (no `--empty-catalog` needed)
- Works out of the box
- Simpler configuration

## Benefits of Using DuckDB in CI/CD

### 1. No External Database Required
- DuckDB is an in-process SQL database
- No need for Snowflake account or credentials
- No network latency or connection issues

### 2. No Secrets Required
- No need for `DBT_PROFILES_YML` secret
- Simpler repository configuration
- Easier for contributors and forks

### 3. Faster CI/CD Pipeline
- DuckDB is faster than Snowflake for small datasets
- No network overhead
- Quicker documentation generation

### 4. Works Out of the Box
- No configuration needed
- Works immediately after cloning repository
- Perfect for open-source projects

### 5. Full Documentation
- Generates complete catalog (not `--empty-catalog`)
- Includes all model metadata
- Better documentation experience

## Enabling GitHub Pages

### Step 1: Go to Repository Settings

1. Navigate to your GitHub repository
2. Click on **Settings** tab
3. Click on **Pages** in the left sidebar

### Step 2: Configure Source

1. Under **Source**, select **GitHub Actions**
2. GitHub will detect the workflow automatically
3. Click **Save**

### Step 3: Trigger Workflow

Push to `main` branch:
```bash
git add .
git commit -m "Update GitHub Actions workflow"
git push origin main
```

The workflow will automatically run and deploy documentation.

### Step 4: Access Documentation

After successful deployment, your documentation will be available at:
```
https://<username>.github.io/<repository-name>/
```

For example:
```
https://remisharoon.github.io/dbt-production-blueprint/
```

## Workflow Status

You can view workflow status in:
1. **Actions** tab in your GitHub repository
2. Click on the workflow run to see details
3. View logs for each step

## Troubleshooting

### Workflow Fails at "Install dependencies"

**Problem**: Python package installation fails

**Solution**: Check that Python version is compatible (3.8+)

### Workflow Fails at "Install dbt packages"

**Problem**: `dbt deps` fails

**Solution**: Check [`packages.yml`](packages.yml) for correct package names and versions

### Workflow Fails at "Generate dbt docs"

**Problem**: `dbt docs generate` fails

**Solution**: Check that [`dbt_project.yml`](dbt_project.yml) has correct profile name

### Workflow Fails at "Deploy with MkDocs"

**Problem**: `mkdocs gh-deploy` fails

**Solution**: Ensure GitHub Pages is enabled and configured correctly

### Documentation Not Updating

**Problem**: Documentation site shows old content

**Solution**:
1. Check workflow ran successfully
2. Clear browser cache
3. Wait a few minutes for GitHub Pages to update

## Customizing the Workflow

### Change Python Version

```yaml
- name: Set up Python
  uses: actions/setup-python@v5
  with:
    python-version: '3.12'  # Change to desired version
```

### Add Additional MkDocs Plugins

```yaml
- name: Install dependencies
  run: |
    pip install \
      dbt-core \
      dbt-duckdb \
      mkdocs \
      mkdocs-material \
      mkdocs-minify-plugin \
      mkdocs-git-revision-date-localized-plugin \
      your-custom-plugin  # Add custom plugin
```

### Change Trigger Branch

```yaml
on:
  push:
    branches:
      - main
      - develop  # Add additional branches
```

### Add Manual Trigger

```yaml
on:
  push:
    branches:
      - main
  workflow_dispatch:  # Enable manual trigger
```

Now you can manually trigger the workflow from the Actions tab.

## Local Testing

To test the workflow locally:

```bash
# Install dependencies
pip install dbt-core dbt-duckdb mkdocs mkdocs-material

# Install dbt packages
dbt deps

# Generate dbt docs
dbt docs generate --target-path docs/dbt_artifacts

# Serve documentation locally
mkdocs serve
```

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [MkDocs Documentation](https://www.mkdocs.org/)
- [dbt Documentation](https://docs.getdbt.com/)
- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Detailed setup instructions
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
