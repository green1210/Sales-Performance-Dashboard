-- ============================================================================
-- SALES PERFORMANCE DASHBOARD - REVENUE ANALYSIS QUERIES
-- ============================================================================
-- Purpose: Analyze revenue trends across time, categories, and regions
-- Author: Data Analytics Portfolio Project
-- Date: January 2026
-- ============================================================================

-- ============================================================================
-- 1. MONTHLY REVENUE TREND WITH GROWTH RATE
-- ============================================================================
-- Business Question: What is our month-over-month revenue performance?
-- Key Metrics: Total revenue, transaction count, growth rate

WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        COUNT(DISTINCT transaction_id) AS total_transactions,
        COUNT(DISTINCT customer_id) AS unique_customers,
        SUM(revenue) AS total_revenue,
        AVG(revenue) AS avg_order_value,
        SUM(quantity) AS total_units_sold
    FROM sales_data
    GROUP BY DATE_TRUNC('month', order_date)
),
revenue_with_growth AS (
    SELECT 
        month,
        total_transactions,
        unique_customers,
        total_revenue,
        avg_order_value,
        total_units_sold,
        -- Calculate month-over-month growth
        LAG(total_revenue) OVER (ORDER BY month) AS prev_month_revenue,
        ROUND(
            ((total_revenue - LAG(total_revenue) OVER (ORDER BY month)) / 
            NULLIF(LAG(total_revenue) OVER (ORDER BY month), 0)) * 100, 
            2
        ) AS revenue_growth_pct,
        -- Calculate 3-month moving average
        ROUND(
            AVG(total_revenue) OVER (
                ORDER BY month 
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ), 
            2
        ) AS revenue_3month_ma
    FROM monthly_revenue
)
SELECT 
    TO_CHAR(month, 'YYYY-MM') AS month,
    total_transactions,
    unique_customers,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(avg_order_value, 2) AS avg_order_value,
    total_units_sold,
    COALESCE(revenue_growth_pct, 0) AS mom_growth_pct,
    revenue_3month_ma
FROM revenue_with_growth
ORDER BY month;


-- ============================================================================
-- 2. QUARTERLY REVENUE ANALYSIS WITH YEAR-OVER-YEAR COMPARISON
-- ============================================================================
-- Business Question: How do quarters perform year-over-year?

WITH quarterly_revenue AS (
    SELECT 
        EXTRACT(YEAR FROM order_date) AS year,
        EXTRACT(QUARTER FROM order_date) AS quarter,
        SUM(revenue) AS total_revenue,
        COUNT(DISTINCT customer_id) AS unique_customers,
        AVG(revenue) AS avg_order_value
    FROM sales_data
    GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(QUARTER FROM order_date)
)
SELECT 
    year,
    quarter,
    CONCAT('Q', quarter, ' ', year) AS quarter_label,
    ROUND(total_revenue, 2) AS total_revenue,
    unique_customers,
    ROUND(avg_order_value, 2) AS avg_order_value,
    -- Year-over-year comparison
    LAG(total_revenue) OVER (PARTITION BY quarter ORDER BY year) AS prev_year_revenue,
    ROUND(
        ((total_revenue - LAG(total_revenue) OVER (PARTITION BY quarter ORDER BY year)) / 
        NULLIF(LAG(total_revenue) OVER (PARTITION BY quarter ORDER BY year), 0)) * 100,
        2
    ) AS yoy_growth_pct
FROM quarterly_revenue
ORDER BY year, quarter;


-- ============================================================================
-- 3. REVENUE BY PRODUCT CATEGORY (PARETO ANALYSIS)
-- ============================================================================
-- Business Question: Which categories drive 80% of revenue?

WITH category_revenue AS (
    SELECT 
        product_category,
        SUM(revenue) AS total_revenue,
        COUNT(DISTINCT transaction_id) AS total_transactions,
        COUNT(DISTINCT customer_id) AS unique_customers,
        AVG(revenue) AS avg_order_value,
        SUM(quantity) AS total_units_sold
    FROM sales_data
    GROUP BY product_category
),
category_ranked AS (
    SELECT 
        product_category,
        total_revenue,
        total_transactions,
        unique_customers,
        avg_order_value,
        total_units_sold,
        -- Calculate percentage of total revenue
        ROUND(
            (total_revenue / SUM(total_revenue) OVER ()) * 100, 
            2
        ) AS revenue_pct,
        -- Calculate cumulative percentage
        ROUND(
            SUM(total_revenue) OVER (
                ORDER BY total_revenue DESC 
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) / SUM(total_revenue) OVER () * 100,
            2
        ) AS cumulative_revenue_pct
    FROM category_revenue
)
SELECT 
    product_category,
    ROUND(total_revenue, 2) AS total_revenue,
    revenue_pct,
    cumulative_revenue_pct,
    total_transactions,
    unique_customers,
    ROUND(avg_order_value, 2) AS avg_order_value,
    total_units_sold,
    -- Flag top 80% categories
    CASE 
        WHEN cumulative_revenue_pct <= 80 THEN 'Top 80%'
        ELSE 'Bottom 20%'
    END AS revenue_segment
FROM category_ranked
ORDER BY total_revenue DESC;


-- ============================================================================
-- 4. REVENUE BY REGION WITH PERFORMANCE METRICS
-- ============================================================================
-- Business Question: Which regions are most profitable?

