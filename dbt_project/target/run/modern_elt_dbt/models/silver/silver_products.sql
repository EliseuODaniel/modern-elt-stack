create or replace view "warehouse"."main_silver"."silver_products__dbt_int" as (
        select * from 's3://datalake/silver/erp/products/silver_products.parquet'
    );