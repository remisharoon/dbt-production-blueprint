# Features Guide

<div class="stats-grid">
  <div class="stat-card">
    <span class="stat-number">15+</span>
    <span class="stat-label">Features</span>
  </div>
  <div class="stat-card">
    <span class="stat-number">4</span>
    <span class="stat-label">Categories</span>
  </div>
  <div class="stat-card">
    <span class="stat-number">100%</span>
    <span class="stat-label">Production Ready</span>
  </div>
</div>

Comprehensive list of all features in dbt Production Blueprint project.

---

## :star2: Overview

dbt Production Blueprint is designed as a **"kitchen sink"** of production-grade dbt patterns. Every feature has been carefully selected to demonstrate real-world enterprise data engineering practices.

---

## :building_construction: Architecture Features

### Layered Data Modeling

The project implements a **three-layer medallion architecture** with clear separation of concerns:

- **Staging Layer** (`models/staging/`)
  - Raw source data ingestion
  - Column standardization and renaming
  - Surrogate key generation
  - Light data cleaning

- **Intermediate Layer** (`models/intermediate/`)
  - Business logic normalization
  - Complex joins and aggregations
  - Reusable transformations
  - Status categorization

- **Marts Layer** (`models/marts/`)
  - Consumer-ready data products
  - Star schema design
  - Performance-optimized tables
  - Business-friendly column names

### Schema Organization

- `stg` - Staging layer schemas
- `int` - Intermediate layer schemas
- `mart_core` - Core marts schemas
- `mart_finance` - Finance marts schemas
- `snapshots` - SCD Type 2 history
- `raw` - Seed data schemas

---

## :zap: Performance Features

### Incremental Processing

Optimized incremental models for efficient data updates:

- **Merge-based incremental updates**
- **Unique key deduplication**
- **Timestamp filtering for change detection**
- **Soft delete tracking**
- **Historical data preservation**

Example: `fct_orders` uses incremental strategy with `order_id` as unique key.

### Materialization Strategies

Different materialization for different use cases:

| Layer | Materialization | Reason |
|--------|---------------|---------|
| Staging | View | Fast queries, transparent logic |
| Intermediate | View | Debugging-friendly, transparent |
| Marts | Table | Performance, reliability |
| Snapshots | Table | Historical tracking |

### State-Based CI

Efficient CI/CD with state comparison:

- Run only modified nodes
- Select dependencies automatically
- Deferral for production states
- Reduced CI runtime
- Cost-effective builds

---

## :camera: Change Tracking

### SCD Type 2 Snapshots

Full change history with timestamps:

- **Strategy**: timestamp-based
- **Updated at tracking**: Records change times
- **Historical preservation**: All versions maintained
- **Point-in-time queries**: Time-travel capability
- **Audit trail**: Complete change log

Example: `snap_customers_history` tracks all customer attribute changes.

---

## :test_tube: Testing Features

### Built-in dbt Tests

Essential data quality checks:

- `not_null` - Required columns
- `unique` - Unique identifiers
- `relationships` - Foreign key integrity

### dbt_expectations

Advanced expectations for comprehensive data quality:

- Column existence checks
- Data type validation
- Range validation
- Row count comparisons
- Distribution checks
- Custom expectations

### Custom Generic Tests

Project-specific tests for domain rules:

- `is_alphanumeric` - Validates ID formats
- Domain-specific validations
- Reusable test patterns

### Cross-Mart Reconciliation

Data consistency checks across marts:

- Revenue parity verification
- Aggregation consistency
- Business rule validation
- Metric alignment

### Test Severity Levels

Flexible severity for different scenarios:

- `error` - Fails build (default)
- `warn` - Logs warning, continues build

Used intentionally for known data quality issues in demo seeds.

---

## :lock: Data Governance Features

### Contracts Enforcement

Schema contracts ensure data integrity:

- Column type enforcement
- Schema change detection
- Automatic fail on schema drift
- Column data type requirements

### Documentation Requirements

Mandatory documentation at all levels:

- Model descriptions
- Column descriptions
- Test documentation
- Exposure documentation

### Doc Blocks

Reusable documentation components:

- Metric definitions
- Business terms
- Standard descriptions
- Consistent documentation

---

## :bar_chart: Business Intelligence Features

### Exposures

Downstream dependency tracking:

- Dashboard documentation
- Application dependencies
- BI tool integration
- Impact analysis

