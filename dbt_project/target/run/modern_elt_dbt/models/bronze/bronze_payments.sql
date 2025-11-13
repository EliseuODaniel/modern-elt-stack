
  
  create view "warehouse"."main_bronze"."bronze_payments__dbt_tmp" as (
    

-- Bronze layer: raw payment ledger from the ERP.
SELECT *
FROM read_parquet('s3://datalake/bronze/erp/payments/*.parquet')
  );
