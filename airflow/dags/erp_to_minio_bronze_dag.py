"""Airflow DAG that copies ERP tables from Postgres into MinIO as bronze Parquet files."""
from __future__ import annotations

from datetime import datetime, timedelta
from io import BytesIO
import logging
import os

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
import boto3
from botocore.config import Config

DEFAULT_ARGS = {
    "owner": "data-platform",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

TABLES = [
    "customers",
    "products",
    "orders",
    "order_items",
    "payments",
]

BUCKET = os.getenv("MINIO_BUCKET", "datalake")
BRONZE_PREFIX = os.getenv("MINIO_BRONZE_PREFIX", "bronze/erp")
S3_ENDPOINT_URL = os.getenv("S3_ENDPOINT_URL", "http://minio:9000")
AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
AWS_DEFAULT_REGION = os.getenv("AWS_DEFAULT_REGION", "us-east-1")

_s3_client = None


def get_s3_client():
    global _s3_client
    if _s3_client is None:
        _s3_client = boto3.client(
            "s3",
            endpoint_url=S3_ENDPOINT_URL,
            aws_access_key_id=AWS_ACCESS_KEY_ID,
            aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
            region_name=AWS_DEFAULT_REGION,
            config=Config(signature_version="s3v4"),
        )
    return _s3_client


def _extract_table(table_name: str, execution_date: datetime, **context) -> None:
    """Read an ERP table and persist it as a Parquet object in MinIO."""
    hook = PostgresHook(postgres_conn_id="postgres_erp")
    sql = f"SELECT * FROM erp.{table_name}"

    # For a real incremental load you would filter using updated_ts/order_ts here.
    df = hook.get_pandas_df(sql)
    if df.empty:
        logging.info("Table %s returned no rows", table_name)
        return

    buffer = BytesIO()
    df.to_parquet(buffer, index=False)
    buffer.seek(0)

    logical_date = context["ds_nodash"]
    object_key = f"{BRONZE_PREFIX}/{table_name}/{logical_date}.parquet"

    get_s3_client().put_object(
        Bucket=BUCKET,
        Key=object_key,
        Body=buffer.read(),
    )
    logging.info("Uploaded %s rows from %s to s3://%s/%s", len(df), table_name, BUCKET, object_key)


def _build_tasks(dag: DAG) -> None:
    for table in TABLES:
        PythonOperator(
            task_id=f"extract_{table}",
            python_callable=_extract_table,
            op_kwargs={"table_name": table},
            dag=dag,
        )


dag = DAG(
    dag_id="erp_to_minio_bronze",
    description="Full-load ERP tables from Postgres into the MinIO bronze zone",
    default_args=DEFAULT_ARGS,
    schedule_interval=timedelta(hours=6),
    start_date=datetime(2023, 7, 1),
    catchup=False,
    tags=["bronze", "postgres", "minio"],
)

_build_tasks(dag)
