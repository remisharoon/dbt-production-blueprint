# Data Dictionary

Comprehensive reference of all fields and columns across the dbt Production Blueprint.

## How to Use This Dictionary

- **Search** using the search bar (top right) or `Ctrl+K` / `Cmd+K`
- **Filter** by model, layer, or data type
- **Navigate** to model documentation for detailed usage

## Column Legend

| Symbol | Meaning |
|--------|---------|
| 🔑 | Primary Key |
| 🔗 | Foreign Key |
| ✓ | Required (not null) |
| ⚠️ | Tested with warning severity |
| 📝 | Has documentation |

---

## Staging Layer

### `stg_customers`

Source: `raw_customers` seed

| Column | Type | Key | Description | Tests |
|--------|------|-----|-------------|-------|
| customer_id | string | 🔑 | Unique customer identifier from source | not_null, unique ⚠️, is_alphanumeric |
| customer_key | string | 🔗✓ | Surrogate key (hash of customer_id + name) | not_null, unique |
| name | string | ✓ | Customer full name (trimmed, title case) | not_null |
| email | string | ✓ | Email address (normalized to lowercase) | not_null |
| region | string | ✓ | Geographic region (North America, EMEA, APAC, LATAM) | not_null, accepted_values |
| status | string | ✓ | Customer status (active, inactive) | not_null, accepted_values |

**Notes**:
- `customer_id` has `severity: warn` on unique test due to known duplicates in seed data (C002)
- Region normalization: "NA" → "North America", "Europe" → "EMEA", etc.

---

### `stg_orders`

Source: `raw_orders` seed

| Column | Type | Key | Description | Tests |
|--------|------|-----|-------------|-------|
| order_id | string | 🔑 | Unique order identifier from source | not_null, unique ⚠️, is_alphanumeric |
| order_key | string | 🔗✓ | Surrogate key (hash of order_id) | not_null, unique |
| customer_id | string | 🔗✓ | Customer identifier (FK to stg_customers) | not_null, relationships |
| order_date | date | ✓ | Date order was placed | not_null |
| order_total | decimal | | Total order amount in specified currency | |
| currency | string | ✓ | Currency code (USD, EUR, GBP, etc.) | not_null |
| status | string | ✓ | Order status (completed, placed, shipped, returned, canceled) | not_null, accepted_values |
| is_deleted | boolean | ✓ | Soft delete flag (true if order canceled/returned) | not_null |
| updated_at | timestamp | ✓ | Last update timestamp for incremental processing | not_null |

**Notes**:
- `order_id` has `severity: warn` on unique test due to known duplicates in seed data (O1002)
- `is_deleted` derived from status (canceled, returned)
- `updated_at` used for incremental processing in downstream `fct_orders`

---

### `stg_payments`

Source: `raw_payments` seed

| Column | Type | Key | Description | Tests |
|--------|------|-----|-------------|-------|
| payment_id | string | 🔑 | Unique payment identifier from source | not_null, unique, is_alphanumeric |
| payment_key | string | 🔗✓ | Surrogate key (hash of payment_id) | not_null, unique |
| order_id | string | 🔗✓ | Order identifier (FK to stg_orders) | not_null, relationships |
| payment_method | string | ✓ | Payment method (credit_card, coupon, bank_transfer, gift_card) | not_null, accepted_values |
| amount | decimal | | Payment amount | |
| provider_transaction_id | string | | External payment processor transaction ID | |

**Notes**:
- Payment method normalization: "credit card" → "credit_card"
- Multiple payments can exist for one order

---

## Intermediate Layer

### `int_order_payments`

Aggregates payments at order level.

| Column | Type | Key | Description | Tests |
|--------|------|-----|-------------|-------|
| order_id | string | 🔑✓ | Order identifier | not_null, unique |
| order_key | string | 🔗✓ | Order surrogate key | not_null |
| order_total | decimal | ✓ | Original order total | not_null |
| total_payments | decimal | ✓ | Sum of all payments for order | not_null |
| payment_coverage | decimal | ✓ | Payment percentage (total_payments / order_total * 100) | expect_between [0, 200] |
| payment_status | string | ✓ | paid, partial, overpaid | not_null, accepted_values |
| refund_amount | decimal | ✓ | Total refund amount | not_null |
| chargeback_amount | decimal | ✓ | Total chargeback amount | not_null |

**Notes**:
- One-to-many relationship: one order → many payments
- `payment_coverage` > 100 indicates overpayment
- Used by `fct_orders` and `fct_revenue`

---

### `int_order_status_categorized`

Categorizes order statuses into groups.

| Column | Type | Key | Description | Tests |
|--------|------|-----|-------------|-------|
| order_id | string | 🔑✓ | Order identifier | not_null, unique |
| order_status | string | ✓ | Original order status | not_null |
| status_category | string | ✓ | completed, open, canceled | not_null, accepted_values |
| updated_at | timestamp | ✓ | Last update timestamp | not_null |

