/*
=============================================================
Create Bronze Tables
=============================================================
Script Purpose:
    This script creates tables in the 'bronze' schema, dropping existing tables
    if they already exist.
	  Run this script to re-define the DDL structure of 'bronze' Tables
=============================================================
*/

IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
GO

CREATE TABLE bronze.crm_cust_info (
    cst_id              INT,
    cst_key             VARCHAR(50),
    cst_firstname       VARCHAR(50),
    cst_lastname        VARCHAR(50),
    cst_material_status VARCHAR(50),
    cst_gndr            VARCHAR(50),
    cst_create_date     DATE
);
GO

IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
GO

CREATE TABLE bronze.crm_prd_info (
    prd_id       INT,
    prd_key      VARCHAR(50),
    prd_nm       VARCHAR(50),
    prd_cost     INT,
    prd_line     VARCHAR(50),
    prd_start_dt DATE,
    prd_end_dt   DATE
);
GO

IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
GO

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num  VARCHAR(50),
    sls_prd_key  VARCHAR(50),
    sls_cust_id  INT,
    sls_order_dt INT,
    sls_ship_dt  INT,
    sls_due_dt   INT,
    sls_sales    INT,
    sls_quantity INT,
    sls_price    INT
);
GO

IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
GO

CREATE TABLE bronze.erp_cust_az12 (
    CID   VARCHAR(50),
    BDATE DATE,
    GEN   VARCHAR(50)
);
GO

IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
GO

CREATE TABLE bronze.erp_loc_a101 (
    CID   VARCHAR(50),
    CNTRY VARCHAR(50)
);
GO

IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
GO

CREATE TABLE bronze.erp_px_cat_g1v2 (
    ID          VARCHAR(50),
    CAT         VARCHAR(50),
    SUBCAT      VARCHAR(50),
    MAINTENANCE VARCHAR(50)
);
GO

/*
=============================================================
Notes on source CSV format (verified against /datasets before loading)
=============================================================
  - FIELDTERMINATOR = ','   for all 6 source files.
  - ROWTERMINATOR   = CRLF (0x0d0a) for all 6 source files (Windows line endings).
  - No quoted/escaped fields, no embedded delimiters in any source file.
  - Date columns (cst_create_date, prd_start_dt/prd_end_dt, BDATE) are all
    ISO format YYYY-MM-DD, safe to load directly into DATE columns.
  - cust_info.csv and CUST_AZ12.csv each have a malformed trailing row
    (garbage cst_key/CID, all other fields empty, no CRLF at EOF) which
    BULK INSERT silently drops -> loaded row count is 1 less than file
    line count for bronze.crm_cust_info and bronze.erp_cust_az12. This is
    expected/known, not a load bug; source files are left untouched since
    bronze is meant to hold raw data as-is (dirty rows get handled in silver).
  - erp_cust_az12.BDATE also contains at least one clearly invalid value
    (e.g. 9999-11-20) — again expected raw/dirty data for the bronze layer.
=============================================================
*/
