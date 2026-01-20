-- ============================================================================
-- SALES PERFORMANCE DASHBOARD - CUSTOMER ANALYSIS QUERIES
-- ============================================================================
-- Purpose: Customer segmentation, RFM analysis, CLV, and retention metrics
-- Author: Data Analytics Portfolio Project
-- Date: January 2026
-- ============================================================================

-- ============================================================================
-- 1. RFM ANALYSIS (Recency, Frequency, Monetary)
-- ============================================================================
-- Business Question: How do we segment customers based on purchasing behavior?
-- Key Segments: Champions, Loyal, At Risk, Lost, New

WITH customer_rfm AS (
    SELECT 
        customer_id,
        -- Recency: Days since last purchase
        CURRENT_DATE - MAX(order_date)::DATE AS recency_days,
        -- Frequency: Number of purchases
        COUNT(DISTINCT transaction_id) AS frequency,
        -- Monetary: Total revenue contributed
        SUM(revenue) AS monetary_value,
        -- Additional metrics
        MIN(order_date) AS first_purchase_date,
        MAX(order_date) AS last_purchase_date
    FROM sales_data
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT 
        customer_id,
        recency_days,
        frequency,
        monetary_value,
        first_purchase_date,
        last_purchase_date,
        -- Calculate RFM scores (1-5 scale, 5 being best)
        NTILE(5) OVER (ORDER BY recency_days ASC) AS recency_score,
        NTILE(5) OVER (ORDER BY frequency DESC) AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary_value DESC) AS monetary_score
    FROM customer_rfm
),
rfm_segments AS (
    SELECT 
        customer_id,
        recency_days,
        frequency,
        ROUND(monetary_value, 2) AS monetary_value,
        recency_score,
        frequency_score,
        monetary_score,
        -- Create combined RFM score
        (recency_score + frequency_score + monetary_score) AS rfm_total_score,
        -- Assign customer segments
        CASE 
            WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 
                THEN 'Champions'
            WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 
                THEN 'Loyal Customers'
            WHEN recency_score >= 4 AND frequency_score <= 2 AND monetary_score <= 2 
                THEN 'New Customers'
            WHEN recency_score <= 2 AND frequency_score >= 3 AND monetary_score >= 3 
                THEN 'At Risk'
            WHEN recency_score <= 2 AND frequency_score <= 2 
                THEN 'Lost Customers'
            WHEN recency_score >= 3 AND frequency_score <= 2 
                THEN 'Promising'
            WHEN monetary_score >= 4 
                THEN 'Big Spenders'
            ELSE 'Needs Attention'
        END AS customer_segment,
        first_purchase_date,
        last_purchase_date
    FROM rfm_scores
)
SELECT 
    customer_segment,
    COUNT(customer_id) AS customer_count,
    ROUND(AVG(recency_days), 1) AS avg_recency_days,
    ROUND(AVG(frequency), 1) AS avg_frequency,
    ROUND(AVG(monetary_value), 2) AS avg_monetary_value,
    ROUND(SUM(monetary_value), 2) AS total_segment_revenue,
    ROUND(
        (SUM(monetary_value) / (SELECT SUM(monetary_value) FROM rfm_segments)) * 100, 
        2
    ) AS revenue_share_pct
FROM rfm_segments
GROUP BY customer_segment
ORDER BY total_segment_revenue DESC;


-- ============================================================================
-- 2. CUSTOMER LIFETIME VALUE (CLV) CALCULATION
-- ============================================================================
-- Business Question: What is the predicted lifetime value of our customers?
-- Formula: CLV = (Average Order Value × Purchase Frequency × Customer Lifespan)

WITH customer_metrics AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT transaction_id) AS total_purchases,
        SUM(revenue) AS total_spent,
        AVG(revenue) AS avg_order_value,
        MIN(order_date) AS first_purchase,
        MAX(order_date) AS last_purchase,
        -- Calculate customer lifespan in months
        GREATEST(
            EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date))), 
            1
        ) AS lifespan_months
    FROM sales_data
    GROUP BY customer_id
),
clv_calculation AS (
    SELECT 
        customer_id,
        total_purchases,
        total_spent,
        avg_order_value,
        lifespan_months,
        -- Purchase frequency (purchases per month)
        ROUND(total_purchases::NUMERIC / NULLIF(lifespan_months, 0), 2) AS purchase_frequency_monthly,
        -- Customer Lifetime Value (historical)
        ROUND(total_spent, 2) AS historical_clv,
        -- Predicted CLV (assuming 24-month lifetime)
        ROUND(
            avg_order_value * 
            (total_purchases::NUMERIC / NULLIF(lifespan_months, 0)) * 
            24, 
            2
        ) AS predicted_clv_24m,
        first_purchase,
        last_purchase
    FROM customer_metrics
)
SELECT 
    -- CLV segments
    CASE 
        WHEN predicted_clv_24m >= 10000 THEN 'Very High Value'
        WHEN predicted_clv_24m >= 5000 THEN 'High Value'
        WHEN predicted_clv_24m >= 2000 THEN 'Medium Value'
        WHEN predicted_clv_24m >= 500 THEN 'Low Value'
        ELSE 'Very Low Value'
    END AS clv_segment,
    COUNT(customer_id) AS customer_count,
    ROUND(AVG(total_purchases), 1) AS avg_purchases,
    ROUND(AVG(avg_order_value), 2) AS avg_order_value,
    ROUND(AVG(purchase_frequency_monthly), 2) AS avg_monthly_frequency,
    ROUND(AVG(historical_clv), 2) AS avg_historical_clv,
    ROUND(AVG(predicted_clv_24m), 2) AS avg_predicted_clv_24m,
    ROUND(SUM(predicted_clv_24m), 2) AS total_predicted_clv_24m
