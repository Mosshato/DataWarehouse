/*
=============================================================
Quality Checks: Silver Layer
=============================================================
Script Purpose:
    Sanity/health checks for the silver tables that have already been
    transformed (crm_cust_info, crm_prd_info, crm_sales_details).
    Every query below should return NO ROWS when the data is healthy.
    A query that DOES return rows points at a problem to investigate.
=============================================================
*/

-- ============================================================
-- silver.crm_cust_info
-- ============================================================

-- Duplicate / NULL primary keys (should be none after the dedupe step)
SELECT cst_id, COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Unwanted leading/trailing spaces in name fields
SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- Values outside the normalized set (only Single/Married/n/a and Female/Male/n/a expected)
SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info
WHERE cst_marital_status NOT IN ('Single', 'Married', 'n/a');

SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info
WHERE cst_gndr NOT IN ('Female', 'Male', 'n/a');

-- ============================================================
-- silver.crm_prd_info
-- ============================================================

-- Duplicate / NULL primary keys
SELECT prd_id, COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Unwanted spaces in product name
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Negative or NULL cost (ISNULL(...,0) should have removed NULLs; negatives are still bad)
SELECT prd_id, prd_cost
FROM silver.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost < 0;

-- Values outside the normalized product line set
SELECT DISTINCT prd_line
FROM silver.crm_prd_info
WHERE prd_line NOT IN ('Mountain', 'Road', 'Other Sales', 'Touring', 'n/a');

-- prd_end_dt earlier than prd_start_dt (should never happen with the LEAD/DATEADD logic)
SELECT prd_id, prd_key, prd_start_dt, prd_end_dt
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- ============================================================
-- silver.crm_sales_details
-- ============================================================

-- Invalid date order: order date should never be after ship/due date
SELECT sls_ord_num, sls_order_dt, sls_ship_dt, sls_due_dt
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- sales/quantity/price consistency: sales must equal quantity * price, all must be positive/non-null
SELECT sls_ord_num, sls_sales, sls_quantity, sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0;

-- Orphan sales rows: prd_key / cust_id not found in their respective silver dimension tables
SELECT sd.sls_prd_key
FROM silver.crm_sales_details sd
WHERE NOT EXISTS (
    SELECT 1 FROM silver.crm_prd_info p WHERE p.prd_key = sd.sls_prd_key
);

SELECT sd.sls_cust_id
FROM silver.crm_sales_details sd
WHERE NOT EXISTS (
    SELECT 1 FROM silver.crm_cust_info c WHERE c.cst_id = sd.sls_cust_id
);
