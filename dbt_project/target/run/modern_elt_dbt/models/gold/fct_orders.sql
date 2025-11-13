create or replace view "warehouse"."main_gold"."fct_orders__dbt_int" as (
        select * from 's3://datalake/gold/fct_orders/fct_orders.parquet'
    );