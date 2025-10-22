Project: Recruitment SaaS - Supabase schema as code

What I added
- /migrations/tables/001_create_tables.sql  -- creates core tables
- /migrations/rls/001_enable_rls_and_policies.sql -- enables RLS and policies
- /seed/seed_data.sql -- sample data to validate schema

Getting Started (Supabase CLI)
1) Install Supabase CLI: https://supabase.com/docs/guides/cli
2) Login and link project: supabase login && supabase link --project-ref <ref>
3) Install npm packages using 'npm install'

Quick run (automated)
1. Make the demo script executable (once):
   chmod +x scripts/demo.sh
2. Run the demo script:
   ./scripts/demo.sh

This will:
- start Supabase local stack
- apply the migrations (create tables)
- enable RLS and create policies
- seed sample data
- print jobs and matches (smoke)
- run an RLS check as a non-superuser to prove tenant isolation

Manual steps (if you prefer to run commands yourself)
1. Start Supabase local stack:
   npx supabase start

2. Apply migrations:
   export CONN_STRING="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
   psql "$CONN_STRING" -f migrations/tables/001_create_tables.sql
   psql "$CONN_STRING" -f migrations/rls/001_enable_rls_and_policies.sql

3. Seed data:
   psql "$CONN_STRING" -f seed/seed_data.sql

4. View sample data in terminal (smoke test):
   npm run smoke

5. Demonstrate RLS (explain that superuser bypasses RLS):
   # create test user and run the RLS check as that user
   # Create role if missing (works on more Postgres versions) and grant privileges
   psql "$CONN_STRING" -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'test_recruiter') THEN CREATE ROLE test_recruiter LOGIN PASSWORD 'testpass'; END IF; END \$\$;"
   psql "$CONN_STRING" -c "GRANT CONNECT ON DATABASE postgres TO test_recruiter;"
   psql "$CONN_STRING" -c "GRANT USAGE ON SCHEMA public TO test_recruiter;"
   psql "$CONN_STRING" -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO test_recruiter;"
   psql "$CONN_STRING" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO test_recruiter;"
   CONN_STRING="postgresql://test_recruiter:testpass@127.0.0.1:54322/postgres" npm run rls-test

6. Optional: Open Supabase Studio in a browser to visually inspect tables and rows:
   http://127.0.0.1:54323



Notes & caveats
- The demo script inserts minimal rows into `auth.users` for local testing only. In production, user accounts should be created via Supabase Auth or an admin API.
- Do not expose service keys to client apps; background workers should use secure server credentials.


Notes & assumptions
- JWT must include 'org_id' claim (UUID string) and Supabase auth.uid() will be used for user id checks.
- For production, tighten policies: service roles should use Postgres functions with SECURITY DEFINER and avoid exposing admin keys to clients.
- Storage paths in candidate_files point to Supabase Storage; ensure buckets and permissions are configured.