**Status Mapping**:

| Original Status | Category |
|----------------|----------|
| completed, shipped, delivered | completed |
| placed, confirmed, processing | open |
| canceled, returned, refunded | canceled |

---

## Marts Layer - Core

### `dim_customers`

Customer dimension with latest state.

| Column | Type | Key | Description | Tests |
|--------|------|-----|-------------|-------|
| customer_id | string | 🔑✓ | Customer natural key | not_null, unique |
| customer_key | string | 🔗✓ | Customer surrogate key | not_null, unique |
| name | string | ✓ | Customer name | not_null |
| email | string | ✓ | Customer email | not_null |
| region | string | ✓ | Geographic region | not_null |
| status | string | ✓ | active, inactive | not_null |
| first_order_date | date | | Date of customer's first order | |
| last_order_date | date | | Date of customer's most recent order | |

**Notes**:
- Post-hook: `grant select on {{ this }} to role reporter`
- Deduplicated to latest record per customer
- Used as primary customer reference in all marts

---

### `fct_orders`

Order fact table (incremental).

| Column | Type | Key | Description | Tests |
|--------|------|-----|-------------|-------|
| order_id | string | 🔑✓ | Order natural key | not_null, unique |
| order_key | string | 🔗✓ | Order surrogate key | not_null |
| customer_key | string | 🔗✓ | Customer surrogate key (FK to dim_customers) | not_null, relationships |
| order_date | date | ✓ | Order placement date | not_null |
| order_total | decimal(19,2) | ✓ | Order total amount | not_null, expect_between [0, null] |
| currency | string | ✓ | Currency code | not_null |
| status | string | ✓ | Order status | not_null |
| is_deleted | boolean | ✓ | Soft delete flag | not_null |
| total_payments | decimal(19,2) | ✓ | Sum of payments | not_null |
| payment_coverage | decimal | ✓ | Payment percentage | not_null, expect_between [0, 200] |
| updated_at | timestamp | ✓ | Last update timestamp | not_null |

**Configuration**:
```yaml
materialized: incremental
unique_key: order_id
strategy: merge
partition_by: [updated_at]
contract: enforced
```

**Notes**:
- Incremental processing on `updated_at` timestamp
- `is_deleted` = false for active orders only
- Includes payment rollups from `int_order_payments`

---

### `fct_customer_ltv`

Customer lifetime value metrics.

| Column | Type | Key | Description | Tests |
|--------|------|-----|-------------|-------|
| customer_id | string | 🔑✓ | Customer natural key | not_null, unique |
| customer_key | string | 🔗✓ | Customer surrogate key | not_null |
| total_revenue | decimal(19,2) | ✓ | Net revenue (orders - refunds) | not_null, expect_between [0, null] |
| total_orders | integer | ✓ | Total number of orders | not_null, expect_between [0, null] |
| avg_order_value | decimal(19,2) | ✓ | Average order amount | not_null, expect_between [0, null] |
| lifetime_value | decimal(19,2) | ✓ | Total net revenue (LTV) | not_null, expect_between [0, null] |
| first_order_date | date | ✓ | Date of first order | not_null |
| last_order_date | date | ✓ | Date of most recent order | not_null |

**Metrics**:
- **Total Revenue**: Net of refunds and cancellations
- **Lifetime Value (LTV)**: Total net revenue per customer
- **Average Order Value**: Mean order amount

---

## Marts Layer - Finance

### `fct_revenue`

Revenue aggregations by date, region, and currency.

| Column | Type | Key | Description | Tests |
|--------|------|-----|-------------|-------|
| date | date | 🔑✓ | Revenue date | not_null |
| region | string | 🔑✓ | Geographic region | not_null |
| currency | string | 🔑✓ | Currency code | not_null |
| total_revenue | decimal(19,2) | ✓ | Sum of net revenue | not_null, expect_between [0, null] |
| order_count | integer | ✓ | Number of orders | not_null, expect_between [0, null] |
| avg_order_value | decimal(19,2) | ✓ | Average order amount | not_null, expect_between [0, null] |

**Composite Key**: (date, region, currency)

**Documentation**:
```markdown
{{ doc('total_revenue') }}
Total Revenue is the sum of all net order totals, excluding 
refunds and cancellations. Used for executive reporting and 
financial reconciliation.
```

**Notes**:
- Excludes soft-deleted orders
- Net revenue = order_total - refunds

---

### `region_summary`

Dynamic region rollup aggregations.

| Column | Type | Key | Description | Tests |
|--------|------|-----|-------------|-------|
| region | string | 🔑✓ | Region name | not_null |
| total_revenue | decimal(19,2) | ✓ | Sum of revenue | not_null |
| total_orders | integer | ✓ | Total order count | not_null |
| total_customers | integer | ✓ | Unique customer count | not_null |
| avg_order_value | decimal(19,2) | ✓ | Average order amount | not_null |

