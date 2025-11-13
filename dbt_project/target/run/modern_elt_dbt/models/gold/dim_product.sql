create or replace view "warehouse"."main_gold"."dim_product__dbt_int" as (
        select * from 's3://datalake/gold/dim_product/dim_product.parquet'
    );