#!/bin/bash

SUPERUSER_PASS="super_secret_root_password"

DB_NAME=$1
DB_USER=$2
DB_PASS=$3

if [ -z "$DB_PASS" ]; then
  echo "Usage: ./create-service-db.sh <database_name> <username> <password>"
  echo "Example: ./create-service-db.sh nextcloud_db nextcloud_user securepass123"
  exit 1
fi

echo "Spinning up ephemeral container to create $DB_NAME..."

docker run --rm --network db_network \
  -e PGPASSWORD="$SUPERUSER_PASS" \
  postgres:15-alpine \
  psql -h pgpool -U postgres -d postgres \
  -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';" \
  -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};" \
  -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"

if [ $? -eq 0 ]; then
  echo "✅ Success! Database '${DB_NAME}' and User '${DB_USER}' are ready."
  echo "🔗 Connection string for your apps: postgres://${DB_USER}:${DB_PASS}@pgpool:5432/${DB_NAME}"
else
  echo "❌ Failed to create database. Check the error output above."
fi
