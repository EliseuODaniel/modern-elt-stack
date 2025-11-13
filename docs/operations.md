# Operations Playbook

This guide captures the exact configuration that is currently running in this repository so you can reproduce the full stack elsewhere (or recover it later).

## Prerequisites

- Docker Engine 24+ and the Docker Compose plugin 2.20+.
- At least 8 GB RAM available for containers (Airflow, Dremio, MinIO, Jupyter, dbt).
- Ports `5432`, `8080`, `8888`, `9000-9001`, and `9047` open on the host.

## Bring everything up

```bash
git clone <this-repo-url>
cd modern-elt-stack
docker compose up -d
```

Useful status checks:

```bash
docker compose ps
docker compose logs -f dremio
```

## Credentials at a glance

| Service  | URL / Host | Username | Password / Token |
|----------|-----------|----------|------------------|
| Airflow  | http://localhost:8080 | `admin` | `admin` |
| MinIO console | http://localhost:9001 | `minioadmin` | `minioadmin123` |
| PostgreSQL | `postgresql://erp_user:erp_password@localhost:5432/erp_db` | `erp_user` | `erp_password` |
| Dremio | http://localhost:9047 | `admin` | `Lakehouse123` |
| JupyterLab | http://localhost:8888 | `jovyan` | token `elt` |

## Dremio auto-bootstrap details

The helper container `dremio_init` runs `scripts/init_dremio.sh`, which:

1. Waits for the Dremio API (`/apiv2/server_status`).
2. Creates the admin user (`admin / Lakehouse123`) if it does not exist.
3. Logs in and ensures two sources exist:
   - `MinIO` &rarr; S3 source with:
     - Endpoint `minio:9000`
     - Compatibility mode and path-style access
     - `rootPath="/"`, `whitelistedBuckets=["datalake"]`
     - `autoPromoteDatasets=true`, so `datalake/bronze|silver|gold` appears immediately in SQL Runner (no manual “Format” step).
   - `ERP_Postgres` &rarr; JDBC source pointing at `erp_postgres` with credentials `erp_user` / `erp_password`.

Re-run the bootstrap any time with:

```bash
docker compose up -d dremio dremio_init
```

## Verifying the lakehouse end-to-end

1. Trigger the ELT DAGs (optional if data already exists):
   ```bash
   docker compose exec airflow airflow dags trigger erp_to_minio_bronze
   docker compose exec airflow airflow dags trigger transform_bronze_to_silver_gold
   ```
2. Confirm Dremio sees the curated tables:
   - Open the SQL Runner and run:
     ```sql
     SELECT COUNT(*) AS cnt
     FROM MinIO.datalake.gold.dim_customer;
     ```
     Expected output: `cnt = 10`.
3. Browse MinIO at http://localhost:9001 to see `bronze/`, `silver/`, and `gold/` folders.
4. (Optional) In JupyterLab, run the DuckDB snippet from `README.md` to query the same Parquet files via `read_parquet('s3://datalake/...')`.

## Resetting components

- **Full stop (preserves data):**
  ```bash
  docker compose down
  ```
- **Full reset (removes volumes):**
  ```bash
  docker compose down -v
  ```
- **Only Dremio metadata:** remove volumes `modern-elt-stack_dremio_data` and `modern-elt-stack_dremio_log`, then `docker compose up -d dremio dremio_init`.

## Publishing this state

To share the current setup publicly:

```bash
# Inside the repo
git status
git add .
git commit -m "Document operations playbook and ensure Dremio bootstrap notes"
git remote add origin git@github.com:<your-user>/<your-repo>.git  # use your repo name
git push -u origin main
```

Anyone cloning the pushed repo can replay the exact steps above to get an identical environment.
