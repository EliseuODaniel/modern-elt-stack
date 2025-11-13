# Modern ELT Sandbox — Documentação Completa

Esta pasta centraliza as instruções detalhadas sobre cada componente do ambiente.

## Serviços

| Serviço | Descrição | Endpoint | Credenciais |
|---------|-----------|----------|-------------|
| PostgreSQL (`erp_postgres`) | Banco OLTP com o schema `erp` já populado. | `postgresql://erp_user:erp_password@localhost:5432/erp_db` | `erp_user` / `erp_password` |
| MinIO (`datalake_minio`) | Armazena os Parquet das zonas bronze/silver/gold. | Console `http://localhost:9001` | `minioadmin` / `minioadmin123` |
| Airflow (`airflow`) | DAGs `erp_to_minio_bronze` e `transform_bronze_to_silver_gold`. | `http://localhost:8080` | `admin` / `admin` |
| dbt CLI (`dbt_duckdb`) | Container utilitário para rodar `dbt run/test`. | `docker compose run --rm dbt_duckdb …` | usa env vars do compose |
| JupyterLab (`lakehouse_notebook`) | Notebook + DuckDB para consultas ad-hoc. | `http://localhost:8888` | token `elt` |
| Dremio (`dremio`) | Lakehouse/SQL UI com fontes `MinIO` e `ERP_Postgres` auto-provisionadas + auto-promote do bucket `datalake`. | `http://localhost:9047` | `admin` / `Lakehouse123` |

## Fluxo operacional

1. **Subir o stack**
   ```bash
   docker compose up -d
   ```
2. **Extrair ERP → Bronze**
   ```bash
   docker compose exec airflow airflow dags trigger erp_to_minio_bronze
   ```
3. **Bronze → Silver/Gold (dbt)**
   ```bash
   docker compose exec airflow airflow dags trigger transform_bronze_to_silver_gold
   ```
4. **Explorar dados**
   - Via Dremio (SQL Runner / BI)
   - Via JupyterLab + DuckDB (`read_parquet` e `ATTACH` do Postgres)

## Snippets úteis

- DuckDB + MinIO:
  ```python
  import duckdb
  con = duckdb.connect()
  con.execute("INSTALL httpfs; LOAD httpfs;")
  con.execute("SET s3_endpoint='minio:9000';")
  con.execute("SET s3_url_style='path'; SET s3_use_ssl=false;")
  con.execute("SET s3_access_key_id='minioadmin'; SET s3_secret_access_key='minioadmin123';")
  con.sql("SELECT * FROM read_parquet('s3://datalake/gold/dim_customer/dim_customer.parquet') LIMIT 5;")
  ```

- Anexar Postgres no DuckDB:
  ```python
  con.execute("INSTALL postgres; LOAD postgres;")
  con.execute("ATTACH 'postgresql://erp_user:erp_password@postgres:5432/erp_db' AS erp_db (TYPE POSTGRES);")
  con.sql("SELECT * FROM erp_db.erp.orders LIMIT 5;")
  ```

- Dremio SQL (já com fontes disponíveis):
  ```sql
  SELECT customer_id, customer_name
  FROM MinIO.datalake.gold.dim_customer
  ORDER BY customer_id
  LIMIT 20;
  ```
  > A aba SQL Runner já exibe `MinIO → datalake → bronze/silver/gold` automaticamente graças ao `autoPromoteDatasets=true`.

## Estrutura do bucket MinIO

```
bronze/erp/<tabela>/<YYYYMMDD>.parquet
silver/erp/<tabela>/silver_<tabela>.parquet
gold/dim_customer/dim_customer.parquet
gold/dim_product/dim_product.parquet
gold/fct_orders/fct_orders.parquet
```

## Troubleshooting

- **`read_parquet` com URL duplicada (`http://http://`)** → use `SET s3_endpoint='minio:9000';`.
- **Quer resetar o Dremio?** → `docker compose down dremio dremio_init && docker compose up -d dremio dremio_init`.
- **Dremio sem fontes** → `docker compose up -d dremio_init` recria o usuário e os sources.
- **MinIO vazio** → rode a DAG `erp_to_minio_bronze`.

Consulte também `docs/architecture.md` para uma visão gráfica do fluxo.
