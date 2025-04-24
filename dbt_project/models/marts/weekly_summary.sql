/*
  Weekly Stock Summary Model
  
  This model:
  1. Aggregates daily metrics by week
  2. Calculates weekly high, low, and average values
  3. Calculates week-over-week performance metrics
*/

{{ config(materialized='table') }}

WITH daily_data AS (
    -- Reference the daily metrics model
    SELECT
        date,
        symbol,
        open,
        high,
        low,
        close,
        volume,
        daily_return,
        daily_volatility
    FROM
        {{ ref('daily_metrics') }}
),

-- Group data by week
weekly_grouped AS (
    SELECT
        -- Get first day of week (Monday)
        DATE_TRUNC(date, WEEK) AS week_starting,
        symbol,
        -- Aggregations
        AVG(daily_return) AS avg_daily_return,
        AVG(daily_volatility) AS avg_daily_volatility,
        MAX(high) AS weekly_high,
        MIN(low) AS weekly_low,
        SUM(volume) AS weekly_volume,
        COUNT(*) AS trading_days,
        -- Get first and last values per week
        MIN(date) AS first_day_of_week,
        MAX(date) AS last_day_of_week
    FROM
        daily_data
    GROUP BY
        week_starting, symbol
),

-- Get opening and closing values for each week
weekly_prices AS (
    SELECT
        w.week_starting,
        w.symbol,
        w.first_day_of_week,
        w.last_day_of_week,
        -- Get opening price from first day
        (SELECT d.open FROM daily_data d 
         WHERE d.date = w.first_day_of_week AND d.symbol = w.symbol) AS week_open,
        -- Get closing price from last day
        (SELECT d.close FROM daily_data d 
         WHERE d.date = w.last_day_of_week AND d.symbol = w.symbol) AS week_close
    FROM
        weekly_grouped w
)

-- Combine weekly metrics
SELECT
    w.week_starting,
    w.symbol,
    w.avg_daily_return,
    w.avg_daily_volatility,
    w.weekly_high,
    w.weekly_low,
    w.weekly_volume,
    w.trading_days,
    p.week_open,
    p.week_close,
    -- Calculate weekly return percentage
    ROUND((p.week_close - p.week_open) / NULLIF(p.week_open, 0) * 100, 2) AS weekly_return
FROM
    weekly_grouped w
JOIN
    weekly_prices p
    ON w.week_starting = p.week_starting AND w.symbol = p.symbol
ORDER BY
    w.week_starting DESC, w.symbol 