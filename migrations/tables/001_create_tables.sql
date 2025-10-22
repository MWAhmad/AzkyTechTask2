-- Migration: create core tables for multi-tenant recruitment SaaS
-- Assumptions:
--  - Supabase Postgres with JWT claims providing 'org_id' and 'role'
--  - 'public.users' managed by Supabase Auth; we keep a profiles table linked to auth.users

create table if not exists organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  plan text not null default 'starter',
  created_at timestamptz not null default now()
);

create table if not exists profiles (
  id uuid references auth.users(id) on delete cascade,
  org_id uuid not null references organizations(id) on delete cascade,
  email text not null,
  full_name text,
  role text not null default 'member', -- member, admin, owner
  created_at timestamptz not null default now(),
  primary key (id)
);

-- Jobs posted by organizations
create table if not exists jobs (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references organizations(id) on delete cascade,
  created_by uuid references profiles(id) on delete set null,
  title text not null,
  description text,
  requirements jsonb,
  location text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Candidate profiles (extracted metadata about CVs)
create table if not exists candidate_profiles (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references organizations(id) on delete cascade,
  name text,
  email text,
  phone text,
  summary text,
  skills text[],
  experience jsonb,
  education jsonb,
  parsed_at timestamptz,
  created_at timestamptz not null default now()
);

-- Candidate file blobs / references (actual uploaded CVs)
create table if not exists candidate_files (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references organizations(id) on delete cascade,
  candidate_id uuid references candidate_profiles(id) on delete cascade,
  storage_path text not null, -- path in Supabase Storage
  file_name text,
  content_type text,
  size bigint,
  uploaded_by uuid references profiles(id) on delete set null,
  uploaded_at timestamptz not null default now()
);

-- AI processing jobs for bulk CV processing
create table if not exists ai_jobs (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references organizations(id) on delete cascade,
  job_id uuid references jobs(id) on delete cascade,
  status text not null default 'pending', -- pending, running, completed, failed
  progress int default 0,
  meta jsonb,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

-- Matches: candidate -> job with AI score and recommendation
create table if not exists matches (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references organizations(id) on delete cascade,
  job_id uuid not null references jobs(id) on delete cascade,
  candidate_id uuid not null references candidate_profiles(id) on delete cascade,
  ai_job_id uuid references ai_jobs(id) on delete set null,
  score numeric(5,2) not null default 0, -- 0.00 - 100.00
  recommendation text,
  reasoning jsonb,
  created_at timestamptz not null default now()
);

-- Indexes to improve common queries
create index if not exists idx_jobs_org on jobs(org_id);
create index if not exists idx_candidates_org on candidate_profiles(org_id);
create index if not exists idx_matches_job on matches(job_id);
create index if not exists idx_matches_candidate on matches(candidate_id);
