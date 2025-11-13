#!/bin/sh
set -euo pipefail

DREMIO_URL="${DREMIO_URL:-http://dremio:9047}"
ADMIN_USER="${DREMIO_ADMIN_USER:-admin}"
ADMIN_PASSWORD="${DREMIO_ADMIN_PASSWORD:-Lakehouse123}"
ADMIN_EMAIL="${DREMIO_ADMIN_EMAIL:-admin@example.com}"

log() {
  echo "[dremio-init] $*"
}

wait_for_dremio() {
  log "Waiting for Dremio at ${DREMIO_URL}..."
  until curl -sf "${DREMIO_URL}/apiv2/server_status" >/dev/null 2>&1; do
    sleep 5
  done
  log "Dremio API is reachable."
}

bootstrap_admin() {
  log "Bootstrapping admin user (if needed)..."
  curl -s -o /dev/null -X PUT \
    -H "Content-Type: application/json" \
    -d "{\"userName\":\"${ADMIN_USER}\",\"firstName\":\"Data\",\"lastName\":\"Admin\",\"email\":\"${ADMIN_EMAIL}\",\"password\":\"${ADMIN_PASSWORD}\"}" \
    "${DREMIO_URL}/apiv2/bootstrap/firstuser" || true
}

login() {
  log "Logging in as ${ADMIN_USER}..."
  for attempt in $(seq 1 30); do
    RESPONSE=$(curl -s -X POST \
      -H "Content-Type: application/json" \
      -d "{\"userName\":\"${ADMIN_USER}\",\"password\":\"${ADMIN_PASSWORD}\"}" \
      "${DREMIO_URL}/apiv2/login" || true)
    TOKEN=$(echo "${RESPONSE}" | jq -r '.token' 2>/dev/null || echo "")
    if [ -n "${TOKEN}" ] && [ "${TOKEN}" != "null" ]; then
      AUTH_HEADER="_dremio${TOKEN}"
      log "Login succeeded."
      return
    fi
    log "Login not ready yet (attempt ${attempt}/30). Retrying in 5s..."
    sleep 5
  done
  log "Failed to log in after multiple attempts."
  exit 1
}

ensure_source() {
  NAME="$1"
  PAYLOAD="$2"
  if curl -sf -H "Authorization: ${AUTH_HEADER}" "${DREMIO_URL}/api/v3/catalog/by-path/${NAME}" >/dev/null 2>&1; then
    log "Source '${NAME}' already exists. Skipping."
  else
    log "Creating source '${NAME}'..."
    RESPONSE=$(curl -s -w "\n%{http_code}\n" -X POST \
      -H "Authorization: ${AUTH_HEADER}" \
      -H "Content-Type: application/json" \
      -d "${PAYLOAD}" \
      "${DREMIO_URL}/api/v3/catalog")
    HTTP_CODE=$(echo "${RESPONSE}" | tail -n1)
    if [ "${HTTP_CODE}" = "409" ]; then
      log "Source '${NAME}' already exists (HTTP 409). Treating as success."
      return
    fi
    if [ "${HTTP_CODE}" -ge 300 ]; then
      log "Failed to create source '${NAME}'. Response: ${RESPONSE}"
      exit 1
    fi
  fi
}

wait_for_dremio
bootstrap_admin
login

MINIO_PAYLOAD='{
  "entityType": "source",
  "name": "MinIO",
  "type": "S3",
  "config": {
    "accessKey": "minioadmin",
    "accessSecret": "minioadmin123",
    "credentialType": "ACCESS_KEY",
    "compatibilityMode": true,
    "secure": false,
    "enableAsync": false,
    "rootPath": "/",
    "propertyList": [
      {"name": "fs.s3a.endpoint", "value": "minio:9000"},
      {"name": "fs.s3a.connection.ssl.enabled", "value": "false"},
      {"name": "fs.s3a.path.style.access", "value": "true"}
    ],
    "whitelistedBuckets": [
      "datalake"
    ]
  },
  "metadataPolicy": {
    "authTTLMs": 86400000,
    "namesRefreshMs": 3600000,
    "datasetRefreshAfterMs": 3600000,
    "datasetExpireAfterMs": 10800000,
    "datasetUpdateMode": "PREFETCH_QUERIED",
    "deleteUnavailableDatasets": true,
    "autoPromoteDatasets": true
  }
}'

POSTGRES_PAYLOAD='{
  "entityType": "source",
  "name": "ERP_Postgres",
  "type": "POSTGRES",
  "config": {
    "hostname": "postgres",
    "port": "5432",
    "username": "erp_user",
    "password": "erp_password",
    "authenticationType": "MASTER",
    "databaseName": "erp_db",
    "useSsl": false
  }
}'

ensure_source "MinIO" "${MINIO_PAYLOAD}"
ensure_source "ERP_Postgres" "${POSTGRES_PAYLOAD}"

log "Dremio initialization complete."
