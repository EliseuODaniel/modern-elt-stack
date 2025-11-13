#!/bin/sh
set -euo pipefail

ALIAS="local"
BUCKET="${MINIO_BUCKET:-datalake}"

until mc alias set "$ALIAS" http://minio:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"; do
  echo "Waiting for MinIO to be ready..."
  sleep 2
done

echo "Creating bucket structure in $BUCKET"
mc mb --ignore-existing "$ALIAS/$BUCKET"
mc mb --ignore-existing "$ALIAS/$BUCKET/bronze"
mc mb --ignore-existing "$ALIAS/$BUCKET/silver"
mc mb --ignore-existing "$ALIAS/$BUCKET/gold"
mc mb --ignore-existing "$ALIAS/$BUCKET/bronze/erp"
mc mb --ignore-existing "$ALIAS/$BUCKET/silver/erp"
mc mb --ignore-existing "$ALIAS/$BUCKET/gold/erp"
