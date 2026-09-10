/*
================================================================================
Database Setup
================================================================================

Purpose:
    - Creates the DataWarehouseAnalytics database
    - Creates the customer, product, and sales tables
    - CSV data is imported separately using MySQL Workbench's
      Table Data Import Wizard.

Tables:
    1. dim_customers
    2. dim_products
    3. fact_sales
================================================================================
*/

-- Create database if it does not already exist
CREATE DATABASE IF NOT EXISTS DataWarehouseAnalytics;

-- Use database
USE DataWarehouseAnalytics;


-------------------------------------------------------------
-- Create Customer Dimension Table
-------------------------------------------------------------

CREATE TABLE IF NOT EXISTS dim_customers (
    customer_key INT,
    customer_id INT,
    customer_number VARCHAR(50),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    country VARCHAR(50),
    marital_status VARCHAR(50),
    gender VARCHAR(50),
    birthdate DATE,
    create_date DATE
);


-------------------------------------------------------------
-- Create Product Dimension Table
-------------------------------------------------------------

CREATE TABLE IF NOT EXISTS dim_products (
    product_key INT,
    product_id INT,
    product_number VARCHAR(50),
    product_name VARCHAR(50),
    category_id VARCHAR(50),
    category VARCHAR(50),
    subcategory VARCHAR(50),
    maintenance VARCHAR(50),
    cost INT,
    product_line VARCHAR(50),
    start_date DATE
);


-------------------------------------------------------------
-- Create Sales Fact Table
-------------------------------------------------------------

CREATE TABLE IF NOT EXISTS fact_sales (
    order_number VARCHAR(50),
    product_key INT,
    customer_key INT,
    order_date DATE,
    shipping_date DATE,
    due_date DATE,
    sales_amount INT,
    quantity TINYINT,
    price INT
);


-------------------------------------------------------------
-- Data Import
-------------------------------------------------------------

-- Import the following CSV files using:
-- MySQL Workbench → Table Data Import Wizard
--
-- 1. datasets/dim_customers.csv → dim_customers
-- 2. datasets/dim_products.csv   → dim_products
-- 3. datasets/fact_sales.csv     → fact_sales
