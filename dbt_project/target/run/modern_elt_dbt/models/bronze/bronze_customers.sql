
  
  create view "warehouse"."main_bronze"."bronze_customers__dbt_tmp" as (
    

SELECT *
FROM read_parquet('s3://datalake/bronze/erp/customers/*.parquet')
  );