**Dynamic Generation**:
```sql
{{ generate_region_summary_sql(var('regions')) }}
```

**Default Regions**:
- North America
- EMEA
- APAC
- LATAM

---

## Snapshots

### `snap_customers_history`

SCD Type 2 snapshot of customer changes.

| Column | Type | Description |
|--------|------|-------------|
| customer_id | string | Natural key |
| name | string | Customer name |
| email | string | Email address |
| region | string | Geographic region |
| status | string | Customer status |
| updated_at | timestamp | Last update timestamp (source) |
| dbt_valid_from | timestamp | Record valid start time |
| dbt_valid_to | timestamp | Record valid end time (null = current) |
| dbt_scd_id | string | SCD record identifier |

**Configuration**:
```yaml
strategy: timestamp
updated_at: updated_at
invalidate_hard_deletes: true
```

**Use Cases**:
- Customer journey analysis
- Attribute change tracking
- Point-in-time reporting

---

## Seed Data

### `raw_customers`

| Column | Type | Description |
|--------|------|-------------|
| customer_id | string | Customer identifier |
| name | string | Customer name |
| email | string | Email address |
| region | string | Geographic region (various formats) |
| status | string | Customer status |

**Issues** (intentional):
- Duplicate customer_id (C002)
- Missing name for C007
- Mixed case emails
- Various region formats (NA, North America, etc.)

---

### `raw_orders`

| Column | Type | Description |
|--------|------|-------------|
| order_id | string | Order identifier |
| customer_id | string | Customer identifier |
| order_date | date | Order date |
| order_total | decimal | Order amount (some null) |
| currency | string | Currency code |
| status | string | Order status (mixed case) |
| updated_at | timestamp | Update timestamp |

**Issues** (intentional):
- Duplicate order_id (O1002)
- Missing order_total values
- Mixed case status values

---

### `raw_payments`

| Column | Type | Description |
|--------|------|-------------|
| payment_id | string | Payment identifier |
| order_id | string | Order identifier |
| payment_method | string | Payment method (various formats) |
| amount | decimal | Payment amount (some null) |
| provider_transaction_id | string | External transaction ID |

**Issues** (intentional):
- Duplicate payment_id (P5002)
- Missing amount values
- Mixed format payment methods

---

## Data Type Reference

### Common Types

| Type | Usage | Example |
|------|-------|---------|
| string | IDs, names, descriptions | customer_id, email |
| decimal(19,2) | Monetary amounts | order_total, revenue |
| integer | Counts | order_count, total_orders |
| boolean | Flags | is_deleted |
| date | Dates without time | order_date |
| timestamp | Dates with time | updated_at |

### Type Mapping

| Logical Type | DuckDB | Snowflake | Notes |
|--------------|--------|-----------|-------|
| decimal(19,2) | DECIMAL | NUMBER | Used for money |
| string | VARCHAR | VARCHAR | Variable length |
| integer | INTEGER | NUMBER(38,0) | Whole numbers |
| boolean | BOOLEAN | BOOLEAN | True/False |
| date | DATE | DATE | Calendar date |
| timestamp | TIMESTAMP | TIMESTAMP_NTZ | No timezone |

---

## Test Reference

### Generic Tests

| Test | Description | Columns Tested |
|------|-------------|----------------|
| not_null | Column must have values | All keys and required fields |
| unique | Values must be unique | All primary keys |
| relationships | FK must reference valid PK | customer_id, order_id |
| accepted_values | Values must be in list | status, payment_method, region |
| is_alphanumeric | Values must be alphanumeric | customer_id, order_id, payment_id |
| column_type_is | Column type must match expected | All columns with contracts |

### dbt_expectations Tests

| Test | Description | Applied To |
|------|-------------|------------|
| expect_column_values_to_be_between | Values in range | order_total, payment_coverage, revenue |

### Data Tests

| Test | Description | Validates |
|------|-------------|-----------|
| revenue_consistency | Cross-mart reconciliation | fct_orders.net_order_total = fct_revenue.total_revenue |

---

## Quick Search

**By Model**:
- [Staging Models](#staging-layer) - stg_customers, stg_orders, stg_payments
- [Intermediate Models](#intermediate-layer) - int_order_payments, int_order_status_categorized
- [Core Marts](#marts-layer-core) - dim_customers, fct_orders, fct_customer_ltv
- [Finance Marts](#marts-layer-finance) - fct_revenue, region_summary
- [Snapshots](#snapshots) - snap_customers_history

**By Data Type**:
- String columns - IDs, names, codes
- Decimal columns - Monetary amounts
- Integer columns - Counts and quantities
- Boolean columns - Flags
- Date/Timestamp columns - Temporal data

**By Layer**:
- Staging - Standardization
- Intermediate - Business logic
- Marts - Analytics
- Snapshots - History tracking
