output "bigquery_dataset_id" {
  description = "The ID of the BigQuery dataset"
  value       = google_bigquery_dataset.stock_dataset.dataset_id
}

output "bigquery_table_id" {
  description = "The ID of the BigQuery raw data table"
  value       = google_bigquery_table.stock_raw_data.table_id
}

output "bigquery_table_path" {
  description = "The full path to the BigQuery raw data table"
  value       = "${google_bigquery_dataset.stock_dataset.dataset_id}.${google_bigquery_table.stock_raw_data.table_id}"
} 