WITH region_metrics AS (
    SELECT 
        region,
        COUNT(DISTINCT transaction_id) AS total_transactions,
        COUNT(DISTINCT customer_id) AS unique_customers,
        SUM(revenue) AS total_revenue,
        AVG(revenue) AS avg_order_value,
        SUM(CASE WHEN discount > 0 THEN 1 ELSE 0 END) AS discounted_orders,
        AVG(discount) AS avg_discount_rate
    FROM sales_data
    GROUP BY region
)
SELECT 
    region,
    total_transactions,
    unique_customers,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(avg_order_value, 2) AS avg_order_value,
    discounted_orders,
    ROUND(avg_discount_rate * 100, 2) AS avg_discount_pct,
    -- Calculate revenue per customer
    ROUND(total_revenue / unique_customers, 2) AS revenue_per_customer,
    -- Calculate market share
    ROUND(
        (total_revenue / SUM(total_revenue) OVER ()) * 100, 
        2
    ) AS market_share_pct,
    -- Rank regions by revenue
    DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM region_metrics
ORDER BY total_revenue DESC;


-- ============================================================================
-- 5. REVENUE BY SALES CHANNEL WITH CONVERSION METRICS
-- ============================================================================
-- Business Question: How do online vs offline channels perform?

WITH channel_performance AS (
    SELECT 
        sales_channel,
        COUNT(DISTINCT transaction_id) AS total_transactions,
        COUNT(DISTINCT customer_id) AS unique_customers,
        SUM(revenue) AS total_revenue,
        AVG(revenue) AS avg_order_value,
        SUM(quantity) AS total_units_sold,
        AVG(discount) AS avg_discount_rate
    FROM sales_data
    GROUP BY sales_channel
)
SELECT 
    sales_channel,
    total_transactions,
    unique_customers,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(avg_order_value, 2) AS avg_order_value,
    total_units_sold,
    ROUND(avg_discount_rate * 100, 2) AS avg_discount_pct,
    -- Calculate transactions per customer
    ROUND(total_transactions::NUMERIC / unique_customers, 2) AS transactions_per_customer,
    -- Calculate revenue share
    ROUND(
        (total_revenue / SUM(total_revenue) OVER ()) * 100, 
        2
    ) AS revenue_share_pct
FROM channel_performance
ORDER BY total_revenue DESC;


-- ============================================================================
-- 6. CATEGORY + REGION REVENUE MATRIX (CROSS-DIMENSIONAL ANALYSIS)
-- ============================================================================
-- Business Question: Which category-region combinations perform best?

WITH category_region_revenue AS (
    SELECT 
        product_category,
        region,
        SUM(revenue) AS total_revenue,
        COUNT(DISTINCT transaction_id) AS total_transactions,
        AVG(revenue) AS avg_order_value
    FROM sales_data
    GROUP BY product_category, region
)
SELECT 
    product_category,
    region,
    ROUND(total_revenue, 2) AS total_revenue,
    total_transactions,
    ROUND(avg_order_value, 2) AS avg_order_value,
    -- Rank within each category
    DENSE_RANK() OVER (
        PARTITION BY product_category 
        ORDER BY total_revenue DESC
    ) AS region_rank_within_category,
    -- Identify top combinations
    CASE 
        WHEN DENSE_RANK() OVER (ORDER BY total_revenue DESC) <= 10 
        THEN 'Top 10 Combo'
        ELSE 'Other'
    END AS performance_tier
FROM category_region_revenue
ORDER BY total_revenue DESC
LIMIT 50;


-- ============================================================================
-- 7. DAILY REVENUE PATTERN (DAY OF WEEK ANALYSIS)
-- ============================================================================
-- Business Question: Which days of the week generate most revenue?

SELECT 
    TO_CHAR(order_date, 'Day') AS day_of_week,
    EXTRACT(DOW FROM order_date) AS day_number,
    COUNT(DISTINCT transaction_id) AS total_transactions,
    SUM(revenue) AS total_revenue,
    AVG(revenue) AS avg_order_value,
    ROUND(
        (SUM(revenue) / (SELECT SUM(revenue) FROM sales_data)) * 100, 
        2
    ) AS revenue_share_pct
FROM sales_data
GROUP BY TO_CHAR(order_date, 'Day'), EXTRACT(DOW FROM order_date)
ORDER BY day_number;


-- ============================================================================
-- 8. REVENUE COHORT ANALYSIS (BY ORDER MONTH)
-- ============================================================================
-- Business Question: How does revenue retention look across monthly cohorts?

WITH first_purchase AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM sales_data
    GROUP BY customer_id
),
customer_revenue AS (
    SELECT 
        f.cohort_month,
        DATE_TRUNC('month', s.order_date) AS purchase_month,
        COUNT(DISTINCT s.customer_id) AS customers,
        SUM(s.revenue) AS total_revenue
    FROM sales_data s
    JOIN first_purchase f ON s.customer_id = f.customer_id
    GROUP BY f.cohort_month, DATE_TRUNC('month', s.order_date)
)
SELECT 
    TO_CHAR(cohort_month, 'YYYY-MM') AS cohort_month,
    TO_CHAR(purchase_month, 'YYYY-MM') AS purchase_month,
    customers,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(total_revenue / customers, 2) AS revenue_per_customer,
    -- Calculate months since first purchase
    EXTRACT(MONTH FROM AGE(purchase_month, cohort_month)) AS months_since_first_purchase
FROM customer_revenue
WHERE cohort_month >= '2023-01-01'
ORDER BY cohort_month, purchase_month
LIMIT 100;
