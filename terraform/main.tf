provider "google" {
  credentials = file(var.credentials)
  project = var.project
  region  = var.region
}

# Create a BigQuery dataset
resource "google_bigquery_dataset" "stock_dataset" {
  dataset_id                  = var.dataset_id
  friendly_name               = "Stock Market Data"
  description                 = "Contains stock market data for analysis"
  location                    = "US"
  delete_contents_on_destroy  = true

  # Access control
  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }
}

# Create table for raw stock data
resource "google_bigquery_table" "stock_raw_data" {
  dataset_id = google_bigquery_dataset.stock_dataset.dataset_id
  table_id   = "stock_data_raw"
  description = "Raw stock market data imported from yfinance API"
  deletion_protection = false

  # Define schema explicitly
  schema = <<EOF
[
  {"name": "date", "type": "DATE", "mode": "REQUIRED", "description": "Trading date"},
  {"name": "symbol", "type": "STRING", "mode": "REQUIRED", "description": "Stock ticker symbol"},
  {"name": "open", "type": "FLOAT", "mode": "NULLABLE", "description": "Opening price"},
  {"name": "high", "type": "FLOAT", "mode": "NULLABLE", "description": "High price"},
  {"name": "low", "type": "FLOAT", "mode": "NULLABLE", "description": "Low price"},
  {"name": "close", "type": "FLOAT", "mode": "NULLABLE", "description": "Closing price"},
  {"name": "adj_close", "type": "FLOAT", "mode": "NULLABLE", "description": "Adjusted closing price"},
  {"name": "volume", "type": "INTEGER", "mode": "NULLABLE", "description": "Trading volume"},
  {"name": "load_timestamp", "type": "TIMESTAMP", "mode": "NULLABLE", "description": "Timestamp when data was loaded"},
  {"name": "load_date", "type": "DATE", "mode": "NULLABLE", "description": "Date when data was loaded"}
]
EOF
} 