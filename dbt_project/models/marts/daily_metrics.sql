/*
  Daily Stock Metrics Model
  
  This model:
  1. Calculates daily return percentages
  2. Calculates daily volatility
  3. Calculates 5-day moving averages
  4. Adds day-of-week information
*/

{{ config(materialized='table') }}

WITH source_data AS (
    -- Get data from staging model
    SELECT
        date,
        symbol,
        open,
        high,
        low,
        close,
        volume
    FROM
        {{ ref('stg_stock_data') }}  -- Reference staging model instead of source
)

SELECT
    date,
    symbol,
    open,
    high,
    low,
    close,
    volume,
    
    -- Calculate daily return (percentage change from previous day)
    ROUND((close - LAG(close) OVER (PARTITION BY symbol ORDER BY date)) / 
          NULLIF(LAG(close) OVER (PARTITION BY symbol ORDER BY date), 0) * 100, 2) AS daily_return,
    
    -- Calculate daily volatility (high-low as percentage of open)
    ROUND((high - low) / NULLIF(open, 0) * 100, 2) AS daily_volatility,
    
    -- Calculate 5-day moving average
    ROUND(AVG(close) OVER (
        PARTITION BY symbol 
        ORDER BY date 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_5d,
    
    -- Extract day of week (1=Sunday, 7=Saturday)
    EXTRACT(DAYOFWEEK FROM date) AS day_of_week,
    
    -- Add trading day categorization
    CASE
        WHEN close > open THEN 'Up'
        WHEN close < open THEN 'Down'
        ELSE 'Flat'
    END AS day_direction
    
FROM
    source_data
ORDER BY
    symbol, date 