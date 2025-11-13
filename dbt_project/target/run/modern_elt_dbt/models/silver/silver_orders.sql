create or replace view "warehouse"."main_silver"."silver_orders__dbt_int" as (
        select * from 's3://datalake/silver/erp/orders/silver_orders.parquet'
    );