/*
=============================================================
Quality Checks: Gold Layer
=============================================================
Script Purpose:
    Sanity/health checks for the gold views (dim_customers, dim_products,
    fact_sales), validating that the star schema is correctly built on
    top of the silver layer (surrogate key uniqueness and referential
    integrity between the fact and its dimensions).
    Every query below should return NO ROWS when the data is healthy.
    A query that DOES return rows points at a problem to investigate.
=============================================================
*/

-- ============================================================
-- gold.dim_customers
-- ============================================================

-- Duplicate / NULL surrogate keys
SELECT customer_key, COUNT(*)
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1 OR customer_key IS NULL;

-- Duplicate customers after the CRM/ERP join (one row expected per customer_id)
SELECT customer_id, COUNT(*)
FROM gold.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Values outside the normalized gender/marital status set
SELECT DISTINCT gender
FROM gold.dim_customers
WHERE gender NOT IN ('Male', 'Female', 'n/a');

SELECT DISTINCT marital_status
FROM gold.dim_customers
WHERE marital_status NOT IN ('Single', 'Married', 'n/a');

-- ============================================================
-- gold.dim_products
-- ============================================================

-- Duplicate / NULL surrogate keys
SELECT product_key, COUNT(*)
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1 OR product_key IS NULL;

-- Duplicate product numbers (should be unique among active products)
SELECT product_number, COUNT(*)
FROM gold.dim_products
GROUP BY product_number
HAVING COUNT(*) > 1;

-- Negative cost
SELECT product_id, cost
FROM gold.dim_products
WHERE cost < 0;

-- ============================================================
-- gold.fact_sales
-- ============================================================

-- Orphan facts: product_key / customer_key not found in their dimension
-- (would indicate a broken join in the fact view)
SELECT f.order_number, f.product_key
FROM gold.fact_sales f
WHERE f.product_key IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM gold.dim_products p WHERE p.product_key = f.product_key
  );

SELECT f.order_number, f.customer_key
FROM gold.fact_sales f
WHERE f.customer_key IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM gold.dim_customers c WHERE c.customer_key = f.customer_key
  );

-- Unmatched foreign keys: sales rows that failed to join to a dimension at all
SELECT order_number
FROM gold.fact_sales
WHERE product_key IS NULL OR customer_key IS NULL;

-- Invalid date order: order date should never be after shipping/due date
SELECT order_number, order_date, shipping_date, due_date
FROM gold.fact_sales
WHERE order_date > shipping_date OR order_date > due_date;

-- sales/quantity/price consistency: sales must equal quantity * price, all positive/non-null
SELECT order_number, sales_amount, quantity, price
FROM gold.fact_sales
WHERE sales_amount != quantity * price
   OR sales_amount IS NULL OR quantity IS NULL OR price IS NULL
   OR sales_amount <= 0 OR quantity <= 0 OR price <= 0;
