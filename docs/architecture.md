# Modern ELT Demo Architecture

This repository provisions a fully containerized ELT playground built around five key components:

1. **PostgreSQL (ERP simulation)** – acts as the transactional source system with seeded tables and reference data.
2. **Apache Airflow** – orchestrates the ELT workload. One DAG extracts ERP data to the lake (bronze) and another executes dbt for silver/gold curation.
3. **MinIO** – serves as the S3-compatible data lake. Buckets/paths are created for bronze, silver, and gold zones.
4. **dbt + DuckDB** – performs analytical transformations. DuckDB reads/writes Parquet files directly to MinIO using the `httpfs` extension.
5. **JupyterLab + DuckDB** – notebooks to query the curated Parquet datasets (silver/gold) and the ERP Postgres source.

```mermaid
flowchart LR
  ERP[PostgreSQL ERP]
  ERP -->Airflow extract Bronze[MinIO Bronze]
  Bronze -->dbt run - DuckDB Silver[MinIO Silver]
  Silver -->dbt run - DuckDB Gold[MinIO Gold]
  Bronze --> Notebook[JupyterLab + DuckDB]
  Silver --> Notebook
  Gold --> Notebook
```

Airflow e dbt compartilham a mesma rede/credenciais para ler e escrever Parquet no MinIO. O workspace JupyterLab já vem pré-configurado (via DuckDB + httpfs) para explorar tanto o Postgres fonte quanto as zonas silver/gold em MinIO.
