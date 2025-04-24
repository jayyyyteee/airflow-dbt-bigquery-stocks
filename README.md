# Airflow-dbt-BigQuery Data Pipeline

A streamlined data pipeline that extracts stock market data from yfinance API, loads it directly to BigQuery, and transforms it using dbt.

## Architecture

This pipeline demonstrates a modern ELT architecture with:

- **Data Source**: yfinance API for stock market data
- **Orchestration**: Apache Airflow
- **Data Warehouse**: Google BigQuery
- **Transformation Tool**: dbt (data build tool)
- **Infrastructure**: Terraform for GCP resources
- **Containerization**: Docker & Docker Compose

## Components

- `docker-compose.yml`: Sets up the containerized environment
- `Dockerfile`: Custom Airflow image with dbt and required dependencies
- `terraform/`: Infrastructure as code for GCP resources
- `dags/`: Airflow DAGs for orchestrating the pipeline
- `dbt_project/`: dbt models for data transformation
- `scripts/`: Helper scripts for setup and maintenance

## Pipeline Flow

1. **Extract**: Pull stock market data from yfinance API
2. **Load**: Store raw data directly in BigQuery 
3. **Transform**: Use dbt to create validated and transformed models
4. **Test**: Run dbt tests on transformed models

## Setup Instructions

### Prerequisites

- Docker and Docker Compose
- Google Cloud Platform account
- GCP project with BigQuery API enabled
- Service account with BigQuery permissions

### Getting Started

1. Clone this repository:
   ```
   git clone <repository-url>
   cd airflow-dbt-demo
   ```

2. Set up sensitive information (not included in the repository):
   ```
   # Create environment file from template
   cp .env.template .env
   # Edit with your specific values
   nano .env
   
   # Create keys directory
   mkdir -p keys
   # Place your GCP service account key in keys/service-account.json
   # You can use the template as a reference
   cp service-account.json.template keys/service-account.json
   nano keys/service-account.json
   ```

3. Run the setup script:
   ```
   chmod +x scripts/setup_environment.sh
   ./scripts/setup_environment.sh
   ```

4. Deploy BigQuery resources using Terraform:
   ```
   cd terraform
   terraform init
   terraform apply
   ```

5. Start the containers:
   ```
   docker-compose up -d
   ```

6. Access Airflow web UI at http://localhost:8080 (username: admin, password: from your .env)

7. Activate and trigger the `stock_market_pipeline` DAG

## Contributing and GitHub Setup

This repository follows best practices for handling sensitive information:

1. **Do not commit sensitive files**:
   - `.env` - Contains environment variables and secrets
   - `keys/` - Contains service account keys and credentials
   - `terraform.tfstate` - Contains infrastructure state that may reveal sensitive data

2. **Use the templates**:
   - `.env.template` - Copy to `.env` and fill in your values
   - `service-account.json.template` - Reference for creating service account key

3. **Before pushing to GitHub**:
   - Ensure you haven't accidentally committed any sensitive files
   - The `.gitignore` is set up to exclude most sensitive files by default

## Pipeline Details

### Data Validation

The pipeline performs these data quality checks:
- Basic validation in the Python extraction step:
  - Missing values in required fields
  - Negative prices
  - High price < low price inconsistencies
- Additional validation and testing through dbt

### Data Transformations

The dbt models include:
- Staging views with cleaned and standardized data
- Daily metrics with return calculations and moving averages
- Weekly aggregations with performance summaries

## Learning Resources

This project is designed to demonstrate data engineering best practices for:
- Data pipeline architecture
- Data quality management
- ELT implementation
- Infrastructure as code
- Workflow orchestration
- SQL-based transformations 