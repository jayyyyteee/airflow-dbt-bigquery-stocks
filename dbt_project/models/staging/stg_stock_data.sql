/*
  Staging Model for Stock Data
  
  A simple pass-through model that standardizes column names
  and provides a clean interface for downstream models.
*/

{{ config(materialized='view') }}

SELECT
    date,
    symbol,
    open,
    high,
    low,
    close,
    volume
FROM
    {{ source('bigquery_raw', 'stock_data_raw') }} 