### Metrics

Business metric definitions:

- Total Revenue
- Customer LTV
- Regional summaries
- Custom metrics

---

## :art: SQL Generation Features

### Dynamic Macros

SQL generation for patterns:

- Region rollups without repetition
- Dynamic column selection
- Parameterized queries
- Code reduction

### Reusable Macros

Common SQL patterns:

- Surrogate key generation
- Date manipulation
- String transformations
- Conditional logic

---

## :gear: Operational Features

### On-Run Hooks

Automated operations:

- **On-run-start**: Audit logging
- Run metadata capture
- Execution tracking
- Performance monitoring

### Post-Hook Operations

Automated post-processing:

- **Grant management**: Role-based access
- Security enforcement
- Permission assignments

### CI/CD Integration

GitHub Actions workflow:

- Automated testing
- Documentation generation
- Deployment automation
- Status reporting

---

## :database: Warehouse Features

### DuckDB Support

Local development without external database:

- **In-process**: No network latency
- **Single file**: Easy backup and transfer
- **Fast execution**: Optimized for small datasets
- **No authentication**: Simple setup

### Snowflake Support

Production-grade warehouse:

- **Cloud-native**: Scalable and reliable
- **Multi-user**: Team collaboration
- **Advanced features**: Security, sharing, time-travel
- **Cost optimization**: Query optimization

### Target Configuration

Multiple targets for different environments:

| Target | Database | Purpose |
|---------|-----------|---------|
| `dev` | `dev.duckdb` | Local development |
| `ci` | `ci.duckdb` | CI/CD testing |
| `snowflake` | Snowflake | Production workloads |

---

## :page_facing_up: Documentation Features

### dbt Docs Integration

Interactive documentation:

- DAG visualization
- Lineage tracking
- Column-level documentation
- Test results
- Catalog metadata

### MkDocs Site

Static documentation:

- Modern Material theme
- Responsive design
- Search functionality
- Dark/light mode
- Code highlighting

### Schema Documentation

Comprehensive model documentation:

- Business purpose
- Transformation logic
- Dependencies
- Materialization strategy
- Test coverage

---

## :robot: Automation Features

### GitHub Actions

Automated workflow:

1. Install dependencies
2. Configure profiles
3. Install dbt packages
4. Validate parsing
5. Generate docs
6. Deploy to GitHub Pages

### Quickstart Script

Automated setup:

- Dependency installation
- Profile configuration
- Initial build
- Documentation generation

---

## :earth_asia: Multi-Region Support

### Regional Configuration

Dynamic region handling:

- North America
- EMEA
- APAC
- LATAM

### Region Rollups

Dynamic SQL generation for regional summaries:

- Configurable regions via variables
- Consistent aggregation logic
- Easy to add new regions

---

## :wrench: Development Features

### Seed Data

Sample data for demonstration:

- Customers with data quality issues
- Orders with edge cases
- Payments with variations
- Intentional data problems for demo

### Analysis Support

Ad-hoc analysis capabilities:

- Analysis directory for SQL queries
- Reusable analysis patterns
- Experimental transformations

---

## :shield: Security Features

### Role-Based Access

Automated permission management:

- Role assignments via hooks
- Read access for consumers
- Write access for producers

### Schema Enforcement

Data integrity guarantees:

- Contract validation
- Type checking
- Schema change protection

---

## :clipboard: Quality Features

### Code Organization

Clean project structure:

- Conventional file naming
- Clear directory hierarchy
- Logical grouping
- Scalable organization

### Best Practices

Industry-standard patterns:

- Naming conventions
- Documentation standards
- Testing coverage
- Version control

---

## :link: Feature Benefits

### For Data Engineers

- Production-ready patterns
- Comprehensive testing
- Clear architecture
- Easy maintenance

### For Data Analysts

- Well-documented models
- Business-friendly names
- Reliable data quality
- Self-service access

### For Data Scientists

- Clean data products
- Historical tracking
- Feature-ready schemas
- Consistent interfaces

### For Managers

- Proven patterns
- Reduced risk
- Faster onboarding
- Scalable solutions

---

## :link: Learn More

- [Project Architecture](architecture.md) - Deep dive into layered design
- [Setup Guide](setup.md) - Installation and configuration
- [Quick Reference](reference.md) - Commands and conventions
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
- [dbt Documentation](dbt_artifacts/index.html) - Interactive data lineage
