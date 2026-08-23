# Data Catalog — Gold Layer

## Overview

The Gold Layer is the business-facing layer of the warehouse, structured as a **star schema**
(dimension + fact views) built on top of the cleaned `silver` layer. It is what BI tools and
analysts should query.

---

## `gold.dim_customers`

Dimension view holding one row per customer, with demographic attributes enriched from CRM and ERP sources.

| Column           | Data Type     | Description                                                                                   |
|------------------|---------------|-------------------------------------------------------------------------------------------------|
| `customer_key`   | `BIGINT`      | Surrogate key uniquely identifying each customer row in the dimension. Generated with `ROW_NUMBER()`. |
| `customer_id`    | `INT`         | Original customer identifier from the CRM source system (`crm_cust_info.cst_id`).              |
| `customer_number`| `VARCHAR(50)` | Alphanumeric customer code used for tracing/reference (`crm_cust_info.cst_key`).                |
| `first_name`     | `VARCHAR(50)` | Customer's first name, as recorded in the CRM system.                                           |
| `last_name`      | `VARCHAR(50)` | Customer's last name (family name), as recorded in the CRM system.                              |
| `country`        | `VARCHAR(50)` | Customer's country of residence (e.g. `Germany`, `United States`). `n/a` if unknown, sourced from ERP location data. |
| `marital_status` | `VARCHAR(50)` | Customer's marital status (`Single`, `Married`, `n/a`).                                         |
| `gender`         | `VARCHAR(50)` | Customer's gender (`Male`, `Female`, `n/a`). CRM value takes priority; falls back to ERP value when CRM is `n/a`. |
| `birthdate`      | `DATE`        | Customer's date of birth, sourced from ERP data. `NULL` if invalid/future-dated.                |
| `create_date`    | `DATE`        | Date the customer record was first created in the CRM source system.                            |

**Grain:** one row per customer.
**Source tables:** `silver.crm_cust_info` (master), `silver.erp_cust_az12`, `silver.erp_loc_a101`.

---

## `gold.dim_products`

Dimension view holding one row per **currently active** product (historical/discontinued product versions are excluded).

| Column          | Data Type     | Description                                                                                     |
|-----------------|---------------|---------------------------------------------------------------------------------------------------|
| `product_key`   | `BIGINT`      | Surrogate key uniquely identifying each product row in the dimension. Generated with `ROW_NUMBER()`, ordered by start date then product key. |
| `product_id`    | `INT`         | Original product identifier from the CRM source system (`crm_prd_info.prd_id`).                  |
| `product_number`| `VARCHAR(50)` | Alphanumeric product code/SKU (`crm_prd_info.prd_key`).                                           |
| `product_name`  | `VARCHAR(50)` | Descriptive name of the product, including key attributes (type, color, size).                   |
| `category_id`   | `VARCHAR(50)` | Identifier linking the product to its high-level category, derived from the product key prefix.   |
| `category`      | `VARCHAR(50)` | High-level product category (e.g. `Bikes`, `Components`), sourced from ERP category data.         |
| `subcategory`   | `VARCHAR(50)` | More detailed product classification within the category (e.g. `Road Frames`).                   |
| `maintenance`   | `VARCHAR(50)` | Indicates whether the product requires maintenance (`Yes`/`No`).                                  |
| `cost`          | `INT`         | Cost/base price of the product, in whole currency units.                                          |
| `product_line`  | `VARCHAR(50)` | Product line/family the item belongs to (`Mountain`, `Road`, `Other Sales`, `Touring`, `n/a`).    |
| `start_date`    | `DATE`        | Date the product became available/effective.                                                      |

**Grain:** one row per active product (rows with a `prd_end_dt` are excluded).
**Source tables:** `silver.crm_prd_info` (master), `silver.erp_px_cat_g1v2`.

---

## `gold.fact_sales`

Fact view holding one row per sales order line item, linking to the customer and product dimensions.

| Column          | Data Type      | Description                                                                                       |
|-----------------|----------------|-------------------------------------------------------------------------------------------------------|
| `order_number`  | `NVARCHAR(50)` | Unique identifier for the sales order (e.g. `SO43697`).                                           |
| `product_key`   | `BIGINT`       | Foreign key to `gold.dim_products.product_key`, identifying the product sold.                     |
| `customer_key`  | `BIGINT`       | Foreign key to `gold.dim_customers.customer_key`, identifying the customer who placed the order.   |
| `order_date`    | `DATE`         | Date the order was placed.                                                                         |
| `shipping_date` | `DATE`         | Date the order was shipped.                                                                         |
| `due_date`      | `DATE`         | Date the order payment/delivery was due.                                                           |
| `sales_amount`  | `INT`          | Total sales value for the line item, in whole currency units (equal to `quantity * price`).        |
| `quantity`      | `INT`          | Number of units sold in the line item.                                                             |
| `price`         | `INT`          | Unit price of the product at the time of sale, in whole currency units.                            |

**Grain:** one row per sales order line item.
**Source tables:** `silver.crm_sales_details` (master), `gold.dim_products`, `gold.dim_customers`.
