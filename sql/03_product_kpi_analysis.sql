-- ============================================================================
-- SALES PERFORMANCE DASHBOARD - PRODUCT & KPI ANALYSIS QUERIES
-- ============================================================================
-- Purpose: Product performance, discount impact, and key business metrics
-- Author: Data Analytics Portfolio Project
-- Date: January 2026
-- ============================================================================

-- ============================================================================
-- 1. TOP 10 PRODUCTS BY REVENUE
-- ============================================================================
-- Business Question: Which products drive the most revenue?

WITH product_performance AS (
    SELECT 
        product_id,
        product_category,
        COUNT(DISTINCT transaction_id) AS total_sales,
        COUNT(DISTINCT customer_id) AS unique_customers,
        SUM(quantity) AS total_units_sold,
        SUM(revenue) AS total_revenue,
        AVG(revenue) AS avg_transaction_value,
        AVG(unit_price) AS avg_unit_price,
        AVG(discount) AS avg_discount_rate,
        -- Calculate revenue per unit
        ROUND(SUM(revenue) / SUM(quantity), 2) AS revenue_per_unit
    FROM sales_data
    GROUP BY product_id, product_category
)
SELECT 
    product_id,
    product_category,
    total_sales,
    unique_customers,
    total_units_sold,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(avg_transaction_value, 2) AS avg_transaction_value,
    ROUND(avg_unit_price, 2) AS avg_unit_price,
    ROUND(avg_discount_rate * 100, 2) AS avg_discount_pct,
    revenue_per_unit,
    -- Calculate revenue contribution
    ROUND(
        (total_revenue / SUM(total_revenue) OVER ()) * 100, 
        2
    ) AS revenue_contribution_pct,
    -- Rank products
    DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM product_performance
ORDER BY total_revenue DESC
LIMIT 10;


-- ============================================================================
-- 2. BOTTOM 10 PERFORMING PRODUCTS (LOW REVENUE)
-- ============================================================================
-- Business Question: Which products are underperforming?

WITH product_performance AS (
    SELECT 
        product_id,
        product_category,
        COUNT(DISTINCT transaction_id) AS total_sales,
        SUM(quantity) AS total_units_sold,
        SUM(revenue) AS total_revenue,
        AVG(discount) AS avg_discount_rate,
        MAX(order_date) AS last_sold_date,
        CURRENT_DATE - MAX(order_date)::DATE AS days_since_last_sale
    FROM sales_data
    GROUP BY product_id, product_category
)
SELECT 
    product_id,
    product_category,
    total_sales,
    total_units_sold,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(avg_discount_rate * 100, 2) AS avg_discount_pct,
    last_sold_date,
    days_since_last_sale,
    -- Flag for clearance
    CASE 
        WHEN days_since_last_sale > 180 AND total_revenue < 500 THEN 'Discontinue'
        WHEN days_since_last_sale > 90 THEN 'Clearance'
        WHEN total_revenue < 100 THEN 'Low Demand'
        ELSE 'Monitor'
    END AS product_action
FROM product_performance
ORDER BY total_revenue ASC
LIMIT 10;


-- ============================================================================
-- 3. CATEGORY PERFORMANCE WITH PRODUCT COUNT
-- ============================================================================
-- Business Question: How do product categories perform overall?

WITH category_metrics AS (
    SELECT 
        product_category,
        COUNT(DISTINCT product_id) AS unique_products,
        COUNT(DISTINCT transaction_id) AS total_transactions,
        SUM(quantity) AS total_units_sold,
        SUM(revenue) AS total_revenue,
        AVG(revenue) AS avg_order_value,
        AVG(discount) AS avg_discount_rate,
        -- Calculate sales velocity (transactions per product)
        ROUND(
            COUNT(DISTINCT transaction_id)::NUMERIC / 
            COUNT(DISTINCT product_id), 
            2
        ) AS sales_velocity
    FROM sales_data
    GROUP BY product_category
)
SELECT 
    product_category,
    unique_products,
    total_transactions,
    total_units_sold,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(avg_order_value, 2) AS avg_order_value,
    ROUND(avg_discount_rate * 100, 2) AS avg_discount_pct,
    sales_velocity,
    ROUND(total_revenue / unique_products, 2) AS revenue_per_product,
    -- Market share
    ROUND(
        (total_revenue / SUM(total_revenue) OVER ()) * 100, 
        2
    ) AS market_share_pct,
    -- Performance rating
    CASE 
        WHEN total_revenue > 2000000 THEN 'Excellent'
        WHEN total_revenue > 1000000 THEN 'Good'
        WHEN total_revenue > 500000 THEN 'Average'
        ELSE 'Below Average'
    END AS performance_rating
