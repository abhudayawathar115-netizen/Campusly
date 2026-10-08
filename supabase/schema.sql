-- Campusly starter schema. Run in the Supabase SQL editor before connecting the UI.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '', email text not null default '',
  role text not null default 'student' check (role in ('student','teacher')),
  department text default '', semester integer, section text default '', profile_image text,
  created_at timestamptz not null default now()
);
create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(), title text not null, content text not null,
  teacher_id uuid references public.profiles(id) on delete set null,
  priority text not null default 'Normal' check(priority in ('Normal','Important')),
  target_section text not null default 'Everyone', created_at timestamptz not null default now()
);
create table if not exists public.assignments (
  id uuid primary key default gen_random_uuid(), title text not null, description text not null default '',
  subject text not null, teacher_id uuid references public.profiles(id) on delete set null,
  due_date timestamptz not null, created_at timestamptz not null default now()
);
create table if not exists public.submissions (
  id uuid primary key default gen_random_uuid(), assignment_id uuid not null references public.assignments(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade, file_url text,
  status text not null default 'Submitted', submitted_at timestamptz not null default now(),
  unique(assignment_id,student_id)
);
create table if not exists public.schedule (
  id uuid primary key default gen_random_uuid(), subject text not null,
  teacher_id uuid references public.profiles(id) on delete set null, room text not null default '',
  start_time time not null, end_time time not null, date date not null,
  section text not null default 'Everyone', created_at timestamptz not null default now()
);
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(), sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  subject text not null default '', message text not null, created_at timestamptz not null default now()
);
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null, message text not null default '', is_read boolean not null default false,
  created_at timestamptz not null default now()
);
create or replace function public.current_user_role() returns text
language sql stable security definer set search_path=public
as $$ select role from public.profiles where id=auth.uid() $$;
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path=public
as $$ begin
  -- Public sign-up always creates a student. Have an administrator promote faculty accounts.
  insert into public.profiles(id,name,email,role)
  values(new.id,coalesce(new.raw_user_meta_data->>'name',''),new.email,'student') on conflict(id) do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();
alter table public.profiles enable row level security;
alter table public.announcements enable row level security;
alter table public.assignments enable row level security;
alter table public.submissions enable row level security;
alter table public.schedule enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;
create policy "Campus members read profiles" on public.profiles for select to authenticated using(true);
create policy "Users update own profile" on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
create policy "Campus members read announcements" on public.announcements for select to authenticated using(true);
create policy "Teachers publish announcements" on public.announcements for insert to authenticated with check(public.current_user_role()='teacher' and teacher_id=auth.uid());
create policy "Teachers update announcements" on public.announcements for update to authenticated using(teacher_id=auth.uid()) with check(teacher_id=auth.uid());
create policy "Campus members read assignments" on public.assignments for select to authenticated using(true);
create policy "Teachers publish assignments" on public.assignments for insert to authenticated with check(public.current_user_role()='teacher' and teacher_id=auth.uid());
create policy "Teachers update assignments" on public.assignments for update to authenticated using(teacher_id=auth.uid()) with check(teacher_id=auth.uid());
create policy "Read own submissions or teacher submissions" on public.submissions for select to authenticated using(student_id=auth.uid() or public.current_user_role()='teacher');
create policy "Students create own submissions" on public.submissions for insert to authenticated with check(student_id=auth.uid() and public.current_user_role()='student');
create policy "Students update own submissions" on public.submissions for update to authenticated using(student_id=auth.uid()) with check(student_id=auth.uid());
create policy "Campus members read schedule" on public.schedule for select to authenticated using(true);
create policy "Teachers manage schedule" on public.schedule for all to authenticated using(public.current_user_role()='teacher') with check(public.current_user_role()='teacher');
create policy "Participants read messages" on public.messages for select to authenticated using(sender_id=auth.uid() or receiver_id=auth.uid());
create policy "Send own messages" on public.messages for insert to authenticated with check(sender_id=auth.uid());
create policy "Read own notifications" on public.notifications for select to authenticated using(user_id=auth.uid());
create policy "Update own notifications" on public.notifications for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
grant usage on schema public to authenticated;
grant select,update on public.profiles to authenticated;
grant select,insert,update on public.announcements,public.assignments to authenticated;
grant select,insert,update on public.submissions to authenticated;
grant select,insert,update,delete on public.schedule to authenticated;
grant select,insert on public.messages to authenticated;
grant select,update on public.notifications to authenticated;
-- Before enabling uploads, create a private `submissions` Storage bucket and restrict object paths
-- to auth.uid(). Configure Email (or campus SSO) in Supabase Auth settings.
