

-- Bronze layer: exposes product snapshots exactly as extracted from ERP.
SELECT *
FROM read_parquet('s3://datalake/bronze/erp/products/*.parquet')