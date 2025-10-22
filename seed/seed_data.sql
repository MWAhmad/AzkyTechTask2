-- Seed data for recruitment SaaS
-- Create an organization and sample users, job, candidates, and matches
-- Insert minimal auth.users rows so profile FK constraints succeed in local dev.
-- NOTE: In production use Supabase Auth signup flows instead of direct inserts.
insert into auth.users (id, email, is_sso_user, is_anonymous, created_at)
values
  ('22222222-2222-2222-2222-222222222222', 'alice@acme.com', false, false, now()),
  ('33333333-3333-3333-3333-333333333333', 'bob@acme.com', false, false, now())
on conflict (id) do nothing;

insert into organizations (id, name, slug, plan, created_at)
values
  ('11111111-1111-1111-1111-111111111111', 'Acme Recruiting', 'acme', 'starter', now())
on conflict (id) do nothing;

-- Sample profiles (IDs should match auth.users in Supabase if linking)
insert into profiles (id, org_id, email, full_name, role, created_at)
values
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'alice@acme.com', 'Alice Admin', 'owner', now()),
  ('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'bob@acme.com', 'Bob Recruiter', 'member', now())
on conflict (id) do nothing;

-- Sample job
insert into jobs (id, org_id, created_by, title, description, requirements, location, is_active, created_at)
values (
  '44444444-4444-4444-4444-444444444444',
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  'Senior Backend Engineer',
  'We are looking for a Senior Backend Engineer with Postgres and Python experience.',
  jsonb_build_object('must_have', array['Python','Postgres','APIs'], 'nice_to_have', array['AI','Docker']),
  'Remote', true, now()
)
on conflict (id) do nothing;

-- Second organization for visualization
insert into organizations (id, name, slug, plan, created_at)
values
  ('22222222-1111-2222-1111-222222222222', 'Beta Recruiting', 'beta', 'starter', now())
on conflict (id) do nothing;

-- Profiles for second org
insert into auth.users (id, email, is_sso_user, is_anonymous, created_at)
values
  ('44444444-4444-4444-4444-444444444444', 'carol@beta.com', false, false, now()),
  ('55555555-5555-5555-5555-555555555555', 'dan@beta.com', false, false, now())
on conflict (id) do nothing;

insert into profiles (id, org_id, email, full_name, role, created_at)
values
  ('44444444-4444-4444-4444-444444444444', '22222222-1111-2222-1111-222222222222', 'carol@beta.com', 'Carol Beta', 'owner', now()),
  ('55555555-5555-5555-5555-555555555555', '22222222-1111-2222-1111-222222222222', 'dan Beta', 'Dan Beta', 'member', now())
on conflict (id) do nothing;

-- Sample job for second org
insert into jobs (id, org_id, created_by, title, description, requirements, location, is_active, created_at)
values (
  '66666666-6666-6666-6666-666666666666',
  '22222222-1111-2222-1111-222222222222',
  '44444444-4444-4444-4444-444444444444',
  'Frontend Engineer',
  'Looking for a skilled frontend developer experienced in React.',
  jsonb_build_object('must_have', array['JavaScript','React'], 'nice_to_have', array['TypeScript','Design']),
  'Remote', true, now()
)
on conflict (id) do nothing;

-- Candidate and match for second org
insert into candidate_profiles (id, org_id, name, email, phone, summary, skills, experience, education, parsed_at, created_at)
values
  ('77777777-7777-7777-7777-777777777777', '22222222-1111-2222-1111-222222222222', 'Eve Front', 'eve@example.com', '+1000000000', 'Frontend specialist', array['JavaScript','React','CSS'], jsonb_build_object('years',4), jsonb_build_object('degree','BSc'), now(), now())
on conflict (id) do nothing;

insert into candidate_files (id, org_id, candidate_id, storage_path, file_name, content_type, size, uploaded_by, uploaded_at)
values
  ('88888888-8888-8888-8888-888888888888', '22222222-1111-2222-1111-222222222222', '77777777-7777-7777-7777-777777777777', 'cv/beta/77777777.pdf', 'eve_cv.pdf', 'application/pdf', 90000, '55555555-5555-5555-5555-555555555555', now())
on conflict (id) do nothing;

insert into ai_jobs (id, org_id, job_id, status, progress, meta, created_at)
values ('99999999-aaaa-9999-aaaa-999999999999', '22222222-1111-2222-1111-222222222222', '66666666-6666-6666-6666-666666666666', 'completed', 100, jsonb_build_object('model','gpt-sim','notes','seed run'), now())
on conflict (id) do nothing;

insert into matches (id, org_id, job_id, candidate_id, ai_job_id, score, recommendation, reasoning, created_at)
values
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '22222222-1111-2222-1111-222222222222', '66666666-6666-6666-6666-666666666666', '77777777-7777-7777-7777-777777777777', '99999999-aaaa-9999-aaaa-999999999999', 88.25, 'Good frontend skills: React and JS.', jsonb_build_object('skill_overlap', array['React','JavaScript']), now())
on conflict (id) do nothing;

-- Candidate profiles
insert into candidate_profiles (id, org_id, name, email, phone, summary, skills, experience, education, parsed_at, created_at)
values
  ('55555555-5555-5555-5555-555555555555', '11111111-1111-1111-1111-111111111111', 'Carol Dev', 'carol@example.com', '+1234567890', 'Experienced backend dev', array['Python','Postgres','Django'], jsonb_build_object('years',5), jsonb_build_object('degree','BSc Computer Science'), now(), now()),
  ('66666666-6666-6666-6666-666666666666', '11111111-1111-1111-1111-111111111111', 'Dan Intern', 'dan@example.com', '+1987654321', 'Junior dev', array['Python','Flask'], jsonb_build_object('years',1), jsonb_build_object('degree','BSc'), now(), now())
on conflict (id) do nothing;

-- Candidate files (storage_path is example)
insert into candidate_files (id, org_id, candidate_id, storage_path, file_name, content_type, size, uploaded_by, uploaded_at)
values
  ('77777777-7777-7777-7777-777777777777', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 'cv/acme/55555555.pdf', 'carol_cv.pdf', 'application/pdf', 102400, '33333333-3333-3333-3333-333333333333', now()),
  ('88888888-8888-8888-8888-888888888888', '11111111-1111-1111-1111-111111111111', '66666666-6666-6666-6666-666666666666', 'cv/acme/66666666.pdf', 'dan_cv.pdf', 'application/pdf', 51200, '33333333-3333-3333-3333-333333333333', now())
on conflict (id) do nothing;

-- AI job
insert into ai_jobs (id, org_id, job_id, status, progress, meta, created_at)
values ('99999999-9999-9999-9999-999999999999', '11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'completed', 100, jsonb_build_object('model','gpt-sim','notes','seed run'), now())
on conflict (id) do nothing;

-- Matches
insert into matches (id, org_id, job_id, candidate_id, ai_job_id, score, recommendation, reasoning, created_at)
values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', '55555555-5555-5555-5555-555555555555', '99999999-9999-9999-9999-999999999999', 92.50, 'Strong match: 5 years backend experience and Postgres skills.', jsonb_build_object('skill_overlap', array['Python','Postgres']), now()),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', '66666666-6666-6666-6666-666666666666', '99999999-9999-9999-9999-999999999999', 56.75, 'Partial match: junior level, may need mentoring.', jsonb_build_object('skill_overlap', array['Python']), now())
on conflict (id) do nothing;
