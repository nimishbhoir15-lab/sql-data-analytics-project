/*
================================================================================
Product Report
================================================================================

Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
        - total orders
        - total sales
        - total quantity sold
        - total customers (unique)
        - lifespan (in months)

    4. Calculates valuable KPIs:
        - recency (months since last sale)
        - average order revenue (AOR)
        - average monthly revenue
================================================================================
*/

WITH base_query AS (

    /*
    ============================================================================
    1) Base Query
       Retrieves required columns from fact_sales and dim_products
    ============================================================================
    */

    SELECT
        f.order_number,
        f.order_date,
        f.customer_key,
        f.sales_amount,
        f.quantity,

        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost

    FROM fact_sales f

    LEFT JOIN dim_products p
        ON f.product_key = p.product_key

    WHERE f.order_date IS NOT NULL
),

product_aggregations AS (

    /*
    ============================================================================
    2) Product Aggregations
       Calculates product-level metrics
    ============================================================================
    */

    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,

        -- Product lifespan in months
        TIMESTAMPDIFF(
            MONTH,
            MIN(order_date),
            MAX(order_date)
        ) AS lifespan,

        -- Most recent sale
        MAX(order_date) AS last_sale_date,

        -- Total number of unique orders
        COUNT(DISTINCT order_number) AS total_orders,

        -- Total number of unique customers
        COUNT(DISTINCT customer_key) AS total_customers,

        -- Total revenue generated
        SUM(sales_amount) AS total_sales,

        -- Total quantity sold
        SUM(quantity) AS total_quantity,

        -- Average selling price
        ROUND(
            AVG(
                sales_amount / NULLIF(quantity, 0)
            ),
            1
        ) AS avg_selling_price

    FROM base_query

    GROUP BY
        product_key,
        product_name,
        category,
        subcategory,
        cost
)

-- ============================================================================
-- 3) Final Product Report
-- ============================================================================

SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,

    last_sale_date,

    -- Recency = months since the product was last sold
    TIMESTAMPDIFF(
        MONTH,
        last_sale_date,
        CURDATE()
    ) AS recency_in_months,

    -- Product segmentation based on total sales
    CASE
        WHEN total_sales > 50000 THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END AS product_segment,

    lifespan,

    total_orders,
    total_sales,
    total_quantity,
    total_customers,

    avg_selling_price,

    -- Average Order Revenue (AOR)
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_revenue,

    -- Average Monthly Revenue
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_revenue

FROM product_aggregations;
