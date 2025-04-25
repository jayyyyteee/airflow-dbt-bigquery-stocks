FROM apache/airflow:2.6.3

# Switch to root to install packages
USER root

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libffi-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create directories with proper permissions for dbt
RUN mkdir -p /tmp/dbt_target /opt/airflow/dbt_project/target /opt/airflow/dbt_project/logs && \
    chmod -R 777 /tmp/dbt_target /opt/airflow/dbt_project/target /opt/airflow/dbt_project/logs

# Switch back to airflow user
USER airflow

# Install Python dependencies
# Each package is listed on a separate line with a comment for clarity
RUN pip install --no-cache-dir \
    # Data transformation framework
    dbt-core==1.5.0 \
    # BigQuery adapter for dbt
    dbt-bigquery==1.5.0 \
    # Stock data API client
    yfinance \
    # Data manipulation library
    pandas \
    # BigQuery pandas connector
    pandas-gbq \
    # SQL toolkit 
    sqlalchemy \
    # MySQL Python interface
    pymysql \
    # For peewee ORM
    peewee \
    # Machine learning packages
    scikit-learn \
    joblib \
    # Date and holiday utilities
    holidays

# Set working directory
WORKDIR /opt/airflow 