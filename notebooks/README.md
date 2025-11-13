# Notebooks

This directory is mounted inside the JupyterLab container (`lakehouse_notebook`). Any `.ipynb` you create via http://localhost:8888 (token `elt`) ficará salvo aqui.

Se quiser acessar o lago diretamente por DuckDB num notebook novo, rode:

```python
import duckdb

con = duckdb.connect()
con.execute("INSTALL httpfs; LOAD httpfs;")
con.execute("SET s3_endpoint='minio:9000';")
con.execute("SET s3_url_style='path'; SET s3_use_ssl=false;")
con.execute("SET s3_access_key_id='minioadmin'; SET s3_secret_access_key='minioadmin123';")
```

É importante passar somente `minio:9000` como endpoint (sem `http://`), pois o DuckDB acrescenta o protocolo automaticamente.
