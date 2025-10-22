#!/usr/bin/env bash
set -euo pipefail

# Reset the demo database state by dropping and recreating the public schema
# WARNING: This will DELETE ALL TABLES in the public schema. Run only on local/test DB.

ROOT=$(cd "$(dirname "$0")/.." && pwd)
export CONN_STRING=${CONN_STRING:-"postgresql://postgres:postgres@127.0.0.1:54322/postgres"}

read -p "This will DROP the public schema and remove seeded demo users. Continue? [y/N] " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Aborted.";
  exit 0;
fi

echo "Dropping public schema..."
psql "$CONN_STRING" -c "DROP SCHEMA public CASCADE;"

echo "Recreating public schema..."
psql "$CONN_STRING" -c "CREATE SCHEMA public;"
psql "$CONN_STRING" -c "GRANT ALL ON SCHEMA public TO postgres;"
psql "$CONN_STRING" -c "GRANT ALL ON SCHEMA public TO public;"

echo "Removing seeded auth.users rows (local dev only)..."
psql "$CONN_STRING" -c "DELETE FROM auth.users WHERE id IN ('22222222-2222-2222-2222-222222222222','33333333-3333-3333-3333-333333333333','44444444-4444-4444-4444-444444444444','55555555-5555-5555-5555-555555555555');" || true

echo "Reset complete. Re-run ./scripts/demo.sh to reinitialize the demo (migrations + seed)."
