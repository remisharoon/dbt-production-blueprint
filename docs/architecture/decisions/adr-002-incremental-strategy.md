# ADR-002: Incremental Processing Strategy

## Status

**Accepted**

## Context

The `fct_orders` table contains order transactions that need to be:
1. Updated when orders change (status updates, amount corrections)
2. Processed efficiently as data volume grows
3. Kept current without full table rebuilds

We evaluated several strategies for handling these requirements.

## Decision

We decided to use **incremental materialization with merge strategy** for `fct_orders`.

### Configuration

```sql
{{ config(
    materialized='incremental',
    unique_key='order_id',
    strategy='merge',
    partition_by=['updated_at'],
    on_schema_change='fail'
) }}
```

### Implementation

```sql
with orders as (
    select *
    from {{ ref('stg_orders') }}
    
    {% if is_incremental() %}
    -- Only process new or updated records
    where updated_at > (
        select max(updated_at) 
        from {{ this }}
    )
    {% endif %}
)

select
    order_id,
    order_key,
    customer_key,
    order_date,
    order_total,
    currency,
    status,
    is_deleted,
    total_payments,
    payment_coverage,
    updated_at
from orders
```

## Consequences

### Positive

1. **Performance**: Only processes new/changed records
2. **Cost**: Reduced compute compared to full refreshes
3. **Freshness**: Faster data availability
4. **Updates**: Handles record changes (not just inserts)
5. **Scalability**: Efficient even with large volumes

### Neutral

1. **Complexity**: More complex than simple views/tables
2. **Monitoring**: Need to track incremental runtimes

### Negative

1. **Schema Changes**: Requires `--full-refresh` when schema changes
2. **Logic Changes**: Changing business logic requires full refresh
3. **Late Arrivals**: Need to handle late-arriving data
4. **Debugging**: Harder to debug than simple models

## Strategy Comparison

| Strategy | Best For | Pros | Cons |
|----------|----------|------|------|
| **Merge** | Updating records | Handles inserts & updates | Slightly slower than append |
| **Append** | Event streams | Fast, simple | No updates, duplicates |
| **Delete+Insert** | Partitioned tables | Clean partitions | Deletes all partition data |
| **Insert Overwrite** | BigQuery | Partition replacement | BigQuery only |

### Why Merge?

We chose `merge` over other strategies because:

1. **Orders Change**: Order statuses and amounts get updated
2. **Idempotent**: Can safely re-run without duplicates
3. **Standard SQL**: Works across warehouses
4. **Well-Supported**: First-class dbt feature

### Why Not Append?

Append strategy would be simpler, but:
- Cannot handle order updates (status changes, refunds)
- Would create duplicate records for changed orders
- Not suitable for transactional data

## Implementation Details

### Unique Key Selection

**Chosen**: `order_id`

**Why**:
- Natural business key
- Stable identifier
- One order = one record

**Alternatives Considered**:
- `order_key` (surrogate) - More complex, no benefit
- Composite key - Unnecessary for orders

### Timestamp Column

**Chosen**: `updated_at`

**Why**:
- Tracks when record last changed
- Efficient filtering: `WHERE updated_at > (SELECT MAX(updated_at) FROM {{ this }})`
- Standard pattern for incremental models

**Generated in**:
- `stg_orders` - Added to staging model
- Used by `fct_orders` - For incremental filtering

### Partitioning

```sql
partition_by=['updated_at']
```

**Benefits**:
- Faster queries filtering on date ranges
- Easier data management (drop old partitions)
- Better compression for time-series data

## Best Practices

### When to Use Incremental

**Use for**:
- Large fact tables
- Tables that receive updates
- Time-series data
- High-volume event data

**Don't use for**:
- Small dimensions (< 1M rows)
- Static reference data
- Tables rebuilt daily anyway

### Handling Schema Changes

```bash
# When schema changes
dbt run --select fct_orders --full-refresh

# When business logic changes
dbt run --select fct_orders --full-refresh
```

### Handling Late Arrivals

```sql
-- Include records that might have been missed
{% if is_incremental() %}
where updated_at > (
    select dateadd(day, -7, max(updated_at)) 
    from {{ this }}
)
{% endif %}
```

### Monitoring

Track these metrics:
- Incremental runtime vs full refresh
- Records processed per run
- Late arrival frequency
- Full refresh frequency

## Related Decisions

- [ADR-001: DuckDB for CI](adr-001-duckdb-ci.md)
- [ADR-003: Contract Enforcement](adr-003-contract-enforcement.md)

## References

- [dbt Incremental Models](https://docs.getdbt.com/docs/build/incremental-models)
- [Best Practices for Incremental Models](https://docs.getdbt.com/best-practices/materializations/1-guide-overview)
