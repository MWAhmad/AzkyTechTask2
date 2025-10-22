Project: Recruitment SaaS - Supabase schema as code

What I added
- /migrations/tables/001_create_tables.sql  -- creates core tables
- /migrations/rls/001_enable_rls_and_policies.sql -- enables RLS and policies
- /seed/seed_data.sql -- sample data to validate schema

Suggested workflow (Supabase CLI)
1) Install Supabase CLI: https://supabase.com/docs/guides/cli
2) Login and link project: supabase login && supabase link --project-ref <ref>
3) Apply migrations:
   supabase db push --project-ref <ref>
   (or run psql against your DB to execute .sql files)
4) Seed data:
   psql <CONN_STRING> -f seed/seed_data.sql

Notes & assumptions
- JWT must include 'org_id' claim (UUID string) and Supabase auth.uid() will be used for user id checks.
- For production, tighten policies: service roles should use Postgres functions with SECURITY DEFINER and avoid exposing admin keys to clients.
- Storage paths in candidate_files point to Supabase Storage; ensure buckets and permissions are configured.

90-minute feasibility estimate
- Designing schema + writing migrations & seeds: ~30-45 minutes (completed here).
- Setting up Supabase project, running migrations, testing RLS locally: ~20-30 minutes.
- Implementing AI processing worker, API endpoints, and frontend: additional time beyond 90 minutes.

Quality gates (recommended)
- Run lint/SQL checks (syntax) after applying migrations.
- Smoke test: connect with a test JWT containing org_id and run sample SELECT queries.
- Add unit/integration tests for background worker and access control.

Next steps
- Add Postgres functions for safe background worker operations.
- Add migrations for audit logs, billing, and rate limits.
- Create minimal backend service to ingest files and enqueue AI jobs.