FROM category_metrics
ORDER BY total_revenue DESC;


-- ============================================================================
-- 4. DISCOUNT IMPACT ANALYSIS
-- ============================================================================
-- Business Question: How do discounts affect sales volume and revenue?

WITH discount_tiers AS (
    SELECT 
        CASE 
            WHEN discount = 0 THEN 'No Discount'
            WHEN discount <= 0.05 THEN '1-5% Discount'
            WHEN discount <= 0.10 THEN '6-10% Discount'
            WHEN discount <= 0.15 THEN '11-15% Discount'
            WHEN discount <= 0.20 THEN '16-20% Discount'
            ELSE '20%+ Discount'
        END AS discount_tier,
        COUNT(DISTINCT transaction_id) AS total_transactions,
        SUM(quantity) AS total_units_sold,
        SUM(revenue) AS total_revenue,
        AVG(revenue) AS avg_order_value,
        SUM(quantity * unit_price * discount) AS total_discount_amount
    FROM sales_data
    GROUP BY 
        CASE 
            WHEN discount = 0 THEN 'No Discount'
            WHEN discount <= 0.05 THEN '1-5% Discount'
            WHEN discount <= 0.10 THEN '6-10% Discount'
            WHEN discount <= 0.15 THEN '11-15% Discount'
            WHEN discount <= 0.20 THEN '16-20% Discount'
            ELSE '20%+ Discount'
        END
)
SELECT 
    discount_tier,
    total_transactions,
    total_units_sold,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(avg_order_value, 2) AS avg_order_value,
    ROUND(total_discount_amount, 2) AS total_discount_given,
    -- Calculate effective price and discount impact
    ROUND(
        (total_discount_amount / (total_revenue + total_discount_amount)) * 100, 
        2
    ) AS effective_discount_pct,
    -- Revenue share
    ROUND(
        (total_revenue / SUM(total_revenue) OVER ()) * 100, 
        2
    ) AS revenue_share_pct
FROM discount_tiers
ORDER BY 
    CASE discount_tier
        WHEN 'No Discount' THEN 1
        WHEN '1-5% Discount' THEN 2
        WHEN '6-10% Discount' THEN 3
        WHEN '11-15% Discount' THEN 4
        WHEN '16-20% Discount' THEN 5
        ELSE 6
    END;


-- ============================================================================
-- 5. PRODUCT-CATEGORY DISCOUNT EFFECTIVENESS
-- ============================================================================
-- Business Question: Which categories benefit most from discounting?

