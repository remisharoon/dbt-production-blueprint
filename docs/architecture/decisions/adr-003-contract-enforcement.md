# ADR-003: Enforce Model Contracts

## Status

**Accepted**

## Context

As our data warehouse grows and more teams depend on our models, we need to ensure that:
1. Column types remain stable across changes
2. Breaking changes are caught before deployment
3. Data consumers can rely on schema guarantees
4. Documentation is accurate and enforced

Without contracts, a developer could accidentally:
- Change a `decimal` column to `integer`
- Rename columns without updating downstream
- Add columns that break BI tools
- Remove columns that reports depend on

## Decision

We decided to **enforce model contracts** globally for all models.

### Configuration

**Global enforcement** in `dbt_project.yml`:

```yaml
models:
  dbt_production_blueprint:
    +contract:
      enforced: true
    +on_schema_change: fail
```

### Model Definition

Each model must define `data_type` for all columns:

```yaml
models:
  - name: fct_orders
    config:
      contract:
        enforced: true
    columns:
      - name: order_id
        data_type: string
        description: "Unique order identifier"
      
      - name: order_total
        data_type: decimal(19,2)
        description: "Total order amount"
      
      - name: order_date
        data_type: date
        description: "Order placement date"
```

## Consequences

### Positive

1. **Type Safety**: Catches type mismatches at build time
2. **Breaking Change Prevention**: CI fails on schema changes
3. **Documentation**: Schema is self-documenting
4. **Consumer Confidence**: Downstream teams can rely on types
5. **Refactoring Safety**: Safe to refactor with type checking

### Neutral

1. **Verbosity**: Must define data_type for every column
2. **Learning Curve**: Team needs to understand contracts

### Negative

1. **Schema Changes Require Coordination**: Can't change types without updating contracts
2. **Full Refresh Required**: Changing contracts requires `--full-refresh`
3. **Initial Setup**: Existing models need data_type definitions added

## Contract Components

### Data Types

Required for every column:

```yaml
columns:
  - name: customer_id
    data_type: string
  
  - name: order_total
    data_type: decimal(19,2)
  
  - name: is_deleted
    data_type: boolean
  
  - name: order_date
    data_type: date
```

### Constraints

Optional but recommended:

```yaml
columns:
  - name: order_id
    data_type: string
    constraints:
      - type: not_null
      - type: unique
```

### Schema Change Behavior

| Setting | Behavior | Use Case |
|---------|----------|----------|
| `fail` | **Fail the run** | Recommended for production |
| `append` | Add new columns | Development flexibility |
| `sync` | Add/remove columns | Aggressive syncing |
| `ignore` | Ignore all changes | Not recommended |

**Our choice**: `fail` for production safety

## Why Enforce Contracts?

### Without Contracts

```
Developer changes order_total from decimal(19,2) to integer
    ↓
Model runs successfully
    ↓
Finance dashboard shows incorrect amounts
    ↓
Bug discovered in production
    ↓
Emergency fix required
```

### With Contracts

```
Developer changes order_total from decimal(19,2) to integer
    ↓
Contract check fails in CI
    ↓
Build blocked
    ↓
Developer updates contract or reverts change
    ↓
Safe deployment
```

## Implementation Strategy

### Phase 1: Add Data Types

Add `data_type` to all existing columns in schema.yml files.

### Phase 2: Enable Contracts

Set `enforced: true` at project level.

### Phase 3: CI Integration

Ensure CI runs fail on contract violations.

### Phase 4: Team Training

Educate team on contract benefits and workflow.

## Type Mapping

### DuckDB vs Snowflake

We use adapter-dispatched macros to handle type differences:

**`macros/utils/data_types.sql`**:

```sql
{% macro numeric_type(precision, scale) %}
  {{ return(adapter.dispatch('numeric_type', 'dbt')(precision, scale)) }}
{% endmacro %}

{% macro default__numeric_type(precision, scale) %}
    numeric({{ precision }}, {{ scale }})
{% endmacro %}

{% macro duckdb__numeric_type(precision, scale) %}
    decimal({{ precision }}, {{ scale }})
{% endmacro %}

{% macro snowflake__numeric_type(precision, scale) %}
    number({{ precision }}, {{ scale }})
{% endmacro %}
```

## Contract Violations

### Common Violations

1. **Type Mismatch**:
   ```
   Contract violation: Column order_total has type decimal(19,2) 
   in contract but integer in model
   ```

2. **Missing Column**:
   ```
   Contract violation: Column customer_segment defined in contract 
   but missing from model
   ```

3. **Extra Column**:
   ```
   Contract violation: Column temp_flag in model but not in contract
   ```

### Resolving Violations

**Option 1: Update the Contract** (intentional change):
```yaml
# Update schema.yml
columns:
  - name: order_total
    data_type: decimal(19,4)  # Changed precision
```

**Option 2: Fix the Model** (mistake):
```sql
-- Change model to match contract
select
    order_total::decimal(19,2)  -- Cast to correct type
from {{ ref('stg_orders') }}
```

**Option 3: Full Refresh** (schema changes):
```bash
dbt run --select fct_orders --full-refresh
```

## Best Practices

### Do

✅ Define `data_type` for every column
✅ Use appropriate types (decimal for money, etc.)
✅ Plan schema changes carefully
✅ Use `--full-refresh` when changing contracts
✅ Document type choices in descriptions

### Don't

❌ Skip `data_type` definitions
❌ Use generic types when specific types are needed
❌ Change contracts without team coordination
❌ Ignore contract violations in CI

## Alternatives Considered

### 1. No Contracts

**Pros**:
- Complete flexibility
- No setup required

**Cons**:
- Breaking changes reach production
- No type guarantees
- Harder to maintain data quality

**Decision**: Rejected - too risky for production

### 2. Optional Contracts (Not Enforced)

**Pros**:
- Documentation benefit
- Can gradually adopt

**Cons**:
- No actual enforcement
- Violations not caught

**Decision**: Rejected - enforcement is the key benefit

### 3. Manual Schema Reviews

**Pros**:
- Human oversight
- Can catch logical issues

**Cons**:
- Doesn't scale
- Error-prone
- Blocks CI/CD

**Decision**: Rejected - automated enforcement is more reliable

## Migration Path

For existing projects wanting to adopt contracts:

1. **Inventory** - List all models and columns
2. **Add Types** - Add `data_type` to all columns
3. **Test** - Run with `enforced: false` first
4. **Enable** - Set `enforced: true` project-wide
5. **Monitor** - Watch for violations in CI

## Related Decisions

- [ADR-001: DuckDB for CI](adr-001-duckdb-ci.md)
- [ADR-002: Incremental Processing](adr-002-incremental-strategy.md)

## References

- [dbt Model Contracts](https://docs.getdbt.com/docs/collaborate/govern/model-contracts)
- [dbt Column Level Constraints](https://docs.getdbt.com/reference/resource-configs/constraints)
- [Adapter Dispatch](https://docs.getdbt.com/reference/dbt-jinja-functions/adapter)
