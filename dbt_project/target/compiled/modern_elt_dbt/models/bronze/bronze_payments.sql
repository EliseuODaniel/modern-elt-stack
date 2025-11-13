

-- Bronze layer: raw payment ledger from the ERP.
SELECT *
FROM read_parquet('s3://datalake/bronze/erp/payments/*.parquet')