WITH category_discount_impact AS (
    SELECT 
        product_category,
        SUM(CASE WHEN discount = 0 THEN quantity ELSE 0 END) AS units_no_discount,
        SUM(CASE WHEN discount > 0 THEN quantity ELSE 0 END) AS units_with_discount,
        SUM(CASE WHEN discount = 0 THEN revenue ELSE 0 END) AS revenue_no_discount,
        SUM(CASE WHEN discount > 0 THEN revenue ELSE 0 END) AS revenue_with_discount,
        AVG(CASE WHEN discount = 0 THEN revenue ELSE NULL END) AS avg_order_no_discount,
        AVG(CASE WHEN discount > 0 THEN revenue ELSE NULL END) AS avg_order_with_discount
    FROM sales_data
    GROUP BY product_category
)
SELECT 
    product_category,
    units_no_discount,
    units_with_discount,
    ROUND(revenue_no_discount, 2) AS revenue_no_discount,
    ROUND(revenue_with_discount, 2) AS revenue_with_discount,
    ROUND(avg_order_no_discount, 2) AS avg_order_no_discount,
    ROUND(avg_order_with_discount, 2) AS avg_order_with_discount,
    -- Calculate discount effectiveness
    ROUND(
        ((units_with_discount - units_no_discount)::NUMERIC / 
        NULLIF(units_no_discount, 0)) * 100, 
        2
    ) AS volume_lift_pct,
    -- Discount ROI indicator
    CASE 
        WHEN revenue_with_discount > revenue_no_discount * 1.2 THEN 'High ROI'
        WHEN revenue_with_discount > revenue_no_discount THEN 'Positive ROI'
        ELSE 'Negative ROI'
    END AS discount_roi
FROM category_discount_impact
ORDER BY revenue_with_discount DESC;


-- ============================================================================
-- 6. KEY PERFORMANCE INDICATORS (KPIs) - OVERALL BUSINESS METRICS
-- ============================================================================
-- Business Question: What are our core business performance metrics?

WITH kpi_metrics AS (
    SELECT 
        -- Total revenue
        SUM(revenue) AS total_revenue,
        -- Total transactions
        COUNT(DISTINCT transaction_id) AS total_transactions,
        -- Unique customers
        COUNT(DISTINCT customer_id) AS unique_customers,
        -- Average order value
        AVG(revenue) AS avg_order_value,
        -- Total units sold
        SUM(quantity) AS total_units_sold,
        -- Discount metrics
        AVG(discount) AS avg_discount_rate,
        SUM(quantity * unit_price * discount) AS total_discounts_given
    FROM sales_data
),
customer_metrics AS (
    -- Repeat purchase rate
    SELECT 
        COUNT(DISTINCT CASE WHEN purchase_count > 1 THEN customer_id END)::NUMERIC / 
        COUNT(DISTINCT customer_id) AS repeat_purchase_rate
    FROM (
        SELECT customer_id, COUNT(DISTINCT transaction_id) AS purchase_count
        FROM sales_data
        GROUP BY customer_id
    ) sub
),
growth_metrics AS (
    -- Calculate revenue growth (comparing latest month vs previous)
    SELECT 
        (MAX(CASE WHEN month_rank = 1 THEN monthly_revenue END) - 
         MAX(CASE WHEN month_rank = 2 THEN monthly_revenue END)) /
        NULLIF(MAX(CASE WHEN month_rank = 2 THEN monthly_revenue END), 0) AS revenue_growth_rate
    FROM (
        SELECT 
            DATE_TRUNC('month', order_date) AS month,
            SUM(revenue) AS monthly_revenue,
            DENSE_RANK() OVER (ORDER BY DATE_TRUNC('month', order_date) DESC) AS month_rank
        FROM sales_data
        GROUP BY DATE_TRUNC('month', order_date)
    ) monthly
    WHERE month_rank <= 2
)
SELECT 
    '1. Total Revenue' AS kpi,
    CONCAT('$', TO_CHAR(ROUND(total_revenue, 2), 'FM999,999,999.00')) AS value
FROM kpi_metrics
UNION ALL
SELECT 
    '2. Revenue Growth %' AS kpi,
    CONCAT(TO_CHAR(ROUND(revenue_growth_rate * 100, 2), 'FM990.00'), '%') AS value
FROM growth_metrics
UNION ALL
SELECT 
    '3. Total Transactions' AS kpi,
    TO_CHAR(total_transactions, 'FM999,999') AS value
FROM kpi_metrics
UNION ALL
SELECT 
    '4. Unique Customers' AS kpi,
    TO_CHAR(unique_customers, 'FM999,999') AS value
FROM kpi_metrics
UNION ALL
SELECT 
    '5. Average Order Value (AOV)' AS kpi,
    CONCAT('$', TO_CHAR(ROUND(avg_order_value, 2), 'FM999,999.00')) AS value
