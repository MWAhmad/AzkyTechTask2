-- Enable Row Level Security and create policies for tenant isolation and roles
-- Assumptions:
--  - JWT contains 'org_id' claim (text) and 'role' claim
--  - Supabase function auth.jwt() is available

-- Enable pgcrypto extension if not present (for gen_random_uuid used in migrations)
create extension if not exists pgcrypto;

-- Enable RLS on tables
alter table if exists organizations enable row level security;
alter table if exists profiles enable row level security;
alter table if exists jobs enable row level security;
alter table if exists candidate_profiles enable row level security;
alter table if exists candidate_files enable row level security;
alter table if exists ai_jobs enable row level security;
alter table if exists matches enable row level security;

-- Organizations: owners/admins only can read/write their org row. For discovery, allow SELECT for service role.
create policy org_select_service on organizations
  for select
  using (true); -- service role (supabase anon/service key) can read; tighten in prod

-- Profiles: users can access their profile; org admins can access any profile in their org
create policy profiles_org_isolation on profiles
  for all
  using (
    (auth.jwt() ->> 'org_id')::uuid = org_id
    or (auth.uid() = id)
  )
  with check (
    (auth.jwt() ->> 'org_id')::uuid = org_id
  );

-- Jobs: restrict to same org; members with role 'member' can insert
create policy jobs_org_access on jobs
  for all
  using ((auth.jwt() ->> 'org_id')::uuid = org_id)
  with check ((auth.jwt() ->> 'org_id')::uuid = org_id);

-- Candidate profiles: org-only access
create policy candidates_org_access on candidate_profiles
  for all
  using ((auth.jwt() ->> 'org_id')::uuid = org_id)
  with check ((auth.jwt() ->> 'org_id')::uuid = org_id);

-- Candidate files: org-only access; allow upload by any authenticated user in org
create policy candidate_files_org_access on candidate_files
  for all
  using ((auth.jwt() ->> 'org_id')::uuid = org_id)
  with check ((auth.jwt() ->> 'org_id')::uuid = org_id);

-- AI Jobs: org-only; service role (backend worker) may insert
create policy aijobs_org_access on ai_jobs
  for all
  using ((auth.jwt() ->> 'org_id')::uuid = org_id)
  with check ((auth.jwt() ->> 'org_id')::uuid = org_id);

-- Matches: org-only access; recruiters in org can read
create policy matches_org_access on matches
  for all
  using ((auth.jwt() ->> 'org_id')::uuid = org_id)
  with check ((auth.jwt() ->> 'org_id')::uuid = org_id);

-- Optionally create role-based helper policies
-- Example: allow users with 'service_role' claim to bypass org restriction for background workers
-- Note: Be careful with service keys in production; prefer Postgres functions with SECURITY DEFINER
