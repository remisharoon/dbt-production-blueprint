# dbt Production Blueprint

<div class="hero">
  <h1>Enterprise-Grade dbt Blueprint</h1>
  <p>A production-ready reference implementation for Snowflake data warehousing with best practices, comprehensive testing, and operational excellence.</p>
  <a href="setup.md">Get Started →</a>
</div>

<div class="scroll-indicator">
  <span>⬇</span>
</div>

## :rocket: What is dbt Production Blueprint?

**dbt Production Blueprint** is a comprehensive, enterprise-grade dbt project designed as a reference implementation for real-world data warehousing on Snowflake. It demonstrates production patterns, architectural decisions, and operational practices that scale.

---

## :chart_with_upwards_trend: Project Stats

<div class="stats-grid">
  <div class="stat-card">
    <span class="stat-number">20+</span>
    <span class="stat-label">Models</span>
  </div>
  <div class="stat-card">
    <span class="stat-number">50+</span>
    <span class="stat-label">Tests</span>
  </div>
  <div class="stat-card">
    <span class="stat-number">3</span>
    <span class="stat-label">Data Layers</span>
  </div>
  <div class="stat-card">
    <span class="stat-number">4</span>
    <span class="stat-label">Regions</span>
  </div>
</div>

---

## :star: Key Features

<div class="feature-grid">
  <div class="feature-card">
    <div class="feature-icon">🏗️</div>
    <h3>Layered Architecture</h3>
    <p>Staging, intermediate, and marts layers with clear separation of concerns. Staging standardizes sources, intermediate normalizes business logic, and marts deliver analytics-ready models.</p>
  </div>

  <div class="feature-card">
    <div class="feature-icon">⚡</div>
    <h3>Incremental Processing</h3>
    <p>Efficient incremental updates using merge strategies with unique keys and timestamp filters. Handles soft-deletes and preserves historical data without inflating metrics.</p>
  </div>

  <div class="feature-card">
    <div class="feature-icon">📸</div>
    <h3>SCD Type 2 Snapshots</h3>
    <p>Track customer changes over time with timestamp-based snapshots. Maintain full change history while preserving current state in dimension tables.</p>
  </div>

  <div class="feature-card">
    <div class="feature-icon">🧪</div>
    <h3>Comprehensive Testing</h3>
    <p>Built-in tests (not_null, unique, relationships), dbt_expectations for advanced checks, custom generic tests for ID validation, and cross-mart reconciliation tests.</p>
  </div>

  <div class="feature-card">
    <div class="feature-icon">🔒</div>
    <h3>Contracts & Schema</h3>
    <p>Enforced contracts with column data types, schema enforcement, and automatic fail on schema changes. Column-level documentation is required.</p>
  </div>

  <div class="feature-card">
    <div class="feature-icon">📊</div>
    <h3>Exposures & Metrics</h3>
    <p>Document downstream dependencies including dashboards and applications. Doc blocks define key metrics like Total Revenue and Customer LTV.</p>
  </div>

  <div class="feature-card">
    <div class="feature-icon">🔄</div>
    <h3>Dynamic SQL Generation</h3>
    <p>Macros generate SQL dynamically for patterns like region rollups, reducing code duplication and making queries more maintainable.</p>
  </div>

  <div class="feature-card">
    <div class="feature-icon">🎣</div>
    <h3>Operational Hooks</h3>
    <p>Automated audit logging with run metadata. Post-hook grants for role-based access control. Seamless CI/CD integration with GitHub Actions.</p>
  </div>

  <div class="feature-card">
    <div class="feature-icon">🔍</div>
    <h3>State-Based Selection</h3>
    <p>Efficient CI using state comparison with selectors. Only build modified nodes and their dependencies. Full support for deferral and caching.</p>
  </div>
</div>

---

## :books: Documentation Features

- **Full dbt Docs Integration** - Interactive DAG, lineage visualization, and column-level documentation
- **Architecture Guides** - Detailed explanations of design patterns and conventions
- **Setup Instructions** - Complete installation and configuration guides
- **Troubleshooting** - Common issues and solutions
- **Quick Reference** - Command cheat sheets and best practices

---

