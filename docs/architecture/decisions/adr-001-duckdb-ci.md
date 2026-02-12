# ADR-001: Use DuckDB for CI/CD Documentation Generation

## Status

**Accepted**

## Context

We needed a reliable way to generate documentation in our CI/CD pipeline. The traditional approach requires a database connection, which introduces several challenges:

1. **Secrets Management**: Storing database credentials securely
2. **External Dependencies**: Reliance on external database availability
3. **Cost**: Running cloud databases just for doc generation
4. **Complexity**: Managing different environments

## Decision

We decided to use **DuckDB** as the database for documentation generation in CI/CD.

### Why DuckDB?

| Factor | DuckDB | Traditional Cloud DB |
|--------|--------|---------------------|
| **Setup** | Zero configuration | Requires credentials |
| **Cost** | Free | Cloud costs |
| **Speed** | In-memory, very fast | Network latency |
| **Security** | No secrets needed | Credential management |
| **Reliability** | Self-contained | External dependency |
| **Portability** | Runs anywhere | Needs network access |

### Implementation

**GitHub Actions Workflow** (`.github/workflows/deploy-docs.yml`):

```yaml
- name: Install dbt and DuckDB
  run: |
    pip install dbt-core dbt-duckdb

- name: Create DuckDB Profile
  run: |
    mkdir -p ~/.dbt
    cat > ~/.dbt/profiles.yml <<EOF
    dbt_production_blueprint_duckdb:
      target: ci
      outputs:
        ci:
          type: duckdb
          path: ':memory:'
          schema: ci
          threads: 2
    EOF

- name: Generate Documentation
  run: |
    dbt deps
    dbt seed
    dbt docs generate --target-dir docs/dbt_artifacts
```

## Consequences

### Positive

1. **No Secrets Required**: Eliminates need for `DBT_PROFILES_YML` secret
2. **Faster CI/CD**: In-memory processing is much faster than cloud DB
3. **Simpler Setup**: Works out of the box without configuration
4. **Reduced Cost**: No cloud database charges for doc generation
5. **Better Reliability**: No external dependencies

### Neutral

1. **Schema Compatibility**: DuckDB has slightly different type system, but our adapter-dispatched macros handle this
2. **Data Volume**: Limited by memory, but doc generation uses minimal data

### Negative

1. **Not Production-Parity**: Generated docs reflect DuckDB types, not Snowflake types
2. **Memory Limits**: Very large projects might hit memory limits

## Alternatives Considered

### 1. Use Snowflake for CI/CD

**Pros**:
- Production parity
- No type differences

**Cons**:
- Requires secrets management
- Costs money
- Slower (network latency)
- External dependency

**Decision**: Rejected due to complexity and cost

### 2. Use Empty Catalog (`--empty-catalog`)

**Pros**:
- No database needed at all
- Fastest option

**Cons**:
- No column types in generated docs
- Missing important metadata
- Incomplete documentation

**Decision**: Rejected because it produces incomplete docs

### 3. Use SQLite Instead of DuckDB

**Pros**:
- Similar benefits to DuckDB
- Well-established

**Cons**:
- Not officially supported by dbt
- Would need custom adapter
- Less modern type system

**Decision**: Rejected - DuckDB is officially supported and purpose-built for analytics

## Related Decisions

- [ADR-002: Incremental Processing Strategy](adr-002-incremental-strategy.md)
- [ADR-003: Contract Enforcement](adr-003-contract-enforcement.md)

## References

- [DuckDB Documentation](https://duckdb.org/docs/)
- [dbt-duckdb Adapter](https://github.com/jwills/dbt-duckdb)
- [GitHub Actions Workflow](https://github.com/remisharoon/dbt-production-blueprint/blob/main/.github/workflows/deploy-docs.yml)