FROM clv_calculation
GROUP BY clv_segment
ORDER BY avg_predicted_clv_24m DESC;


-- ============================================================================
-- 3. TOP 100 CUSTOMERS BY LIFETIME VALUE
-- ============================================================================
-- Business Question: Who are our most valuable customers?

WITH customer_value AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT transaction_id) AS total_transactions,
        SUM(revenue) AS total_revenue,
        AVG(revenue) AS avg_order_value,
        MIN(order_date) AS first_purchase,
        MAX(order_date) AS last_purchase,
        CURRENT_DATE - MAX(order_date)::DATE AS days_since_last_purchase,
        -- Calculate average days between purchases
        CASE 
            WHEN COUNT(DISTINCT transaction_id) > 1 
            THEN EXTRACT(DAY FROM AGE(MAX(order_date), MIN(order_date))) / 
                 (COUNT(DISTINCT transaction_id) - 1)
            ELSE NULL
        END AS avg_days_between_purchases
    FROM sales_data
    GROUP BY customer_id
)
SELECT 
    customer_id,
    total_transactions,
    ROUND(total_revenue, 2) AS lifetime_value,
    ROUND(avg_order_value, 2) AS avg_order_value,
    first_purchase,
    last_purchase,
    days_since_last_purchase,
    ROUND(avg_days_between_purchases, 1) AS avg_days_between_purchases,
    -- Assign VIP status
    CASE 
        WHEN total_revenue >= 20000 THEN 'VIP Tier 1'
        WHEN total_revenue >= 10000 THEN 'VIP Tier 2'
        WHEN total_revenue >= 5000 THEN 'VIP Tier 3'
        ELSE 'Standard'
    END AS customer_tier,
    -- Calculate retention score
    CASE 
        WHEN days_since_last_purchase <= 30 THEN 'Active'
        WHEN days_since_last_purchase <= 90 THEN 'Moderate'
        WHEN days_since_last_purchase <= 180 THEN 'At Risk'
        ELSE 'Churned'
    END AS retention_status
FROM customer_value
ORDER BY total_revenue DESC
LIMIT 100;


-- ============================================================================
-- 4. NEW VS RETURNING CUSTOMER ANALYSIS
-- ============================================================================
-- Business Question: How do new vs returning customers compare in performance?

WITH customer_type_metrics AS (
    SELECT 
        customer_type,
        COUNT(DISTINCT transaction_id) AS total_transactions,
        COUNT(DISTINCT customer_id) AS unique_customers,
        SUM(revenue) AS total_revenue,
        AVG(revenue) AS avg_order_value,
        SUM(quantity) AS total_units,
        AVG(discount) AS avg_discount
    FROM sales_data
    GROUP BY customer_type
)
SELECT 
    customer_type,
    total_transactions,
    unique_customers,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(avg_order_value, 2) AS avg_order_value,
    total_units,
    ROUND(avg_discount * 100, 2) AS avg_discount_pct,
    -- Calculate revenue contribution
    ROUND(
        (total_revenue / SUM(total_revenue) OVER ()) * 100, 
        2
    ) AS revenue_contribution_pct,
    -- Calculate transactions per customer
    ROUND(total_transactions::NUMERIC / unique_customers, 2) AS transactions_per_customer
FROM customer_type_metrics
ORDER BY total_revenue DESC;


-- ============================================================================
-- 5. CUSTOMER PURCHASE FREQUENCY DISTRIBUTION
-- ============================================================================
-- Business Question: What is the distribution of purchase frequency?

