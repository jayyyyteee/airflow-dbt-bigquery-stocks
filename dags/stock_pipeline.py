from datetime import datetime, timedelta
import os
import pandas as pd
import yfinance as yf
import pandas_gbq
from google.oauth2 import service_account
import logging

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.operators.dummy import DummyOperator

# Default DAG arguments
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 0,
    'retry_delay': timedelta(minutes=5),
}

# Environment variables and constants
STOCKS = os.environ.get('STOCK_SYMBOLS')
# Split the stock symbols by comma
STOCKS = [symbol.strip() for symbol in STOCKS.split(',')] if STOCKS else []

PROJECT_ID = os.environ.get('GCP_PROJECT_ID')
DATASET_ID = os.environ.get('BIGQUERY_DATASET_ID')
TABLE_ID = os.environ.get('BIGQUERY_TABLE_ID')
STOCK_HISTORY_DAYS = int(os.environ.get('STOCK_HISTORY_DAYS', 365))
SERVICE_ACCOUNT_PATH = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')

# Construct BigQuery table reference
BQ_TABLE_PATH = f"{DATASET_ID}.{TABLE_ID}"

def deduplicate_column_names(columns):
    new_columns = []
    seen = set()
    
    for col in columns:
        base_col = col
        counter = 0
        while col in seen:
            counter += 1
            col = f"{base_col}.{counter}"
        seen.add(col)
        new_columns.append(col)
    
    return new_columns

# Define the DAG
dag = DAG(
    'stock_market_pipeline',
    default_args=default_args,
    description='A streamlined ELT pipeline for stock market data',
    schedule_interval=timedelta(days=1),
    start_date=datetime(2023, 1, 1),
    catchup=False,
    tags=['stocks', 'yfinance', 'bigquery', 'dbt', 'elt'],
)

def extract_and_load_to_bigquery(**context):
    print(f"Starting extraction for: {STOCKS}")
    end_date = datetime.now()
    start_date = end_date - timedelta(days=STOCK_HISTORY_DAYS)
    
    # Create an empty DataFrame to store all results
    final_df = pd.DataFrame()
    
    # Process each stock one at a time
    for stock in STOCKS:
        try:
            print(f"Downloading data for {stock}...")
            
            # Use the Ticker object directly for more control
            ticker = yf.Ticker(stock)
            # Get the historical data
            hist = ticker.history(start=start_date, end=end_date)
            
            # If empty, skip to next stock
            if hist.empty:
                print(f"No data found for {stock}")
                continue
                
            # Reset index to get Date as a column
            hist = hist.reset_index()
            
            # Select and rename only the columns we want
            selected_columns = {
                'Date': 'date',
                'Open': 'open',
                'High': 'high',
                'Low': 'low',
                'Close': 'close',
                'Volume': 'volume'
            }
            
            # Check if Adj Close exists and include it
            if 'Adj Close' in hist.columns:
                selected_columns['Adj Close'] = 'adj_close'
            
            # Get only the columns we need
            stock_df = hist[[col for col in selected_columns.keys() if col in hist.columns]]
            
            # Rename the columns
            for old_col, new_col in selected_columns.items():
                if old_col in stock_df.columns:
                    stock_df = stock_df.rename(columns={old_col: new_col})
            
            # Add symbol column
            stock_df['symbol'] = stock
            
            # Verify columns are correct before appending
            print(f"Columns for {stock}: {stock_df.columns.tolist()}")
            
            # Append to final dataframe
            final_df = pd.concat([final_df, stock_df], ignore_index=True)
            
            print(f"Downloaded {len(stock_df)} rows for {stock}")
        except Exception as e:
            print(f"Error downloading {stock}: {str(e)}")
    
    if final_df.empty:
        raise ValueError("No stock data could be retrieved")
    
    # Add metadata columns
    final_df['load_timestamp'] = datetime.now()
    final_df['load_date'] = datetime.now().date()
    
    # Print detailed information for debugging
    print(f"Final dataframe shape: {final_df.shape}")
    print(f"Columns: {final_df.columns.tolist()}")
    print(f"Data types: {final_df.dtypes}")
    print(f"First 3 rows sample:\n{final_df.head(3)}")
    
    # Count rows per stock for verification
    stock_counts = final_df.groupby('symbol').size()
    print(f"Rows per stock: {dict(stock_counts)}")
    
    # Upload to BigQuery
    credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_PATH,
        scopes=["https://www.googleapis.com/auth/bigquery"]
    )
    
    pandas_gbq.to_gbq(
        final_df,
        f'{DATASET_ID}.{TABLE_ID}',
        project_id=PROJECT_ID,
        if_exists='replace',
        credentials=credentials
    )
    
    return {
        'load_time': datetime.now().isoformat(),
        'rows_loaded': len(final_df),
        'symbols_loaded': ','.join(final_df['symbol'].unique()),
        'target': f'{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}'
    }

def log_load_results(**context):
    ti = context['ti']
    result = ti.xcom_pull(task_ids='extract_and_load_to_bigquery')
    print("==== LOAD SUMMARY ====")
    for key, value in result.items():
        print(f"{key}: {value}")
    
    # Get total number of rows and symbols
    rows = result.get('rows_loaded', 0)
    symbols = result.get('symbols_loaded', '').split(',')
    
    print(f"\nLoaded {rows} total rows for {len(symbols)} symbols")
    print(f"Average rows per symbol: {rows / len(symbols) if symbols else 0:.1f}")
    print("=======================")

start_pipeline = DummyOperator(task_id='start_pipeline', dag=dag)
extract_load = PythonOperator(task_id='extract_and_load_to_bigquery', python_callable=extract_and_load_to_bigquery, dag=dag)
log_results = PythonOperator(task_id='log_load_results', python_callable=log_load_results, dag=dag)
run_dbt = BashOperator(
    task_id='run_dbt_transformations', 
    bash_command='cd /opt/airflow/dbt_project && dbt run --profiles-dir . --target-path ${DBT_TARGET_PATH:-/tmp/dbt_target}', 
    dag=dag
)
test_dbt = BashOperator(
    task_id='test_dbt_models', 
    bash_command='cd /opt/airflow/dbt_project && dbt test --profiles-dir . --target-path ${DBT_TARGET_PATH:-/tmp/dbt_target}', 
    dag=dag
)
end_pipeline = DummyOperator(task_id='end_pipeline', dag=dag)

start_pipeline >> extract_load >> log_results >> run_dbt >> test_dbt >> end_pipeline
