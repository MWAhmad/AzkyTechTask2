Demo instructions — Recruitment SaaS DB (Supabase)

Goal: Quickly demonstrate migrations, seed data, and RLS enforcement for the proctor.

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
   psql "$CONN_STRING" -c "CREATE ROLE IF NOT EXISTS test_recruiter LOGIN PASSWORD 'testpass'; GRANT CONNECT ON DATABASE postgres TO test_recruiter; GRANT USAGE ON SCHEMA public TO test_recruiter; GRANT SELECT ON ALL TABLES IN SCHEMA public TO test_recruiter;"
   CONN_STRING="postgresql://test_recruiter:testpass@127.0.0.1:54322/postgres" npm run rls-test

6. Optional: Open Supabase Studio in a browser to visually inspect tables and rows:
   http://127.0.0.1:54323

Suggested short narration for recording (30–60s)
- "I'll show the database we designed as code using Supabase. First I start the local Supabase stack."
- "Next I apply migrations which create organizations, users (profiles), jobs, candidate profiles, uploaded CV references, AI jobs, and matches."
- "I then seed example data and run a smoke test to show the job and AI-match results."
- "Finally, I'll demonstrate row-level security: when a user from a different organization queries the jobs, they see no rows — tenant isolation is enforced at the DB level."

Notes & caveats
- The demo script inserts minimal rows into `auth.users` for local testing only. In production, user accounts should be created via Supabase Auth or an admin API.
- Do not expose service keys to client apps; background workers should use secure server credentials.
