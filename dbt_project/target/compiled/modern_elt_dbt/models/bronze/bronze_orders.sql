

-- Bronze layer: ERP orders for downstream cleansing.
SELECT *
FROM read_parquet('s3://datalake/bronze/erp/orders/*.parquet')