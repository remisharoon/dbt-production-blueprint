# Project Architecture

This repository is intentionally designed as a **"kitchen sink"** for production-grade dbt patterns on Snowflake. The goal is to demonstrate how enterprise teams structure, document, test, and operate dbt projects at scale.

<div class="stats-grid">
  <div class="stat-card">
    <span class="stat-number">3</span>
    <span class="stat-label">Architecture Layers</span>
  </div>
  <div class="stat-card">
    <span class="stat-number">4</span>
    <span class="stat-label">Test Categories</span>
  </div>
  <div class="stat-card">
    <span class="stat-number">2</span>
    <span class="stat-label">Snapshot Types</span>
  </div>
  <div class="stat-card">
    <span class="stat-number">100%</span>
    <span class="stat-label">Documented</span>
  </div>
</div>

---

## :building_construction: Layered Model Architecture

The project follows the **medallion architecture** pattern with three distinct layers, each serving a specific purpose in the data transformation pipeline.

<div class="feature-grid">

### 📥 Staging Layer (`models/staging`)

**Purpose**: Raw source standardization and lightweight cleaning

Staging models are the **first transformation layer** that connects directly to raw data sources. They perform minimal transformations to standardize data before it enters the business logic layers.

**Key Characteristics**:
- Direct connection to raw sources via `sources.yml`
- Surrogate keys generated for all entities
- Column renaming for consistency (snake_case)
- Data type normalization
- Light cleaning (trim, null handling)
- Preserves raw columns for debugging

**Models**:
- `stg_customers` - Customer data from source
- `stg_orders` - Order transactions
- `stg_payments` - Payment records

**Materialization**: View (for fast queries)

```sql
-- Example: stg_customers
select
    customer_id as customer_key,
    customer_id,
    email,
    lower(email) as email_lower,
    -- Standardized column naming
    first_name,
    last_name,
    -- Generated surrogate key
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_key,
from {{ source('raw', 'customers') }}
```

---

### 🔄 Intermediate Layer (`models/intermediate`)

**Purpose**: Business logic normalization and reuse