FROM kpi_metrics
UNION ALL
SELECT 
    '6. Repeat Purchase Rate' AS kpi,
    CONCAT(TO_CHAR(ROUND(repeat_purchase_rate * 100, 2), 'FM990.00'), '%') AS value
FROM customer_metrics
UNION ALL
SELECT 
    '7. Average Discount Rate' AS kpi,
    CONCAT(TO_CHAR(ROUND(avg_discount_rate * 100, 2), 'FM990.00'), '%') AS value
FROM kpi_metrics
UNION ALL
SELECT 
    '8. Total Units Sold' AS kpi,
    TO_CHAR(total_units_sold, 'FM999,999') AS value
FROM kpi_metrics;


-- ============================================================================
-- 7. CONVERSION RATE BY CHANNEL (PROXY CALCULATION)
-- ============================================================================
-- Business Question: What is the conversion rate across sales channels?
-- Note: Assuming conversion = transactions / unique customer visits (proxy)

WITH channel_conversion AS (
    SELECT 
        sales_channel,
        COUNT(DISTINCT transaction_id) AS total_transactions,
        COUNT(DISTINCT customer_id) AS unique_customers,
        -- Proxy: Assume each customer visit resulted in conversion or no conversion
        -- Conversion rate = transactions / (transactions + estimated bounces)
        -- Using 1.5x customer count as proxy for total visits
        ROUND(
            (COUNT(DISTINCT transaction_id)::NUMERIC / 
            (COUNT(DISTINCT customer_id) * 1.5)) * 100, 
            2
        ) AS estimated_conversion_rate_pct,
        SUM(revenue) AS total_revenue,
        AVG(revenue) AS avg_order_value
    FROM sales_data
    GROUP BY sales_channel
)
SELECT 
    sales_channel,
    total_transactions,
    unique_customers,
    estimated_conversion_rate_pct,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(avg_order_value, 2) AS avg_order_value
FROM channel_conversion
ORDER BY total_revenue DESC;


-- ============================================================================
-- 8. MONTHLY KPI DASHBOARD (TIME SERIES)
-- ============================================================================
-- Business Question: How do KPIs trend over time?

WITH monthly_kpis AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        SUM(revenue) AS total_revenue,
        COUNT(DISTINCT transaction_id) AS total_transactions,
        COUNT(DISTINCT customer_id) AS unique_customers,
        AVG(revenue) AS avg_order_value,
        SUM(quantity) AS total_units_sold
    FROM sales_data
    GROUP BY DATE_TRUNC('month', order_date)
),
kpi_with_growth AS (
    SELECT 
        month,
        total_revenue,
        total_transactions,
        unique_customers,
        avg_order_value,
        total_units_sold,
        -- Calculate month-over-month growth
        ROUND(
            ((total_revenue - LAG(total_revenue) OVER (ORDER BY month)) / 
            NULLIF(LAG(total_revenue) OVER (ORDER BY month), 0)) * 100,
            2
        ) AS revenue_growth_pct,
        -- Calculate customer acquisition
        unique_customers - COALESCE(LAG(unique_customers) OVER (ORDER BY month), 0) AS new_customers_month
    FROM monthly_kpis
)
SELECT 
    TO_CHAR(month, 'YYYY-MM') AS month,
    ROUND(total_revenue, 2) AS total_revenue,
    COALESCE(revenue_growth_pct, 0) AS revenue_growth_pct,
    total_transactions,
    unique_customers,
    new_customers_month,
    ROUND(avg_order_value, 2) AS avg_order_value,
    total_units_sold,
    -- Year-over-year comparison flag
    CASE 
        WHEN revenue_growth_pct > 10 THEN 'Strong Growth'
        WHEN revenue_growth_pct > 0 THEN 'Positive Growth'
        WHEN revenue_growth_pct < -10 THEN 'Declining'
        ELSE 'Flat'
    END AS performance_status
FROM kpi_with_growth
ORDER BY month;
