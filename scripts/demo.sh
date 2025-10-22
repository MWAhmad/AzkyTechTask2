#!/usr/bin/env bash
set -euo pipefail

# Demo script for proctors: starts supabase, applies migrations, seeds, and runs smoke checks
# Usage: ./scripts/demo.sh

ROOT=$(cd "$(dirname "$0")/.." && pwd)
export CONN_STRING=${CONN_STRING:-"postgresql://postgres:postgres@127.0.0.1:54322/postgres"}

echo "Starting Supabase local stack (this may take a minute)..."
npx supabase start

echo "Applying migrations..."
psql "$CONN_STRING" -f "$ROOT/migrations/tables/001_create_tables.sql"
psql "$CONN_STRING" -f "$ROOT/migrations/rls/001_enable_rls_and_policies.sql"

echo "Seeding database..."
psql "$CONN_STRING" -f "$ROOT/seed/seed_data.sql"

echo "Running smoke test (prints jobs & matches):"
npm run smoke

echo "Running RLS test as non-superuser (prints job counts)..."
# Create role if missing (works on more Postgres versions) and grant privileges
psql "$CONN_STRING" -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'test_recruiter') THEN CREATE ROLE test_recruiter LOGIN PASSWORD 'testpass'; END IF; END \$\$;"
psql "$CONN_STRING" -c "GRANT CONNECT ON DATABASE postgres TO test_recruiter;"
psql "$CONN_STRING" -c "GRANT USAGE ON SCHEMA public TO test_recruiter;"
psql "$CONN_STRING" -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO test_recruiter;"
psql "$CONN_STRING" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO test_recruiter;"
CONN_STRING="postgresql://test_recruiter:testpass@127.0.0.1:54322/postgres" npm run rls-test

echo "Demo complete. Open Supabase Studio at http://127.0.0.1:54323 to inspect tables visually."
