"""Airflow DAG that executes dbt (DuckDB) models to build silver/gold layers."""
from __future__ import annotations

from datetime import datetime, timedelta
import os

from airflow import DAG
from airflow.operators.bash import BashOperator

DEFAULT_ARGS = {
    "owner": "data-platform",
    "depends_on_past": False,
    "retries": 0,
}

DBT_DIR = "/opt/airflow/dbt"
DBT_BIN = os.getenv("DBT_BIN", "/home/airflow/.local/bin/dbt")
DBT_ENV_PREFIX = f"export DBT_PROFILES_DIR={DBT_DIR} && "


dag = DAG(
    dag_id="transform_bronze_to_silver_gold",
    description="Run dbt models (DuckDB) that read from MinIO bronze and publish silver/gold",
    default_args=DEFAULT_ARGS,
    schedule_interval=timedelta(hours=6),
    start_date=datetime(2023, 7, 1),
    catchup=False,
    tags=["dbt", "duckdb", "silver", "gold"],
)

with dag:
    dbt_deps = BashOperator(
        task_id="dbt_deps",
        bash_command=f"cd {DBT_DIR} && {DBT_ENV_PREFIX}{DBT_BIN} deps",
    )

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=f"cd {DBT_DIR} && {DBT_ENV_PREFIX}{DBT_BIN} run",
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"cd {DBT_DIR} && {DBT_ENV_PREFIX}{DBT_BIN} test",
    )

    dbt_deps >> dbt_run >> dbt_test