Intermediate models contain **reusable business logic** that is shared across multiple mart models. This DRY (Don't Repeat Yourself) approach ensures consistency and reduces maintenance overhead.

**Key Characteristics**:
- Joins between staging models
- Business rules and calculations
- Data quality transformations
- Reusable aggregations
- Status categorization logic
- Clean, documented SQL

**Models**:
- `int_order_payments` - Joins orders with payments
- `int_order_status_categorized` - Order status categorization

**Materialization**: View (for transparency and debugging)

```sql
-- Example: int_order_payments
-- This joins orders with payments once, reused by multiple marts
select
    o.order_id,
    o.customer_key,
    o.order_status,
    o.order_date,
    o.updated_at,
    p.payment_id,
    p.payment_method,
    p.amount as payment_amount,
    -- Business logic: net order total
    coalesce(sum(p.amount), 0) as net_order_total,
from {{ ref('stg_orders') }} o
left join {{ ref('stg_payments') }} p
    on o.order_id = p.order_id
group by 1, 2, 3, 4, 5, 6, 7, 8
```

---

### 📊 Marts Layer (`models/marts`)

**Purpose**: Analytics-ready models for consumption

Marts are **consumer-facing models** optimized for reporting, dashboards, and data products. They represent the final output of the data pipeline and are highly optimized for query performance.

**Key Characteristics**:
- Star schema design (dimensions + facts)
- Aggregated metrics
- Performance-optimized
- Column-level documentation required
- Business-friendly column names
- Exposures documented

**Core Marts** (`models/marts/core`):
- `dim_customers` - Customer dimension with LTV
- `fct_orders` - Order fact table
- `fct_customer_ltv` - Customer lifetime value facts

**Finance Marts** (`models/marts/finance`):
- `fct_revenue` - Revenue aggregations by date
- `region_summary` - Regional rollups (dynamic SQL)

**Materialization**: Table (for performance and reliability)

```sql
-- Example: dim_customers
-- Customer dimension with lifetime value
select
    c.customer_key,
    c.customer_id,
    c.email,
    c.first_name,
    c.last_name,
    -- LTV calculation from customer_ltv intermediate
    coalesce(ltv.total_revenue, 0) as lifetime_value,
    coalesce(ltv.order_count, 0) as lifetime_order_count,
    c.updated_at,
from {{ ref('stg_customers') }} c
left join {{ ref('int_customer_ltv') }} ltv
    on c.customer_key = ltv.customer_key
```

</div>

---

## :zap: Incremental Processing

Incremental models optimize performance by **only processing new or changed data** rather than rebuilding the entire table on every run.

### `fct_orders` Implementation

The `fct_orders` model demonstrates incremental processing with:

- **Merge Strategy**: Upsert records based on unique key
- **Incremental Key**: `order_id` (unique identifier)
- **Updated At Filter**: `updated_at > (select max(updated_at) from {{ this }})`
- **Soft Delete Handling**: Track deleted records without removing them

```sql
{{ config(
    materialized='incremental',
    unique_key='order_id',
    incremental_strategy='merge',
    on_schema_change='append_new_columns'
) }}

select
    o.order_id,
    o.customer_key,
    o.order_date,
    o.order_status,
    o.updated_at,
    -- Soft delete tracking
    case when o.updated_at is null then true else false end as is_deleted,
    o.updated_at as deleted_at,
    -- Net total excludes deleted orders
    coalesce(sum(op.payment_amount), 0) as net_order_total,
from {{ ref('int_order_payments') }} o
where o.updated_at is null
   or o.updated_at > (select max(updated_at) from {{ this }})
group by 1, 2, 3, 4, 5, 6, 7
```

**Benefits**:
- Dramatically faster builds on large datasets
- Cost-effective by processing less data
- Maintains historical data with soft deletes
- Handles late-arriving data gracefully

---

## :camera: SCD Type 2 Snapshots

**Slowly Changing Dimensions (SCD) Type 2** track the complete history of changes to dimension attributes over time.

### `snap_customers_history` Implementation

This snapshot captures all customer attribute changes:

- **Strategy**: `timestamp` based
- **Updated At Column**: Tracks when changes occurred
- **Check Columns**: All customer attributes (`email`, `first_name`, `last_name`)

```sql
{% snapshot snap_customers_history %}
{{
    config(
      target_schema='snapshots',
      unique_key='customer_key',
      strategy='timestamp',
      updated_at='updated_at',
      invalidate_hard_deletes=true
    )
}}

select * from {{ ref('stg_customers') }}

{% endsnapshot %}
```

**Output Columns**:
- `customer_key` - Unique identifier
- `customer_id` - Original ID
- `email`, `first_name`, `last_name` - Customer attributes
- `updated_at` - Last update timestamp
- `dbt_valid_from` - Record validity start
- `dbt_valid_to` - Record validity end
- `dbt_scd_id` - Unique SCD record ID
- `dbt_updated_at` - Snapshot creation time

**Benefits**:
- Complete audit trail of customer changes
- Time-travel queries for historical analysis
- Point-in-time reporting
- Compliance with data governance requirements

---

## :art: Dynamic SQL Generation

Macros generate SQL dynamically to eliminate code duplication and enable flexible patterns.

### Region Summary Model

The `region_summary` model uses dynamic SQL to generate region rollups for all configured regions without hardcoding:

```sql
-- Macro: generate_region_rollup
{% macro generate_region_rollup() %}
  {% for region in var('regions') %}
    union all
    select
      '{{ region }}' as region,
      count(distinct customer_key) as customer_count,
      sum(net_order_total) as revenue,
      count(order_id) as order_count
    from {{ ref('fct_revenue') }}
    where region = '{{ region }}'
  {% endfor %}
{% endmacro %}

-- Model: region_summary
select * from ( {{ generate_region_rollup() }} ) t
where region is not null
```

**Benefits**:
- Single source of truth for region configuration
- Easy to add new regions via variables
- Reduced code duplication
- Consistent logic across all regions

---

## :microscope: Testing & Quality

The project implements a **multi-layered testing strategy** to ensure data quality and reliability.

### Test Categories

#### 1. Built-in dbt Tests
- `not_null` - Required columns
- `unique` - Unique identifiers
- `relationships` - Foreign key integrity

```yaml
# Example: Schema test
columns:
  - name: customer_id
    tests:
      - not_null
      - unique
      - relationships:
          to: ref('stg_customers')
          field: customer_id
```

#### 2. dbt_expectations Tests
Advanced expectations for comprehensive data quality:

```yaml
tests:
  - dbt_expectations.expect_column_to_exist:
      column: net_order_total
  - dbt_expectations.expect_column_values_to_be_between:
      column: net_order_total
      min_value: 0
  - dbt_expectations.expect_table_row_count_to_equal_other_table:
      other_table_name: ref('stg_orders')
```

#### 3. Custom Generic Tests
Project-specific tests for domain rules:

```sql
-- is_alphanumeric.sql - Custom test
{% test is_alphanumeric(model, column_name) %}

select *
from {{ model }}
where {{ column_name }} !~ '^[a-zA-Z0-9_]+$'

{% endtest %}

-- Usage
tests:
  - is_alphanumeric: customer_id
  - is_alphanumeric: order_id
```

#### 4. Cross-Mart Reconciliation Tests
Data consistency checks across marts:

```sql
-- tests/revenue_consistency.sql
-- Ensures revenue matches across finance and core marts
select 1
from (
    select
        (select sum(net_order_total) from {{ ref('fct_revenue') }}) as finance_revenue,
        (select sum(net_order_total) from {{ ref('fct_orders') }}) as core_revenue
) t
where finance_revenue != core_revenue
```

### Test Configuration

Tests are configured with appropriate severity levels:

```yaml
tests:
  - dbt_expectations.expect_column_values_to_be_between:
      severity: warn  # Known data quality issues in seeds
      column: net_order_total
      min_value: 0
```

**Severity Levels**:
- `error` (default) - Fails the build
- `warn` - Logs warning but continues build
- Used intentionally for known data issues in demo seeds

---

## :clipboard: Documentation & Exposures

### Column-Level Documentation

Contracts enforce documentation requirements:

```yaml
models:
  dbt_production_blueprint:
    +persist_docs:
      relation: true
      columns: true
    +contract:
      enforced: true
```

```yaml
# Example: Documented column
columns:
  - name: lifetime_value
    description: |
      Total revenue generated by the customer across all orders.
      Calculated as sum of all order totals minus refunds.
    data_type: numeric(18,2)
    tests:
      - dbt_expectations.expect_column_to_be_of_type:
          column_type: numeric
```

### Doc Blocks

Reusable documentation blocks for metrics and concepts:

```md
<!-- models/docs.md -->
{% docs metric_total_revenue %}
**Total Revenue**: The sum of all successful order payments after refunds.
Includes all regions: {{ var('regions') | join(', ') }}.

Formula: `sum(net_order_total) where is_deleted = false`
{% enddocs %}
```

```yaml
# Usage in models
description: "{{ doc('metric_total_revenue') }}"
```

### Exposures

Document downstream dependencies for impact analysis:

```yaml
# models/exposures.yml
exposures:
  - name: executive_dashboard
    type: dashboard
    depends_on:
      - ref('fct_revenue')
      - ref('dim_customers')
    owner:
      name: Data Team
      email: data@company.com
    url: https://looker.company.com/dashboards/executive

  - name: revenue_reporting_api
    type: application
    depends_on:
      - ref('fct_revenue')
    owner:
      name: Engineering
      email: eng@company.com
```

**Benefits**:
- Impact analysis for model changes
- Document data lineage to consumers
- Change communication strategy
- Asset ownership and accountability

---

## :gear: Operational Hooks

### On-Run-Start Hook

Automatically logs run metadata to `audit_run` table:

```sql
-- macros/audit.sql
{% macro log_run_start() %}
  {% if execute %}
    {% set run_id = run_id %}
    insert into audit_run (
      run_id,
      invocation_id,
      dbt_version,
      started_at,
      command,
      env
    )
    values (
      '{{ run_id }}',
      '{{ invocation_id }}',
      '{{ dbt_version }}',
      '{{ run_started_at.strftime("%Y-%m-%d %H:%M:%S") }}',
      '{{ command_invocation }}',
      '{{ target.name }}'
    )
  {% endif %}
{% endmacro %}
```

### Post-Hook Grants

Automatically grant access on materialization:

```sql
-- models/marts/core/dim_customers.sql
{{ config(
    materialized='table',
    post_hook='grant select on {{ this }} to role reporter'
) }}

select ...
```

**Benefits**:
- Automated audit logging
- Role-based access control
- Compliance with data governance
- Traceability of all dbt runs

---

## :link: Learn More

- [Setup Guide](setup.md) - Installation and configuration
- [Features Guide](features.md) - Complete feature documentation
- [Quick Reference](reference.md) - Commands and conventions
- [dbt Documentation](dbt_artifacts/index.html) - Interactive data lineage
