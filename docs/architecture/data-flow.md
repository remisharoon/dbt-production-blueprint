# Data Flow

Visual representation of how data flows through the dbt Production Blueprint.

## Complete Data Flow Diagram

```mermaid
graph TD
    subgraph Seeds["📂 Seeds (Raw Data)"]
        SC[raw_customers.csv<br/>11 records]
        SO[raw_orders.csv<br/>12 records]
        SP[raw_payments.csv<br/>12 records]
    end
    
    subgraph Staging["🔵 Staging Layer"]
        SC -->|normalize| STG1[stg_customers<br/>Surrogate keys, clean names]
        SO -->|standardize| STG2[stg_orders<br/>Soft-delete flags, status clean]
        SP -->|cast| STG3[stg_payments<br/>Method normalization]
    end
    
    subgraph Intermediate["🟢 Intermediate Layer"]
        STG1 & STG2 & STG3 --> INT1[int_order_payments<br/>Payment rollups]
        STG2 --> INT2[int_order_status_categorized<br/>Status groups]
    end
    
    subgraph Marts_Core["🟠 Core Marts"]
        STG1 --> DIM[dim_customers<br/>Latest customer state]
        STG2 & INT1 & INT2 --> FCT1[fct_orders<br/>Incremental facts]
        STG1 & STG2 & FCT1 --> LTV[fct_customer_ltv<br/>Lifetime value]
    end
    
    subgraph Marts_Finance["🟣 Finance Marts"]
        STG1 & FCT1 & STG3 --> REV[fct_revenue<br/>Revenue aggregates]
        REV --> REG[region_summary<br/>Dynamic rollup]
    end
    
    subgraph Snapshots["📸 Snapshots"]
        STG1 -.->|SCD Type 2| SNAP[snap_customers_history<br/>Change tracking]
    end
    
    subgraph Testing["🧪 Quality Gates"]
        QC1[50+ Tests]
        QC2[Custom Tests]
        QC3[Data Tests]
    end
    
    STG1 & STG2 & STG3 --> QC1
    INT1 & INT2 --> QC1
    DIM & FCT1 & LTV & REV & REG --> QC2
    FCT1 & REV --> QC3
    
    style Seeds fill:#f9f9f9
    style Staging fill:#e3f2fd
    style Intermediate fill:#e8f5e9
    style Marts_Core fill:#fff3e0
    style Marts_Finance fill:#f3e5f5
    style Snapshots fill:#fce4ec
    style Testing fill:#f1f8e9
```

## Detailed Flow by Layer

### 1. Seeds to Staging

```mermaid
graph LR
    A[raw_customers] -->|Clean names| B[stg_customers]
    C[raw_orders] -->|Handle soft-deletes| D[stg_orders]
    E[raw_payments] -->|Normalize methods| F[stg_payments]
    
    style A fill:#f5f5f5
    style B fill:#e3f2fd
    style C fill:#f5f5f5
    style D fill:#e3f2fd
    style E fill:#f5f5f5
    style F fill:#e3f2fd
```

**Transformations**:

| Source | Target | Transformations |
|--------|--------|-----------------|
| `raw_customers` | `stg_customers` | Surrogate keys, normalize regions, fix email casing, standardize status, clean names |
| `raw_orders` | `stg_orders` | Handle soft-deletes, fix status casing, cast numeric types, add timestamps |
| `raw_payments` | `stg_payments` | Normalize payment methods, cast amounts, track provider IDs |

### 2. Staging to Intermediate

```mermaid
graph LR
    A[stg_customers] & B[stg_orders] & C[stg_payments] --> D[int_order_payments]
    B --> E[int_order_status_categorized]
    
    style A fill:#e3f2fd
    style B fill:#e3f2fd
    style C fill:#e3f2fd
    style D fill:#e8f5e9
    style E fill:#e8f5e9
```

**Business Logic**:

**`int_order_payments`**:
- Rolls up payments per order
- Calculates payment coverage (payments vs order_total)
- Identifies partial payments
- Tracks refunds and chargebacks

**`int_order_status_categorized`**:
- Groups order statuses into categories
- Completed: completed, shipped, delivered
- Open: placed, confirmed, processing
- Canceled: canceled, returned, refunded

### 3. Intermediate to Marts

```mermaid
graph TD
    subgraph Core["Core Marts"]
        A[stg_customers] --> D[dim_customers]
        B[stg_orders] & C[int_order_payments] & E[int_order_status] --> F[fct_orders]
        A & B & F --> G[fct_customer_ltv]
    end
    
    subgraph Finance["Finance Marts"]
        A & F & S[stg_payments] --> H[fct_revenue]
        H --> I[region_summary]
    end
    
    style A fill:#e3f2fd
    style B fill:#e3f2fd
    style C fill:#e8f5e9
    style D fill:#fff3e0
    style E fill:#e8f5e9
    style F fill:#fff3e0
    style G fill:#fff3e0
    style H fill:#f3e5f5
    style I fill:#f3e5f5
    style S fill:#e3f2fd
```

**Marts Transformations**:

| Model | Input Models | Transformations |
|-------|--------------|-----------------|
| `dim_customers` | `stg_customers` | Deduplicate to latest, grant reporter access |
| `fct_orders` | `stg_orders`, `int_order_payments`, `int_order_status_categorized` | Incremental merge on order_id, partition by updated_at |
| `fct_customer_ltv` | `stg_customers`, `stg_orders`, `fct_orders` | Aggregate net revenue, order counts, cohort metrics |
| `fct_revenue` | `stg_customers`, `fct_orders`, `stg_payments` | Daily revenue by region and currency |
| `region_summary` | `fct_revenue` | Dynamic rollup using macro generation |

