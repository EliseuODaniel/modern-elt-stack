# Modern ELT Sandbox — Documentation

Esta pasta consolida instruções detalhadas sobre a stack descrita no README principal. Use-a como referência rápida para entender cada componente, comandos de operação e fluxos comuns de troubleshooting.

## Serviços

| Serviço | Descrição | Portas/Endpoint | Credenciais |
|---------|-----------|-----------------|-------------|
| PostgreSQL (`erp_postgres`) | Banco OLTP com o schema `erp` já populado. | `localhost:5432` | `erp_user` / `erp_password` |
| MinIO (`datalake_minio`) | Armazena os Parquet das zonas bronze/silver/gold. | API `http://localhost:9000` / Console `http://localhost:9001` | `minioadmin` / `minioadmin123` |
| Airflow (`airflow`) | Orquestra as DAGs `erp_to_minio_bronze` e `transform_bronze_to_silver_gold`. | `http://localhost:8080` | `admin` / `admin` |
| dbt CLI (`dbt_duckdb`) | Container utilitário para rodar `dbt` manualmente. | n/a | herda variáveis de ambiente |
| JupyterLab (`lakehouse_notebook`) | Notebook + DuckDB para consultas ad-hoc em MinIO/Postgres. | `http://localhost:8888` | token `elt` |

## Fluxo ELT

1. **Bronze** — DAG `erp_to_minio_bronze` lê cada tabela `erp.*`, grava Parquet e envia para `s3://datalake/bronze/erp/<tabela>/<ds>.parquet`.
2. **Silver/Gold** — DAG `transform_bronze_to_silver_gold` roda `dbt deps/run/test`. Os modelos usam `materialized='external'` com `location` fixo, gerando arquivos únicos por entidade, por exemplo:
   - `s3://datalake/silver/erp/orders/silver_orders.parquet`
   - `s3://datalake/gold/fct_orders/fct_orders.parquet`
3. **Exploração** — JupyterLab com DuckDB lê tanto o S3 quanto o Postgres; basta configurar HTTPFS e, se quiser, o conector Postgres.

## Comandos úteis

```bash
# Subir/derrubar tudo
docker compose up -d
docker compose down

# Rodar DAGs manualmente
docker compose exec airflow airflow dags trigger erp_to_minio_bronze
docker compose exec airflow airflow dags trigger transform_bronze_to_silver_gold

# Rodar dbt manualmente
docker compose run --rm dbt_duckdb bash -c "cd /dbt && dbt run && dbt test"

# Entrar no notebook (token elt)
open http://localhost:8888
```

## DuckDB + MinIO (via notebook)

```python
import duckdb

con = duckdb.connect()
con.execute("INSTALL httpfs; LOAD httpfs;")
con.execute("SET s3_endpoint='minio:9000';")  # sem http://
con.execute("SET s3_url_style='path'; SET s3_use_ssl=false;")
con.execute("SET s3_access_key_id='minioadmin'; SET s3_secret_access_key='minioadmin123';")

con.sql("SELECT * FROM read_parquet('s3://datalake/gold/dim_customer/dim_customer.parquet') LIMIT 5;")
```

Para anexar o Postgres:

```python
con.execute("INSTALL postgres; LOAD postgres;")
con.execute("ATTACH 'postgresql://erp_user:erp_password@postgres:5432/erp_db' AS erp_db (TYPE POSTGRES);")
con.sql("SELECT * FROM erp_db.erp.orders LIMIT 5;")
```

## Estrutura do bucket MinIO

```
bronze/erp/<tabela>/<YYYYMMDD>.parquet
silver/erp/<tabela>/<silver_<tabela>.parquet>
gold/dim_customer/dim_customer.parquet
gold/dim_product/dim_product.parquet
gold/fct_orders/fct_orders.parquet
```

## Troubleshooting rápido

- **`read_parquet` falhou com `http://http://minio...`** → reconfigure `SET s3_endpoint='minio:9000';` (sem protocolo).
- **Jupyter não sobe** → verifique `docker compose logs -f jupyter`; o container instala pip packages na primeira inicialização.
- **Airflow DAG travada** → `docker compose logs -f airflow | grep <dag_id>` ou abra o Grid/Logs na UI.
- **MinIO vazio** → confira se a DAG bronze foi rodada; os arquivos aparecem no console `http://localhost:9001` (bucket `datalake`).

## Convenções

- O repositório assume WSL2/Unix; em Windows use PowerShell/Git Bash, mas não altere os paths.
- `dbt_project` fica montada nos containers para evitar rebuilds longos.
- Tudo roda na rede `modern_elt_net`; você pode anexar novos serviços usando o mesmo network se quiser expandir.

Para detalhes adicionais, veja o README raiz ou abra issues com dúvidas específicas.
