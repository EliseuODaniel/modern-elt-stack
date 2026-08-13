# Modern ELT Data Engineering Sandbox

This repository spins up a fully containerized ELT playground that mimics a modern data platform: PostgreSQL acts as an ERP source, Airflow orchestrates jobs, MinIO stores Parquet data across bronze/silver/gold zones, dbt + DuckDB perform transformations, and JupyterLab + DuckDB notebooks let you explore the curated datasets.

## Project status

This is a local educational sandbox and portfolio reference, not a production deployment. The source-controlled surface consists of Docker configuration, DAGs, dbt models, bootstrap scripts, and documentation. Generated dbt artifacts, DuckDB files, Dremio metadata/logs, Python caches, and local profiles are intentionally excluded from Git and are recreated by the stack.

The credentials shown below are development defaults for an isolated local environment. Change them before exposing any service beyond localhost, and never reuse them in a real environment.

```mermaid
flowchart LR
  ERP[PostgreSQL ERP]
  ERP -->|Airflow extract| Bronze[MinIO Bronze]
  Bronze -->|dbt run - DuckDB| Silver[MinIO Silver]
  Silver -->|dbt run - DuckDB| Gold[MinIO Gold]
  Bronze --> Notebook[JupyterLab + DuckDB]
  Silver --> Notebook
  Gold --> Notebook
```

## Stack at a Glance

| Service  | Purpose | Port | Default credentials |
|----------|---------|------|---------------------|
| PostgreSQL | ERP-style OLTP source with seeded tables (`erp.*`). | 5432 | `erp_user` / `erp_password` |
| MinIO | S3-compatible lake with `datalake/bronze|silver|gold`. | 9000 (API), 9001 (console) | `minioadmin` / `minioadmin123` |
| Apache Airflow | Runs extraction + dbt DAGs (webserver+scheduler). | 8080 | `admin` / `admin` |
| dbt + DuckDB | CLI container to run transformations manually. | n/a | uses env vars | 
| JupyterLab + DuckDB | Notebook + SQL workspace to explore datasets via DuckDB (connects to MinIO and Postgres). | 8888 | token `elt` (see instructions below) |
| Dremio OSS | Lakehouse SQL / BI layer automatically wired to MinIO + Postgres. | 9047 | `admin` / `Lakehouse123` |

## Prerequisites

- Docker 24+
- Docker Compose plugin 2.20+
- At least 8 GB RAM available for containers (Airflow + notebooks + Dremio + MinIO)

## Getting Started

1. Clone this repo and move into it.
2. Start everything:
   ```bash
   docker compose up -d
   ```
3. Tail logs (optional):
   ```bash
   docker compose logs -f airflow
   ```

### Accessing the services

- **Airflow UI:** http://localhost:8080 (user `admin`, password `admin`). The DAGs are paused by default; turn them on or trigger manually.
- **MinIO Console:** http://localhost:9001 (`minioadmin` / `minioadmin123`). Navigate to the `datalake` bucket and inspect `bronze/`, `silver/`, and `gold/` prefixes.
- **PostgreSQL:** connect via any SQL tool using `postgresql://erp_user:erp_password@localhost:5432/erp_db`.
- **Dremio UI:** http://localhost:9047 (user `admin`, password `Lakehouse123`). The setup script auto-creates two sources:
  - `MinIO` → already pointing to the `datalake` bucket (navigate into `datalake/bronze|silver|gold`).
  - `ERP_Postgres` → wired to the `erp_db` database/schema.
  Example query inside Dremio's SQL Runner:
  ```sql
  SELECT * FROM MinIO.datalake.gold.dim_customer LIMIT 20;
  ```

## Running the ELT pipelines

### 1. Extract ERP ➜ MinIO (bronze)

- Airflow DAG ID: `erp_to_minio_bronze`
- Schedules every 6 hours; run now via UI or CLI:
  ```bash
  docker compose exec airflow airflow dags trigger erp_to_minio_bronze
  ```
- The task set reads each ERP table, writes Parquet files, and uploads them to `s3://datalake/bronze/erp/<table>/<logical_date>.parquet` inside MinIO.

### 2. Transform Bronze ➜ Silver/Gold (dbt + DuckDB)

- Airflow DAG ID: `transform_bronze_to_silver_gold`
- Depends on the bronze files; it runs `dbt deps → dbt run → dbt test` inside the Airflow container.
- Trigger manually:
  ```bash
  docker compose exec airflow airflow dags trigger transform_bronze_to_silver_gold
  ```
- dbt materializes external Parquet datasets:
  - Silver: `s3://datalake/silver/erp/...`
  - Gold: `s3://datalake/gold/dim_customer`, `.../dim_product`, `.../fct_orders`

### Manual dbt workflows