### 4. Staging to Snapshots

```mermaid
graph LR
    A[stg_customers] -.->|SCD Type 2| B[snap_customers_history]
    
    style A fill:#e3f2fd
    style B fill:#fce4ec
```

**Change Tracking**:
- Captures all customer attribute changes
- Uses `updated_at` timestamp for versioning
- Maintains `dbt_valid_from` and `dbt_valid_to` dates
- Invalidates hard deletes

## Data Quality Checkpoints

```mermaid
graph LR
    A[Raw Data] -->|1. Validate Schema| B[Staging]
    B -->|2. Test Relationships| C[Intermediate]
    C -->|3. Reconcile Metrics| D[Marts]
    D -->|4. Cross-Mart Check| E[Analytics]
    
    style A fill:#ffebee
    style B fill:#e3f2fd
    style C fill:#e8f5e9
    style D fill:#fff3e0
    style E fill:#c8e6c9
```

### Quality Gates

1. **Staging Layer**:
   - Not null checks on keys
   - Unique constraints (with warnings for known issues)
   - Accepted values for status fields
   - Alphanumeric validation for IDs

2. **Intermediate Layer**:
   - Relationship tests between models
   - Range checks for numeric values
   - Status categorization validation

3. **Marts Layer**:
   - Contract enforcement with data types
   - Foreign key relationships
   - Cross-mart reconciliation (revenue consistency)
   - Metric range validations

## Change Tracking Strategy

### Incremental Updates

**`fct_orders`** uses incremental processing:

```mermaid
graph TD
    A[New/Updated Records] -->|WHERE updated_at > max| B[Incremental Merge]
    C[Existing Records] -->|Keep unchanged| B
    B --> D[Updated fct_orders]
    
    style A fill:#c8e6c9
    style B fill:#e3f2fd
    style C fill:#fff3e0
    style D fill:#c8e6c9
```

**Strategy**:
- Unique key: `order_id`
- Strategy: `merge`
- Filter: `updated_at > (SELECT MAX(updated_at) FROM {{ this }})`

### Historical Tracking

**`snap_customers_history`** uses SCD Type 2:

```mermaid
graph LR
    A[Customer Change] -->|New record| B[Insert with dbt_valid_from]
    B -->|Previous record| C[Update dbt_valid_to]
    C --> D[Historical view]
    
    style A fill:#c8e6c9
    style B fill:#e3f2fd
    style C fill:#fff3e0
    style D fill:#f3e5f5
```

**Output Columns**:
- `customer_id` - Natural key
- All customer attributes
- `dbt_valid_from` - Record valid start date
- `dbt_valid_to` - Record valid end date (null = current)
- `dbt_scd_id` - SCD record identifier

## Dependencies

### Model Dependency Graph

```mermaid
graph TD
    subgraph Sources["Sources"]
        SC[raw_customers]
        SO[raw_orders]
        SP[raw_payments]
    end
    
    subgraph Staging["Staging"]
        STG_C[stg_customers]
        STG_O[stg_orders]
        STG_P[stg_payments]
    end
    
    subgraph Intermediate["Intermediate"]
        INT_OP[int_order_payments]
        INT_OSC[int_order_status_categorized]
    end
    
    subgraph Marts["Marts"]
        DIM_C[dim_customers]
        FCT_O[fct_orders]
        FCT_LTV[fct_customer_ltv]
        FCT_REV[fct_revenue]
        REG_SUM[region_summary]
    end
    
    SC --> STG_C
    SO --> STG_O
    SP --> STG_P
    
    STG_C & STG_O & STG_P --> INT_OP
    STG_O --> INT_OSC
    
    STG_C --> DIM_C
    STG_O & INT_OP & INT_OSC --> FCT_O
    STG_C & STG_O & FCT_O --> FCT_LTV
    STG_C & FCT_O & STG_P --> FCT_REV
    FCT_REV --> REG_SUM
    
    style Sources fill:#f5f5f5
    style Staging fill:#e3f2fd
    style Intermediate fill:#e8f5e9
    style Marts fill:#fff3e0
```

### Critical Path

The critical path for most analytics:

```
raw_orders → stg_orders → int_order_payments → fct_orders → fct_revenue
```

Any failure in this chain affects revenue reporting.

## Exposures

Downstream dependencies documented in `exposures.yml`:

```mermaid
graph LR
    subgraph Marts["Marts"]
        FCT_O[fct_orders]
        DIM_C[dim_customers]
        FCT_REV[fct_revenue]
        FCT_LTV[fct_customer_ltv]
    end
    
    subgraph Exposures["Exposures"]
        DASH[Finance Executive Dashboard]
        APP[Customer LTV App]
    end
    
    FCT_O & DIM_C & FCT_REV --> DASH
    FCT_LTV & DIM_C --> APP
    
    style Marts fill:#e3f2fd
    style Exposures fill:#f3e5f5
```

| Exposure | Type | Depends On | Owner |
|----------|------|------------|-------|
| Finance Executive Dashboard | Dashboard | `fct_revenue`, `fct_orders`, `dim_customers` | Finance Analytics |
| Customer LTV App | Application | `fct_customer_ltv`, `dim_customers` | Customer Intelligence |

## Related Documentation

- [Layer Details](layers.md) - In-depth explanation of each layer
- [Design Patterns](patterns.md) - Architectural patterns used
- [Data Dictionary](../reference/data-dictionary.md) - Field-level documentation
