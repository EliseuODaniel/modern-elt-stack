create or replace view "warehouse"."main_gold"."dim_customer__dbt_int" as (
        select * from 's3://datalake/gold/dim_customer/dim_customer.parquet'
    );