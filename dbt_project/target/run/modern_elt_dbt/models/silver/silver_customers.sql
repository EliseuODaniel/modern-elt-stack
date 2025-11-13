create or replace view "warehouse"."main_silver"."silver_customers__dbt_int" as (
        select * from 's3://datalake/silver/erp/customers/silver_customers.parquet'
    );