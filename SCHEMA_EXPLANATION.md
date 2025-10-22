Schema design and RLS explanation — Recruitment SaaS

Purpose
-------
This document explains the database schema choices and the Row-Level Security (RLS) rules used in the demo. Use this text as part of your README or verbatim in your recorded explanation for the proctor.

High-level goals
-----------------
- Multi-tenant SaaS: data for multiple customer organizations (tenants) co-exists in the same database but must be strictly isolated.
- Keep metadata in Postgres and large files (CVs) in object storage.
- Enforce tenant isolation and least-privilege access via RLS so policy is enforced at the DB-level.

Top-level schema (files)
-------------------------
- migrations/tables/001_create_tables.sql — table definitions and indexes.
- migrations/rls/001_enable_rls_and_policies.sql — enables RLS and creates policies.
- seed/seed_data.sql — sample data to demonstrate behavior.

Key tables and reasons for their design
--------------------------------------
- organizations
  - id (uuid pk), name, slug, plan, created_at
  - Purpose: tenant container. Every tenant-scoped row references organizations.id.

- profiles
  - id references auth.users(id), org_id, email, full_name, role
  - Purpose: stores application user metadata. We keep a separate profiles table so auth.users remains managed by Supabase Auth, and application-specific fields (role, org_id) live in profiles.
  - Security: policies allow a user to access their own profile (auth.uid() = id) and org admins to access other profiles in the same org.

- jobs
  - id, org_id, created_by (profiles.id), title, description, requirements (jsonb), is_active
  - Purpose: job postings belonging to an organization. org_id ensures jobs are tenant-scoped.

- candidate_profiles
  - id, org_id, name, email, skills array, parsed_at, experience/education (jsonb)
  - Purpose: extracted metadata from CVs — searchable and joinable for matching, without storing the full file in the DB.

- candidate_files
  - id, org_id, candidate_id, storage_path, file_name, uploaded_by, uploaded_at
  - Purpose: stores a reference to the file stored in Supabase Storage (object storage). Keeps DB small and fast.

- ai_jobs
  - id, org_id, job_id, status, progress, meta, created_at
  - Purpose: records processing runs (bulk CV parsing or matching) so you can track background work and associate matches with a job run.

- matches
  - id, org_id, job_id, candidate_id, ai_job_id, score (numeric), recommendation, reasoning (jsonb)
  - Purpose: the AI result linking a candidate to a job with a score and human-readable recommendation.

Indexes
-------
- Indexes on org_id, job_id, and candidate_id are added because common queries filter by org and job (e.g., list matches for a job or candidates in an org).

RLS and security design
------------------------
1) Core idea: every tenant-scoped table contains an `org_id` column. RLS policies compare the `org_id` value on the row to the `org_id` claim in the user's JWT.

2) How policies read claims:
   - Supabase exposes `auth.jwt()` in SQL to access parsed JWT claims.
   - Policies use `(auth.jwt() ->> 'org_id')::uuid = org_id` to ensure the current request's org_id matches the row.

3) Why we use JWT claims and a separate DB role:
   - RLS is evaluated by Postgres for each SQL operation. Policies can read session/GUC values; Supabase sets `request.jwt.claims` from the JWT for each request.
   - In demos/tests we simulate JWTs by setting `request.jwt.claims` with `SET LOCAL` inside a transaction. The helper `auth.jwt()` then returns those values for policy evaluation.
   - Postgres superusers bypass RLS. For demonstration we create a non-superuser `test_recruiter` role and run the RLS test as that role so RLS actually takes effect.

4) Profile access exception:
   - The `profiles` table has a policy that allows a user to read their own profile by matching `auth.uid()` to `profiles.id`. This supports per-user ownership checks (e.g., editing a profile).

Assumptions and tradeoffs
-------------------------
- Assumes external auth issues JWTs containing an `org_id` claim (stringified UUID). This is practical for multi-tenant apps where users belong to one organization.
- We do not require `sub` to be validated against `profiles` for jobs/matches reads. That keeps recruiter workflows simple (any authenticated user in the org can query jobs/matches). If you want stricter controls, add clauses checking `auth.jwt() ->> 'sub' = profiles.id` for sensitive operations.
- Storing files in object storage keeps the DB fast. Use signed URLs for secure downloads in production.

Demo queries and speaking points (copy-paste for recording)
---------------------------------------------------------
- Show tables and data (smoke): `npm run smoke` — prints `jobs` and `matches` table rows.
- Demonstrate RLS enforcement:
  - Connect as non-superuser and simulate JWT for seeded org:
    ```sql
    BEGIN;
    SET LOCAL request.jwt.claims = '{"sub":"33333333-...,","org_id":"11111111-..."}';
    SELECT * FROM jobs; -- should show rows for org 1111...
    ROLLBACK;
    ```
  - Simulate different org:
    ```sql
    BEGIN;
    SET LOCAL request.jwt.claims = '{"sub":"deadbeef-...,","org_id":"aaaaaaaa-..."}';
    SELECT * FROM jobs; -- should return 0 rows
    ROLLBACK;
    ```


Appendix — Common policy examples
---------------------------------
1) Basic org-level select policy (example):

   CREATE POLICY org_select ON jobs
   FOR SELECT USING ((auth.jwt() ->> 'org_id')::uuid = org_id);

2) Profile ownership read (example):

   CREATE POLICY profiles_ownership ON profiles
   FOR ALL
   USING ((auth.jwt() ->> 'org_id')::uuid = org_id OR auth.uid()::uuid = id)
   WITH CHECK ((auth.jwt() ->> 'org_id')::uuid = org_id);