## :technologist: Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Warehouse** | Snowflake | Enterprise data warehouse |
| **Transform** | dbt 1.8+ | Data transformation framework |
| **Testing** | dbt_expectations | Advanced data quality testing |
| **CI/CD** | GitHub Actions | Automated testing and deployment |
| **Docs** | MkDocs Material | Modern documentation site |
| **Package** | dbt-duckdb | Local development database |

---

## :wrench: Quick Start

```bash
# Clone the repository
git clone https://github.com/remisharoon/dbt-production-blueprint.git
cd dbt-production-blueprint

# Install dependencies
dbt deps

# Load seed data
dbt seed

# Build everything
dbt build

# View documentation
mkdocs serve
```

<details>
<summary>📖 View Full Setup Guide</summary>

Complete setup instructions are available in our [Setup Guide](setup.md). This includes:

- Profile configuration for Snowflake or DuckDB
- Environment setup and dependencies
- Running tests and validation
- CI/CD configuration

</details>

---

## :folder: Project Structure

```
dbt-production-blueprint/
├── models/
│   ├── staging/          # Raw source normalization
│   ├── intermediate/     # Business logic layer
│   └── marts/          # Analytics-ready models
│       ├── core/       # Dimensions & facts
│       └── finance/    # Revenue aggregates
├── snapshots/          # SCD Type 2 history
├── macros/            # Reusable SQL & tests
├── tests/             # Data quality checks
├── seeds/            # Sample data
└── docs/             # Documentation

```

---

## :bulb: Use Cases

- **Learning Production Patterns** - Understand how enterprise teams structure dbt projects
- **Starting New Projects** - Use as a template with best practices built-in
- **Team Training** - Reference for onboarding data engineers and analysts
- **Data Quality Standards** - Comprehensive testing examples and patterns

---

## :heart: Why This Blueprint?

This isn't just another dbt project. It's a **kitchen sink** of production patterns designed to demonstrate real-world challenges and solutions:

- Intentionally includes data quality issues in seeds for demo purposes
- Tests configured with appropriate severity levels
- Cross-mart reconciliation for revenue consistency
- Custom generic tests for alphanumeric ID validation
- Operational hooks for audit logging and access control
- State-based CI for efficient builds

---

## :link: Explore Further

- [Project Architecture](architecture.md) - Deep dive into layered design
- [Features Guide](features.md) - Complete feature documentation
- [Setup Guide](setup.md) - Installation and configuration
- [Quick Reference](reference.md) - Commands and conventions
- [Troubleshooting](troubleshooting.md) - Common issues and fixes
- [dbt Documentation](dbt_artifacts/index.html) - Interactive data lineage

---

## :star2: Show Your Support

If this blueprint helps you build better data pipelines, consider:

- Starring the repository on GitHub
- Sharing it with your team
- Submitting issues or PRs for improvements
- Following the project for updates

<div class="stats-grid" style="margin-top: 2rem;">
  <div class="stat-card">
    <a href="https://github.com/remisharoon/dbt-production-blueprint" style="color: inherit; text-decoration: none;">
      :star: Star on GitHub
    </a>
  </div>
  <div class="stat-card">
    <a href="https://github.com/remisharoon/dbt-production-blueprint/fork" style="color: inherit; text-decoration: none;">
      🍴 Fork & Customize
    </a>
  </div>
  <div class="stat-card">
    <a href="https://github.com/remisharoon/dbt-production-blueprint/issues" style="color: inherit; text-decoration: none;">
      🐛 Report Issues
    </a>
  </div>
  <div class="stat-card">
    <a href="setup.md" style="color: inherit; text-decoration: none;">
      🚀 Get Started
    </a>
  </div>
</div>

---

<div style="text-align: center; margin: 3rem 0; padding: 2rem; background: var(--md-primary-fg-color--light); border-radius: 0.5rem; color: var(--md-primary-fg-color);">
  <strong style="font-size: 1.5rem; display: block; margin-bottom: 1rem;">Ready to transform your data stack?</strong>
  <a href="setup.md" style="display: inline-block; padding: 0.75rem 2rem; background: var(--md-primary-fg-color); color: var(--md-primary-bg-color); border-radius: 2rem; font-weight: 600; text-decoration: none; transition: all 0.3s ease; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
    Start Building →
  </a>
</div>
