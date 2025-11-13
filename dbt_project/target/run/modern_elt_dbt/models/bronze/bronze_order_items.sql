
  
  create view "warehouse"."main_bronze"."bronze_order_items__dbt_tmp" as (
    

-- Bronze layer: ERP order line items.
SELECT *
FROM read_parquet('s3://datalake/bronze/erp/order_items/*.parquet')
  );
