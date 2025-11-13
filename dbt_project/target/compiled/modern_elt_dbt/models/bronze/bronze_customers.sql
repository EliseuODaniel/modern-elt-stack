

SELECT *
FROM read_parquet('s3://datalake/bronze/erp/customers/*.parquet')