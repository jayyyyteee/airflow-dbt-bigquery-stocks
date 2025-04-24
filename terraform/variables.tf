variable "project" {
    description = "Project"
    default = "terraform-457118"
}

variable "credentials" {
    description = "Project"
    default = "../keys/service-account.json"
}

variable "region" {
  description = "Google Cloud Region"
  type        = string
  default     = "us-central1"
}

variable "dataset_id" {
  description = "BigQuery Dataset ID"
  type        = string
  default     = "stock_market_data"
} 