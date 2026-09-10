-- =============================================================
-- OVERALL ANALYSIS
-- =============================================================

USE DataWarehouseAnalytics;


-- =============================================================
-- 1. CHANGE OVER TIME ANALYSIS
-- =============================================================

SELECT
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity

FROM fact_sales

WHERE order_date IS NOT NULL

GROUP BY
    YEAR(order_date),
    MONTH(order_date)

ORDER BY
    YEAR(order_date),
    MONTH(order_date);


-- =============================================================
-- 2. CUMULATIVE ANALYSIS
-- =============================================================

SELECT
    order_month,
    total_sales,

    SUM(total_sales) OVER (
        ORDER BY order_month
    ) AS running_total_sales

FROM
(
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS order_month,
        SUM(sales_amount) AS total_sales

    FROM fact_sales

    WHERE order_date IS NOT NULL

    GROUP BY DATE_FORMAT(order_date, '%Y-%m')

) AS t;


-- =============================================================
-- 3. PERFORMANCE ANALYSIS
-- Analyze yearly product performance by comparing:
-- - Current year sales with average product sales
-- - Current year sales with previous year sales
-- =============================================================

WITH yearly_product_sales AS (

    SELECT
        YEAR(f.order_date) AS order_year,
        p.product_name,
        SUM(f.sales_amount) AS current_sales

    FROM fact_sales f

    LEFT JOIN dim_products p
        ON f.product_key = p.product_key

    WHERE f.order_date IS NOT NULL

    GROUP BY
        YEAR(f.order_date),
        p.product_name
)

SELECT
    order_year,
    product_name,
    current_sales,

    AVG(current_sales) OVER (
        PARTITION BY product_name
    ) AS avg_sales,

    current_sales -
    AVG(current_sales) OVER (
        PARTITION BY product_name
    ) AS diff_avg,

    CASE
        WHEN current_sales -
             AVG(current_sales) OVER (
                 PARTITION BY product_name
             ) > 0
            THEN 'Above Avg'

        WHEN current_sales -
             AVG(current_sales) OVER (
                 PARTITION BY product_name
             ) < 0
            THEN 'Below Avg'

        ELSE 'Avg'
    END AS avg_change,

    LAG(current_sales) OVER (
        PARTITION BY product_name
        ORDER BY order_year
    ) AS py_sales,

    current_sales -
    LAG(current_sales) OVER (
        PARTITION BY product_name
        ORDER BY order_year
    ) AS diff_py,

    CASE
        WHEN current_sales -
             LAG(current_sales) OVER (
                 PARTITION BY product_name
                 ORDER BY order_year
             ) > 0
            THEN 'Increase'

        WHEN current_sales -
             LAG(current_sales) OVER (
                 PARTITION BY product_name
                 ORDER BY order_year
             ) < 0
            THEN 'Decrease'

        ELSE 'No Change'
    END AS py_change

FROM yearly_product_sales

ORDER BY
    product_name,
    order_year;


-- =============================================================
-- 4. CATEGORY CONTRIBUTION TO OVERALL SALES
-- =============================================================

WITH category_sales AS (

    SELECT
        p.category,
        SUM(f.sales_amount) AS total_sales

    FROM fact_sales f

    LEFT JOIN dim_products p
        ON p.product_key = f.product_key

    GROUP BY p.category
)

SELECT
    category,
    total_sales,

    SUM(total_sales) OVER () AS overall_sales,

    CONCAT(
        ROUND(
            (
                CAST(total_sales AS DECIMAL(10,2))
                / SUM(total_sales) OVER ()
            ) * 100,
            2
        ),
        '%'
    ) AS percentage_of_total

FROM category_sales

ORDER BY total_sales DESC;


-- =============================================================
-- 5. PRODUCT COST SEGMENTATION
-- Count how many products fall into each cost range
-- =============================================================

WITH product_segments AS (

    SELECT
        product_key,
        product_name,
        cost,

        CASE
            WHEN cost < 100
                THEN 'Below 100'

            WHEN cost BETWEEN 100 AND 500
                THEN '100-500'

            WHEN cost BETWEEN 500 AND 1000
                THEN '500-1000'

            ELSE 'Above 1000'
        END AS cost_range

    FROM dim_products
)

SELECT
    cost_range,
    COUNT(product_key) AS total_products

FROM product_segments

GROUP BY cost_range;


-- =============================================================
-- 6. CUSTOMER SEGMENTATION
--
-- VIP:
--     Lifespan >= 12 months AND spending > 5000
--
-- Regular:
--     Lifespan >= 12 months AND spending <= 5000
--
-- New:
--     Lifespan < 12 months
--
-- Counts the total customers in each segment.
-- =============================================================

WITH customer_spending AS (

    SELECT
        c.customer_key,

        SUM(f.sales_amount) AS total_spending,

        MIN(f.order_date) AS first_order,

        MAX(f.order_date) AS last_order,

        TIMESTAMPDIFF(
            MONTH,
            DATE_FORMAT(
                MIN(f.order_date),
                '%Y-%m-01'
            ),
            DATE_FORMAT(
                MAX(f.order_date),
                '%Y-%m-01'
            )
        ) AS lifespan

    FROM fact_sales f

    LEFT JOIN dim_customers c
        ON f.customer_key = c.customer_key

    GROUP BY c.customer_key
)

SELECT
    customer_segment,
    COUNT(customer_key) AS total_customers

FROM
(
    SELECT
        customer_key,

        CASE
            WHEN lifespan >= 12
                 AND total_spending > 5000
                THEN 'VIP'

            WHEN lifespan >= 12
                 AND total_spending <= 5000
                THEN 'Regular'

            ELSE 'New'
        END AS customer_segment

    FROM customer_spending
) AS t

GROUP BY customer_segment;