A dedicated container (`dbt_duckdb`) is provided for local experimentation.

```bash
# Install deps (no-op if already pulled)
docker compose run --rm dbt_duckdb dbt deps

# Validate profile connectivity
docker compose run --rm dbt_duckdb dbt debug --profiles-dir /dbt

# Execute models + tests
docker compose run --rm dbt_duckdb bash -c "cd /dbt && dbt run && dbt test"
```

Both Airflow and the dbt container mount `./dbt_project`, which includes:
- `dbt_project.yml` – project metadata
- `profiles_example.yml` – copy or symlink to `profiles.yml` if you want to run dbt outside Docker (`~/.dbt/profiles.yml`).

## Interactive SQL workspace (Jupyter + DuckDB)

JupyterLab complements Dremio as a lightweight SQL notebook workspace (http://localhost:8888, token `elt`).

1. Start the stack (`docker compose up -d`). When the `lakehouse_notebook` container is up, open http://localhost:8888 and enter the token `elt`.
2. Create a new Python notebook and run the cell below to spin up a DuckDB connection that understands both MinIO (S3) and Postgres:

   ```python
   import duckdb, os

   con = duckdb.connect()
   con.execute("INSTALL httpfs; LOAD httpfs;")
   con.execute("SET s3_endpoint='minio:9000';")
   con.execute("SET s3_access_key_id='minioadmin'; SET s3_secret_access_key='minioadmin123';")
   con.execute("SET s3_url_style='path'; SET s3_use_ssl=false;")
   con.execute("INSTALL postgres; LOAD postgres;")
   con.execute("ATTACH 'postgresql://erp_user:erp_password@postgres:5432/erp_db' AS erp_db (TYPE POSTGRES);")
   ```

   > Obs.: passe apenas `minio:9000` no `s3_endpoint` (sem `http://`). O DuckDB adiciona o protocolo automaticamente; se você incluir `http://`, ele duplica o prefixo e as leituras falham.

3. Run SQL directly from DuckDB:

   ```python
   con.sql("SELECT * FROM read_parquet('s3://datalake/gold/dim_customer/dim_customer.parquet') LIMIT 5;")
   con.sql("SELECT * FROM erp_db.erp.orders LIMIT 5;")
   ```

4. If you prefer a pure-SQL experience, install the `ipython-sql` extension inside the notebook (`%load_ext sql`) and use `%sql duckdb://` cells.

This workspace sits alongside Dremio as an ad-hoc SQL surface while keeping the same underlying bronze/silver/gold layout in MinIO.

## Dremio lakehouse workspace

Dremio complements the notebooks for anyone who prefers a drag-and-drop lakehouse UI:

1. Open http://localhost:9047 and authenticate with `admin / Lakehouse123`.
2. The bootstrap job creates two ready-to-use sources:
   - `MinIO` (S3-compatible) pre-wired to the `datalake` bucket via `minio:9000`, compatibility mode, and path-style access. Auto-promotion is on, so folders under `datalake/bronze|silver|gold` immediately show up in the SQL Runner without any manual "Format" step.
   - `ERP_Postgres` pointing to the transactional database.
3. Under **Datasets**, expand `MinIO → datalake` and drill into `bronze/`, `silver/`, or `gold/`. All folders and Parquet files are queryable directly (e.g., `MinIO.datalake.gold.dim_customer`).
4. Example SQL from the Dremio query editor:
   ```sql
   SELECT
     customer_id,
     customer_name,
     email
   FROM MinIO.datalake.gold.dim_customer
   ORDER BY customer_id
   LIMIT 50;
   ```

If you ever need to rebootstrap the sources, re-run `docker compose up -d dremio dremio_init`. The helper script (`scripts/init_dremio.sh`) handles user creation and source provisioning automatically.

## Data locations in MinIO

```
s3://datalake/bronze/erp/...    # Raw extracts from PostgreSQL
s3://datalake/silver/erp/...    # Cleaned/normalized silver tables
s3://datalake/gold/...          # Dimensional/fact models
```

You can browse these via the MinIO console or any S3-compatible client (e.g., `aws s3 ls --endpoint-url http://localhost:9000 s3://datalake/`).

## Stopping & cleanup

```bash
# Stop containers but keep data
 docker compose down

# Remove everything (including volumes) – optional destructive step
docker compose down -v
```

## Troubleshooting tips

- Airflow plugins/requirements are installed every time the container starts; the first boot can take a minute.
- If dbt cannot reach MinIO, verify that `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `S3_ENDPOINT_URL` exist inside the calling container.

Enjoy exploring a modern ELT workflow end-to-end!

> Para instruções mais detalhadas (comandos, troubleshooting e snippets), veja também `doc/README.md` e `docs/operations.md`.

## License

MIT — see [LICENSE](LICENSE).