WITH purchase_frequency AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT transaction_id) AS num_purchases,
        SUM(revenue) AS total_spent
    FROM sales_data
    GROUP BY customer_id
),
frequency_buckets AS (
    SELECT 
        CASE 
            WHEN num_purchases = 1 THEN '1 Purchase (One-time)'
            WHEN num_purchases BETWEEN 2 AND 3 THEN '2-3 Purchases'
            WHEN num_purchases BETWEEN 4 AND 6 THEN '4-6 Purchases'
            WHEN num_purchases BETWEEN 7 AND 10 THEN '7-10 Purchases'
            WHEN num_purchases BETWEEN 11 AND 20 THEN '11-20 Purchases'
            ELSE '20+ Purchases (Power Users)'
        END AS frequency_bucket,
        COUNT(customer_id) AS customer_count,
        SUM(total_spent) AS total_revenue
    FROM purchase_frequency
    GROUP BY 
        CASE 
            WHEN num_purchases = 1 THEN '1 Purchase (One-time)'
            WHEN num_purchases BETWEEN 2 AND 3 THEN '2-3 Purchases'
            WHEN num_purchases BETWEEN 4 AND 6 THEN '4-6 Purchases'
            WHEN num_purchases BETWEEN 7 AND 10 THEN '7-10 Purchases'
            WHEN num_purchases BETWEEN 11 AND 20 THEN '11-20 Purchases'
            ELSE '20+ Purchases (Power Users)'
        END
)
SELECT 
    frequency_bucket,
    customer_count,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(total_revenue / customer_count, 2) AS avg_revenue_per_customer,
    ROUND(
        (customer_count::NUMERIC / SUM(customer_count) OVER ()) * 100, 
        2
    ) AS customer_pct,
    ROUND(
        (total_revenue / SUM(total_revenue) OVER ()) * 100, 
        2
    ) AS revenue_pct
FROM frequency_buckets
ORDER BY 
    CASE frequency_bucket
        WHEN '1 Purchase (One-time)' THEN 1
        WHEN '2-3 Purchases' THEN 2
        WHEN '4-6 Purchases' THEN 3
        WHEN '7-10 Purchases' THEN 4
        WHEN '11-20 Purchases' THEN 5
        ELSE 6
    END;


-- ============================================================================
-- 6. CUSTOMER RETENTION COHORT ANALYSIS
-- ============================================================================
-- Business Question: What is our customer retention rate by cohort?

WITH customer_cohorts AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM sales_data
    GROUP BY customer_id
),
cohort_activity AS (
    SELECT 
        c.cohort_month,
        DATE_TRUNC('month', s.order_date) AS activity_month,
        COUNT(DISTINCT s.customer_id) AS active_customers
    FROM sales_data s
    JOIN customer_cohorts c ON s.customer_id = c.customer_id
    GROUP BY c.cohort_month, DATE_TRUNC('month', s.order_date)
),
cohort_size AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
)
SELECT 
    TO_CHAR(ca.cohort_month, 'YYYY-MM') AS cohort_month,
    cs.cohort_size,
    TO_CHAR(ca.activity_month, 'YYYY-MM') AS activity_month,
    ca.active_customers,
    -- Calculate retention rate
    ROUND(
        (ca.active_customers::NUMERIC / cs.cohort_size) * 100, 
        2
    ) AS retention_rate_pct,
    -- Calculate months since cohort start
    EXTRACT(MONTH FROM AGE(ca.activity_month, ca.cohort_month)) AS month_number
FROM cohort_activity ca
JOIN cohort_size cs ON ca.cohort_month = cs.cohort_month
WHERE ca.cohort_month >= '2023-01-01'
ORDER BY ca.cohort_month, ca.activity_month
LIMIT 200;


-- ============================================================================
-- 7. CUSTOMER CHURN RISK ANALYSIS
-- ============================================================================
-- Business Question: Which customers are at risk of churning?

WITH customer_last_purchase AS (
    SELECT 
        customer_id,
        MAX(order_date) AS last_purchase_date,
        COUNT(DISTINCT transaction_id) AS total_purchases,
        SUM(revenue) AS lifetime_value,
        AVG(revenue) AS avg_order_value
    FROM sales_data
    GROUP BY customer_id
),
churn_risk AS (
    SELECT 
        customer_id,
        last_purchase_date,
        CURRENT_DATE - last_purchase_date::DATE AS days_since_last_purchase,
        total_purchases,
        lifetime_value,
        avg_order_value,
        -- Assign churn risk level
        CASE 
            WHEN CURRENT_DATE - last_purchase_date::DATE > 180 THEN 'High Risk'
            WHEN CURRENT_DATE - last_purchase_date::DATE > 90 THEN 'Medium Risk'
            WHEN CURRENT_DATE - last_purchase_date::DATE > 60 THEN 'Low Risk'
            ELSE 'Active'
        END AS churn_risk_level,
        -- Assign value category
        CASE 
            WHEN lifetime_value >= 5000 THEN 'High Value'
            WHEN lifetime_value >= 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_category
    FROM customer_last_purchase
)
SELECT 
    churn_risk_level,
    value_category,
    COUNT(customer_id) AS customer_count,
    ROUND(AVG(days_since_last_purchase), 1) AS avg_days_inactive,
    ROUND(AVG(total_purchases), 1) AS avg_total_purchases,
    ROUND(SUM(lifetime_value), 2) AS total_at_risk_revenue,
    ROUND(AVG(lifetime_value), 2) AS avg_lifetime_value
FROM churn_risk
GROUP BY churn_risk_level, value_category
ORDER BY 
    CASE churn_risk_level
        WHEN 'High Risk' THEN 1
        WHEN 'Medium Risk' THEN 2
        WHEN 'Low Risk' THEN 3
        ELSE 4
    END,
    total_at_risk_revenue DESC;
