
  
  create view "warehouse"."main_bronze"."bronze_products__dbt_tmp" as (
    

-- Bronze layer: exposes product snapshots exactly as extracted from ERP.
SELECT *
FROM read_parquet('s3://datalake/bronze/erp/products/*.parquet')
  );
