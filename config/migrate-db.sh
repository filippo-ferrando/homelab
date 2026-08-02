#!/bin/bash

echo "================================================="
echo "   Interactive DB Migration to Pgpool Cluster"
echo "================================================="

# --- 1. PROMPT FOR USER INPUT ---
echo "--- Old Database Details ---"
read -p "1. Old DB Host/Service Name (e.g., nextcloud-db): " OLD_DB_HOST
read -p "2. Old DB User: " OLD_DB_USER
read -s -p "3. Old DB Password: " OLD_DB_PASS
echo
read -p "4. Old DB Name: " OLD_DB_NAME
read -p "5. Old Network Name (e.g., nextcloud-internal): " OLD_NET_NAME

echo ""
echo "--- New DBaaS (Pgpool) Details ---"
read -p "6. New DB User: " NEW_DB_USER
read -s -p "7. New DB Password: " NEW_DB_PASS
echo
read -p "8. New DB Name: " NEW_DB_NAME

CREATE_SCRIPT="./create-db-table.sh"
# We map /tmp from the host to /dumps in the containers
HOST_DUMP_DIR="/tmp"
DUMP_FILENAME="${OLD_DB_NAME}_migration.backup"

echo ""
echo "================================================="
echo " Starting Migration..."
echo "================================================="

# --- 2. DUMP THE OLD DATABASE ---
echo "[1/4] Spinning up ephemeral container on '${OLD_NET_NAME}' to dump data..."
# Use -v to map the host's /tmp to the container's /dumps so the file persists between steps
docker run --rm --network "${OLD_NET_NAME}" \
  -v "${HOST_DUMP_DIR}:/dumps" \
  -e PGPASSWORD="${OLD_DB_PASS}" \
  postgres:15-alpine \
  pg_dump -h "${OLD_DB_HOST}" -U "${OLD_DB_USER}" -Fc "${OLD_DB_NAME}" -f "/dumps/${DUMP_FILENAME}"

if [ $? -ne 0 ]; then
  echo "❌ Error: Failed to dump the old database."
  exit 1
fi
echo "✅ Dump successful! Saved to ${HOST_DUMP_DIR}/${DUMP_FILENAME}"

# --- 3. CREATE THE NEW DATABASE ---
echo "[2/4] Creating new database '${NEW_DB_NAME}' on Pgpool cluster..."
if [ ! -f "${CREATE_SCRIPT}" ]; then
  echo "❌ Error: Could not find ${CREATE_SCRIPT}. Please ensure it is in the same directory."
  exit 1
fi

bash "${CREATE_SCRIPT}" "${NEW_DB_NAME}" "${NEW_DB_USER}" "${NEW_DB_PASS}"

if [ $? -ne 0 ]; then
  echo "❌ Error: Failed to create the new database."
  exit 1
fi
echo "✅ Database created successfully."

# --- 4. RESTORE INTO PGPOOL ---
echo "[3/4] Spinning up ephemeral container on 'db_network' to restore data..."
docker run --rm --network db_network \
  -v "${HOST_DUMP_DIR}:/dumps" \
  -e PGPASSWORD="${NEW_DB_PASS}" \
  postgres:15-alpine \
  pg_restore -h pgpool -U "${NEW_DB_USER}" -d "${NEW_DB_NAME}" \
  --clean --if-exists --no-owner --no-privileges -1 "/dumps/${DUMP_FILENAME}"

if [ $? -ne 0 ]; then
  echo "❌ Error: Failed to restore the database into Pgpool."
  exit 1
fi
echo "✅ Data restored successfully!"

# --- 5. CLEANUP ---
echo "[4/4] Cleaning up temporary files..."
rm -f "${HOST_DUMP_DIR}/${DUMP_FILENAME}"

# --- 6. OUTPUT NEW STACK SETTINGS ---
echo "================================================="
echo "🎉 Migration Complete!"
echo ""
echo "Remove the old database service from your stack."
echo "Update your application stack (docker-compose.yml) with these new settings:"
echo "-------------------------------------------------"
echo "Networks configuration to add to your app service:"
echo "  networks:"
echo "    - db_network"
echo "    - traefik-net   # (Keep your existing network)"
echo ""
echo "Database Connection Environment Variables:"
echo "  DB_HOST     = pgpool"
echo "  DB_PORT     = 5432"
echo "  DB_NAME     = ${NEW_DB_NAME}"
echo "  DB_USER     = ${NEW_DB_USER}"
echo "  DB_PASSWORD = ${NEW_DB_PASS}"
echo "-------------------------------------------------"
echo "Don't forget to define 'db_network: { external: true }' at the bottom of the compose file!"
echo "================================================="
