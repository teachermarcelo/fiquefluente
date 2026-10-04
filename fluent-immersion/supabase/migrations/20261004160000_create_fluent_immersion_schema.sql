create schema if not exists fluent_immersion;

create table if not exists fluent_immersion.languages (
 id uuid primary key default gen_random_uuid(), code text unique not null check (code in ('en','es')),
 name text not null, native_name text not null, active boolean not null default true, created_at timestamptz not null default now()
);
create table if not exists fluent_immersion.cefr_levels (
 id uuid primary key default gen_random_uuid(), code text unique not null check (code in ('A0','A1','A2','B1','B2','C1','C2')),
 name text not null, description text, sort_order int not null, created_at timestamptz not null default now()
);
create table if not exists fluent_immersion.courses (
 id uuid primary key default gen_random_uuid(), language_id uuid not null references fluent_immersion.languages(id) on delete cascade,
 level_id uuid not null references fluent_immersion.cefr_levels(id) on delete restrict, title text not null, description text, cover_url text,
 active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(language_id, level_id)
);
create table if not exists fluent_immersion.units (
 id uuid primary key default gen_random_uuid(), course_id uuid not null references fluent_immersion.courses(id) on delete cascade,
 title text not null, description text, position int not null default 1, created_at timestamptz not null default now(),
 unique(course_id, position)
);
create table if not exists fluent_immersion.lessons (
 id uuid primary key default gen_random_uuid(), unit_id uuid not null references fluent_immersion.units(id) on delete cascade,
 title text not null, description text, skill text not null check (skill in ('reading','writing','listening','speaking','grammar','vocabulary','mixed')),
 duration_minutes int default 15, position int not null default 1, published boolean not null default false,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(unit_id, position)
);
create table if not exists fluent_immersion.content (
 id uuid primary key default gen_random_uuid(), lesson_id uuid not null references fluent_immersion.lessons(id) on delete cascade,
 type text not null check (type in ('text','video','audio','image','pdf','link')), title text, body text, media_url text,
 transcript text, metadata jsonb not null default '{}'::jsonb, position int not null default 1, created_at timestamptz not null default now()
);
create table if not exists fluent_immersion.exercises (
 id uuid primary key default gen_random_uuid(), lesson_id uuid not null references fluent_immersion.lessons(id) on delete cascade,
 title text not null, instructions text, exercise_type text not null check (exercise_type in ('multiple_choice','true_false','fill_blank','matching','ordering','drag_drop','listening','reading','writing','speaking','mixed')),
 xp int not null default 10, position int not null default 1, published boolean not null default false, created_at timestamptz not null default now()
);
create table if not exists fluent_immersion.exercise_items (
 id uuid primary key default gen_random_uuid(), exercise_id uuid not null references fluent_immersion.exercises(id) on delete cascade,
 prompt text not null, options jsonb not null default '[]'::jsonb, answer jsonb, explanation text, media_url text, position int not null default 1, created_at timestamptz not null default now()
);
create table if not exists fluent_immersion.user_profiles (
 user_id uuid primary key references auth.users(id) on delete cascade, display_name text, avatar_url text,
 current_language text check (current_language in ('en','es')), current_level text check (current_level in ('A0','A1','A2','B1','B2','C1','C2')),
 xp int not null default 0, streak_days int not null default 0, last_study_date date, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists fluent_immersion.progress (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 lesson_id uuid not null references fluent_immersion.lessons(id) on delete cascade, completion_percent int not null default 0 check (completion_percent between 0 and 100),
 score_percent numeric(5,2), last_position text, completed_at timestamptz, updated_at timestamptz not null default now(), unique(user_id, lesson_id)
);
create table if not exists fluent_immersion.attempts (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 exercise_id uuid not null references fluent_immersion.exercises(id) on delete cascade, score_percent numeric(5,2) not null default 0,
 correct_count int not null default 0, total_count int not null default 0, answers jsonb not null default '{}'::jsonb, xp_earned int not null default 0,
 started_at timestamptz, completed_at timestamptz not null default now()
);

create index if not exists idx_fi_courses_language_level on fluent_immersion.courses(language_id, level_id);
create index if not exists idx_fi_units_course on fluent_immersion.units(course_id);
create index if not exists idx_fi_lessons_unit_skill on fluent_immersion.lessons(unit_id, skill);
create index if not exists idx_fi_content_lesson on fluent_immersion.content(lesson_id);
create index if not exists idx_fi_exercises_lesson on fluent_immersion.exercises(lesson_id);
create index if not exists idx_fi_items_exercise on fluent_immersion.exercise_items(exercise_id);
create index if not exists idx_fi_progress_user on fluent_immersion.progress(user_id);
create index if not exists idx_fi_attempts_user on fluent_immersion.attempts(user_id);

alter table fluent_immersion.languages enable row level security;
alter table fluent_immersion.cefr_levels enable row level security;
alter table fluent_immersion.courses enable row level security;
alter table fluent_immersion.units enable row level security;
alter table fluent_immersion.lessons enable row level security;
alter table fluent_immersion.content enable row level security;
alter table fluent_immersion.exercises enable row level security;
alter table fluent_immersion.exercise_items enable row level security;
alter table fluent_immersion.user_profiles enable row level security;
alter table fluent_immersion.progress enable row level security;
alter table fluent_immersion.attempts enable row level security;

drop policy if exists "fi_public_read_languages" on fluent_immersion.languages;
create policy "fi_public_read_languages" on fluent_immersion.languages for select to anon, authenticated using (active = true);
drop policy if exists "fi_public_read_levels" on fluent_immersion.cefr_levels;
create policy "fi_public_read_levels" on fluent_immersion.cefr_levels for select to anon, authenticated using (true);
drop policy if exists "fi_public_read_courses" on fluent_immersion.courses;
create policy "fi_public_read_courses" on fluent_immersion.courses for select to anon, authenticated using (active = true);
drop policy if exists "fi_public_read_units" on fluent_immersion.units;
create policy "fi_public_read_units" on fluent_immersion.units for select to anon, authenticated using (exists (select 1 from fluent_immersion.courses c where c.id = course_id and c.active = true));
drop policy if exists "fi_public_read_lessons" on fluent_immersion.lessons;
create policy "fi_public_read_lessons" on fluent_immersion.lessons for select to anon, authenticated using (published = true);
drop policy if exists "fi_public_read_content" on fluent_immersion.content;
create policy "fi_public_read_content" on fluent_immersion.content for select to anon, authenticated using (exists (select 1 from fluent_immersion.lessons l where l.id = lesson_id and l.published = true));
drop policy if exists "fi_public_read_exercises" on fluent_immersion.exercises;
create policy "fi_public_read_exercises" on fluent_immersion.exercises for select to anon, authenticated using (published = true);
drop policy if exists "fi_public_read_items" on fluent_immersion.exercise_items;
create policy "fi_public_read_items" on fluent_immersion.exercise_items for select to anon, authenticated using (exists (select 1 from fluent_immersion.exercises e where e.id = exercise_id and e.published = true));

drop policy if exists "fi_profile_select_own" on fluent_immersion.user_profiles;
create policy "fi_profile_select_own" on fluent_immersion.user_profiles for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "fi_profile_insert_own" on fluent_immersion.user_profiles;
create policy "fi_profile_insert_own" on fluent_immersion.user_profiles for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "fi_profile_update_own" on fluent_immersion.user_profiles;
create policy "fi_profile_update_own" on fluent_immersion.user_profiles for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists "fi_progress_own" on fluent_immersion.progress;
create policy "fi_progress_own" on fluent_immersion.progress for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "fi_progress_insert_own" on fluent_immersion.progress;
create policy "fi_progress_insert_own" on fluent_immersion.progress for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "fi_progress_update_own" on fluent_immersion.progress;
create policy "fi_progress_update_own" on fluent_immersion.progress for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists "fi_attempts_own" on fluent_immersion.attempts;
create policy "fi_attempts_own" on fluent_immersion.attempts for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "fi_attempts_insert_own" on fluent_immersion.attempts;
create policy "fi_attempts_insert_own" on fluent_immersion.attempts for insert to authenticated with check ((select auth.uid()) = user_id);

grant usage on schema fluent_immersion to anon, authenticated;
grant select on all tables in schema fluent_immersion to anon, authenticated;
grant insert, update on fluent_immersion.user_profiles, fluent_immersion.progress to authenticated;
grant insert on fluent_immersion.attempts to authenticated;

insert into fluent_immersion.languages(code,name,native_name) values
('en','English','English'),('es','Spanish','Español') on conflict (code) do nothing;
insert into fluent_immersion.cefr_levels(code,name,description,sort_order) values
('A0','Starter','Primeiros contatos com o idioma.',0),('A1','Beginner','Comunicação básica do cotidiano.',1),
('A2','Elementary','Situações familiares e comunicação simples.',2),('B1','Intermediate','Comunicação independente em situações comuns.',3),
('B2','Upper-Intermediate','Comunicação fluente e argumentação.',4),('C1','Advanced','Uso avançado, preciso e flexível.',5),
('C2','Proficient','Domínio próximo ao nível de proficiência.',6) on conflict (code) do nothing;