#!/bin/bash
# Quick start script for dbt Production Blueprint with DuckDB

set -e

echo "🚀 Setting up dbt Production Blueprint with DuckDB..."
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.8 or higher."
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"
echo ""

# Create virtual environment (optional but recommended)
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
    echo "✅ Virtual environment created"
    echo ""
fi

# Activate virtual environment
echo "🔌 Activating virtual environment..."
source venv/bin/activate
echo "✅ Virtual environment activated"
echo ""

# Install dependencies (includes dbt-duckdb adapter)
echo "📥 Installing Python dependencies (including dbt-duckdb adapter)..."
pip install --upgrade pip
pip install -r requirements.txt
echo "✅ Dependencies installed"
echo ""

# Install dbt packages
echo "📦 Installing dbt packages (dbt_utils, dbt_expectations, audit_helper)..."
dbt deps
echo "✅ dbt packages installed"
echo ""

# Load seed data
echo "🌱 Loading seed data..."
dbt seed
echo "✅ Seed data loaded"
echo ""

# Build all models
echo "🏗️  Building all models..."
dbt build
echo "✅ Models built successfully"
echo ""

# Generate documentation
echo "📚 Generating documentation..."
dbt docs generate
echo "✅ Documentation generated"
echo ""

echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "  - Run dbt commands: dbt run, dbt test, dbt build"
echo "  - View documentation: dbt docs serve"
echo "  - Explore the data: duckdb dev.duckdb"
echo ""
echo "To deactivate the virtual environment, run: deactivate"
