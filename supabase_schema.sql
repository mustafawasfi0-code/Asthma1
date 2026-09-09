-- AsthmaCare final Supabase schema
-- Safe to run more than once in the Supabase SQL Editor.

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default 'New User' check (length(trim(name)) between 1 and 100),
  city text not null default 'Baghdad',
  age smallint not null default 18 check (age between 1 and 120),
  sex text not null default 'Male' check (sex in ('Male', 'Female')),
  height_cm numeric(5,2) not null default 170 check (height_cm between 50 and 250),
  personal_best_pef integer check (personal_best_pef between 1 and 1000),
  doctor_name text,
  doctor_phone text,
  role text not null default 'patient' check (role in ('patient', 'clinician', 'admin')),
  triggers text[] default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.peak_flow_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  reading integer not null check (reading between 1 and 1000),
  measured_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.symptom_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  symptoms text[] not null default '{}',
  severity smallint not null check (severity between 0 and 10),
  notes text,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.trigger_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  triggers text[] not null default '{}',
  notes text,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.medication_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  medication_type text not null check (length(trim(medication_type)) between 1 and 120),
  dosage text not null check (length(trim(dosage)) between 1 and 120),
  notes text,
  taken_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, medication_type, dosage, taken_at)
);

create table if not exists public.reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (length(trim(title)) between 1 and 120),
  time_of_day time not null,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, title, time_of_day)
);

create table if not exists public.community_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (length(trim(body)) between 1 and 2000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists peak_flow_user_date_idx on public.peak_flow_logs (user_id, measured_at desc);
create index if not exists symptoms_user_date_idx on public.symptom_logs (user_id, occurred_at desc);
create index if not exists triggers_user_date_idx on public.trigger_logs (user_id, occurred_at desc);
create index if not exists medications_user_date_idx on public.medication_logs (user_id, taken_at desc);
create index if not exists reminders_user_idx on public.reminders (user_id);
create index if not exists community_created_idx on public.community_posts (created_at desc);

-- Keep updated_at correct on every update.
do $$
declare table_name text;
begin
  foreach table_name in array array[
    'profiles', 'peak_flow_logs', 'symptom_logs', 'trigger_logs',
    'medication_logs', 'reminders', 'community_posts'
  ] loop
    execute format('drop trigger if exists set_%I_updated_at on public.%I', table_name, table_name);
    execute format(
      'create trigger set_%I_updated_at before update on public.%I for each row execute function public.set_updated_at()',
      table_name, table_name
    );
    execute format('alter table public.%I enable row level security', table_name);
  end loop;
end;
$$;

-- Drop policies first so this script is idempotent.
drop policy if exists "profiles own select" on public.profiles;
drop policy if exists "profiles own insert" on public.profiles;
drop policy if exists "profiles own update" on public.profiles;
drop policy if exists "profiles own delete" on public.profiles;
create policy "profiles own select" on public.profiles for select to authenticated using ((select auth.uid()) = id);
create policy "profiles own insert" on public.profiles for insert to authenticated with check ((select auth.uid()) = id and role = 'patient');
create policy "profiles own update" on public.profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id and role = 'patient');
create policy "profiles own delete" on public.profiles for delete to authenticated using ((select auth.uid()) = id);

-- Private health tables: a user can only access rows carrying their own user_id.
do $$
declare table_name text;
begin
  foreach table_name in array array[
    'peak_flow_logs', 'symptom_logs', 'trigger_logs', 'medication_logs', 'reminders'
  ] loop
    execute format('drop policy if exists %I on public.%I', table_name || '_select', table_name);
    execute format('drop policy if exists %I on public.%I', table_name || '_insert', table_name);
    execute format('drop policy if exists %I on public.%I', table_name || '_update', table_name);
    execute format('drop policy if exists %I on public.%I', table_name || '_delete', table_name);
    execute format('create policy %I on public.%I for select to authenticated using ((select auth.uid()) = user_id)', table_name || '_select', table_name);
    execute format('create policy %I on public.%I for insert to authenticated with check ((select auth.uid()) = user_id)', table_name || '_insert', table_name);
    execute format('create policy %I on public.%I for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id)', table_name || '_update', table_name);
    execute format('create policy %I on public.%I for delete to authenticated using ((select auth.uid()) = user_id)', table_name || '_delete', table_name);
  end loop;
end;
$$;

-- Community posts are readable by signed-in users, but editable only by their author.
drop policy if exists community_posts_select on public.community_posts;
drop policy if exists community_posts_insert on public.community_posts;
drop policy if exists community_posts_update on public.community_posts;
drop policy if exists community_posts_delete on public.community_posts;
create policy community_posts_select on public.community_posts for select to authenticated using (true);
create policy community_posts_insert on public.community_posts for insert to authenticated with check ((select auth.uid()) = user_id);
create policy community_posts_update on public.community_posts for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy community_posts_delete on public.community_posts for delete to authenticated using ((select auth.uid()) = user_id);

-- Automatically provision a patient profile for normal or anonymous Auth users.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
 insert into public.profiles (id, name, city, age, sex, height_cm, role)
values (
  new.id,
  coalesce(nullif(trim(new.raw_user_meta_data ->> 'name'), ''), 'New User'),
  'Baghdad', 18, 'Male', 170, 'patient'
)
on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.peak_flow_logs to authenticated;
grant select, insert, update, delete on public.symptom_logs to authenticated;
grant select, insert, update, delete on public.trigger_logs to authenticated;
grant select, insert, update, delete on public.medication_logs to authenticated;
grant select, insert, update, delete on public.reminders to authenticated;
grant select, insert, update, delete on public.community_posts to authenticated;

-- Medication onboarding and emergency contacts
create table if not exists public.medications (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name_ar text not null,
  name_en text not null,
  description_ar text not null,
  description_en text not null,
  medication_type text not null check (medication_type in ('emergency', 'preventer')),
  instructions_ar text not null,
  instructions_en text not null,
  warning_ar text,
  warning_en text,
  image_path text not null default '',
  sort_order integer not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_medications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  medication_id uuid not null references public.medications(id) on delete cascade,
  selected_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, medication_id)
);

create table if not exists public.emergency_contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  contact_name text not null check (length(trim(contact_name)) between 1 and 120),
  relationship text not null check (length(trim(relationship)) between 1 and 60),
  phone_number text not null check (
    phone_number ~ '^07[0-9]{9}$' or
    phone_number ~ '^\+[1-9][0-9]{7,14}$'
  ),
  is_primary boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists user_medications_user_id_idx
  on public.user_medications(user_id);
create index if not exists user_medications_medication_id_idx
  on public.user_medications(medication_id);
create index if not exists emergency_contacts_user_id_idx
  on public.emergency_contacts(user_id);
create index if not exists medications_type_sort_idx
  on public.medications(medication_type, sort_order);

drop trigger if exists set_medications_updated_at on public.medications;
create trigger set_medications_updated_at
before update on public.medications
for each row execute function public.set_updated_at();

drop trigger if exists set_emergency_contacts_updated_at on public.emergency_contacts;
create trigger set_emergency_contacts_updated_at
before update on public.emergency_contacts
for each row execute function public.set_updated_at();

alter table public.medications enable row level security;
alter table public.user_medications enable row level security;
alter table public.emergency_contacts enable row level security;

drop policy if exists medications_authenticated_select on public.medications;
create policy medications_authenticated_select
on public.medications for select to authenticated using (true);

drop policy if exists user_medications_select on public.user_medications;
drop policy if exists user_medications_insert on public.user_medications;
drop policy if exists user_medications_update on public.user_medications;
drop policy if exists user_medications_delete on public.user_medications;
create policy user_medications_select on public.user_medications
for select to authenticated using ((select auth.uid()) = user_id);
create policy user_medications_insert on public.user_medications
for insert to authenticated with check ((select auth.uid()) = user_id);
create policy user_medications_update on public.user_medications
for update to authenticated using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
create policy user_medications_delete on public.user_medications
for delete to authenticated using ((select auth.uid()) = user_id);

drop policy if exists emergency_contacts_select on public.emergency_contacts;
drop policy if exists emergency_contacts_insert on public.emergency_contacts;
drop policy if exists emergency_contacts_update on public.emergency_contacts;
drop policy if exists emergency_contacts_delete on public.emergency_contacts;
create policy emergency_contacts_select on public.emergency_contacts
for select to authenticated using ((select auth.uid()) = user_id);
create policy emergency_contacts_insert on public.emergency_contacts
for insert to authenticated with check ((select auth.uid()) = user_id);
create policy emergency_contacts_update on public.emergency_contacts
for update to authenticated using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
create policy emergency_contacts_delete on public.emergency_contacts
for delete to authenticated using ((select auth.uid()) = user_id);

grant select on public.medications to authenticated;
grant select, insert, update, delete on public.user_medications to authenticated;
grant select, insert, update, delete on public.emergency_contacts to authenticated;

insert into public.medications
(code, name_ar, name_en, description_ar, description_en, medication_type,
 instructions_ar, instructions_en, warning_ar, warning_en, image_path, sort_order)
values
('ventolin', 'فينتولين / بوتالين / سامالير', 'Ventolin / Butalin / Samaler', 'بخاخ منقذ (أزرق)', 'Rescue inhaler (blue)', 'emergency',
 'يستخدم هذا الدواء عند الحاجة فقط.', 'Use this medicine only when needed.',
 'لا يوجد جدول زمني ثابت لهذا الدواء. يُستخدم عند الشعور بالأعراض أو قبل ممارسة الرياضة حسب تعليمات الطبيب.', 'There is no fixed schedule. Use it when symptoms occur or before exercise as directed by your doctor.', 'assets/images/medications/ventolin.png', 1),
('clenil', 'كلينيل / بيكلوميثازون', 'Clenil / Beclometasone', 'بخاخ وقائي (بني)', 'Preventer inhaler (brown)', 'preventer',
 'يُستخدم يومياً حسب وصف الطبيب للسيطرة على التهاب مجاري التنفس.', 'Use daily as prescribed to control airway inflammation.',
 'تمضمض بعد الاستخدام ولا توقفه دون استشارة الطبيب.', 'Rinse your mouth after use and do not stop without medical advice.', 'assets/images/medications/clenil.png', 2),
('symbicort', 'سيمبيكورت تيربوهيلر', 'Symbicort Turbuhaler', 'مسحوق جاف (أبيض/أحمر)', 'Dry powder inhaler (white/red)', 'preventer',
 'استخدم الجرعة الموصوفة بانتظام وبطريقة الاستنشاق الصحيحة.', 'Use the prescribed dose regularly with correct inhalation technique.',
 'تمضمض بعد كل جرعة.', 'Rinse your mouth after each dose.', 'assets/images/medications/symbicort.png', 3),
('seretide', 'سيريتايد ديسكاس', 'Seretide Diskus', 'مسحوق جاف (أرجواني)', 'Dry powder inhaler (purple)', 'preventer',
 'يُستخدم بانتظام صباحاً ومساءً حسب الخطة العلاجية.', 'Use regularly morning and evening according to your plan.',
 'ليس بديلاً عن بخاخ الإنقاذ أثناء النوبة الحادة.', 'It does not replace a rescue inhaler during an acute attack.', 'assets/images/medications/seretide.png', 4),
('foster', 'فوستر / فوستير', 'Foster / Fostair', 'بخاخ مركب', 'Combination inhaler', 'preventer',
 'استخدمه حسب الجدول الذي حدده الطبيب.', 'Use according to the schedule set by your doctor.',
 'لا تغيّر الجرعة دون مراجعة الطبيب.', 'Do not change the dose without consulting your doctor.', 'assets/images/medications/foster.png', 5),
('montelukast', 'مونتيلوكاست', 'Montelukast', 'أقراص وقائية', 'Preventer tablets', 'preventer',
 'يؤخذ مرة يومياً حسب وصف الطبيب.', 'Take once daily as prescribed.',
 'أبلغ الطبيب عند ظهور تغيرات غير معتادة في المزاج أو النوم.', 'Tell your doctor about unusual mood or sleep changes.', 'assets/images/medications/montelukast.png', 6),
('prednisolone', 'بريدنيزولون', 'Prednisolone', 'أقراص للحالات الحادة', 'Tablets for acute flare-ups', 'emergency',
 'يُستخدم فقط للمدة والجرعة التي يحددها الطبيب.', 'Use only for the dose and duration prescribed by your doctor.',
 'لا تبدأه أو توقفه من نفسك.', 'Do not start or stop it without medical advice.', 'assets/images/medications/prednisolone.png', 7),
('ipratropium', 'إبراتروبيوم / أتروفنت', 'Ipratropium / Atrovent', 'بخاخ موسع للشعب', 'Bronchodilator inhaler', 'emergency',
 'يُستخدم حسب تعليمات الطبيب عند ضيق التنفس.', 'Use as directed for breathing difficulty.',
 'تجنب وصول الرذاذ إلى العينين.', 'Avoid spraying into the eyes.', 'assets/images/medications/ipratropium.png', 8),
 ('salres', 'سالريس', 'Salres', 'بخاخ منقذ (أزرق)', 'Rescue inhaler (blue)', 'emergency',
 'يستخدم هذا الدواء عند الحاجة فقط.', 'Use this medicine only when needed.',
 'لا يوجد جدول زمني ثابت لهذا الدواء. يُستخدم عند الشعور بالأعراض أو قبل ممارسة الرياضة حسب تعليمات الطبيب.', 'There is no fixed schedule. Use it when symptoms occur or before exercise as directed by your doctor.', 'assets/images/medications/salres.jpg', 9),
('brontio', 'برونتيو', 'Brontio', 'كبسولات استنشاق - موسّع قصبي طويل المفعول', 'Inhalation capsules - long-acting bronchodilator', 'preventer',
 'تُستخدم كبسولة واحدة يومياً عبر جهاز الاستنشاق المرفق حسب وصف الطبيب.', 'Use one capsule daily through the supplied inhalation device as prescribed.',
 'لا تبتلع الكبسولة؛ فهي للاستنشاق فقط.', 'Do not swallow the capsule; it is for inhalation only.', 'assets/images/medications/brontio.jpg', 10),
('respiramol', 'ريسبيرامول', 'Respiramol', 'كبسولات استنشاق مركبة (بوديزونيد + فورموتيرول)', 'Combination inhalation capsules (Budesonide + Formoterol)', 'preventer',
 'تُستخدم بانتظام حسب الجرعة والجدول الذي حدده الطبيب.', 'Use regularly at the dose and schedule set by your doctor.',
 'تمضمض بعد الاستخدام ولا توقفه دون استشارة الطبيب.', 'Rinse your mouth after use and do not stop without medical advice.', 'assets/images/medications/respiramol.jpg', 11),
('pralas', 'برالاس', 'Pralas', 'بخاخ موسّع للشعب الهوائية (مركب)', 'Combination bronchodilator inhaler', 'emergency',
 'يُستخدم حسب تعليمات الطبيب عند ضيق التنفس.', 'Use as directed for breathing difficulty.',
 'تجنب وصول الرذاذ إلى العينين.', 'Avoid spraying into the eyes.', 'assets/images/medications/pralas.jpg', 12),
('pulmoton', 'بولموتون', 'Pulmoton', 'مسحوق استنشاق مركب (Elpenhaler)', 'Combination inhalation powder (Elpenhaler)', 'preventer',
 'يُستخدم بانتظام حسب الجرعة الموصوفة.', 'Use regularly at the prescribed dose.',
 'تمضمض بعد كل جرعة.', 'Rinse your mouth after each dose.', 'assets/images/medications/pulmoton.jpg', 13),
('rolenium', 'رولينيوم', 'Rolenium', 'مسحوق استنشاق مركب (Elpenhaler)', 'Combination inhalation powder (Elpenhaler)', 'preventer',
 'يُستخدم بانتظام صباحاً ومساءً حسب الخطة العلاجية.', 'Use regularly morning and evening according to your plan.',
 'ليس بديلاً عن بخاخ الإنقاذ أثناء النوبة الحادة.', 'It does not replace a rescue inhaler during an acute attack.', 'assets/images/medications/rolenium.jpg', 14),
('airtide', 'إيرتايد', 'Airtide', 'كبسولات استنشاق مركبة جاهزة الجرعة', 'Pre-metered combination inhalation capsules', 'preventer',
 'تُستخدم بانتظام حسب الجرعة الموصوفة.', 'Use regularly at the prescribed dose.',
 'تمضمض بعد كل جرعة.', 'Rinse your mouth after each dose.', 'assets/images/medications/airtide.jpg', 15),
('foracort', 'فوراكورت', 'Foracort', 'بخاخ مركب بعداد جرعات', 'Combination inhaler with dose counter', 'preventer',
 'استخدم الجرعة الموصوفة بانتظام وبطريقة الاستنشاق الصحيحة.', 'Use the prescribed dose regularly with correct inhalation technique.',
 'تحقق من عداد الجرعات قبل كل استخدام.', 'Check the dose counter before each use.', 'assets/images/medications/foracort.jpg', 16),
('pulmicort', 'بولميكورت', 'Pulmicort', 'مسحوق جاف توربوهيلر', 'Dry powder inhaler (Turbuhaler)', 'preventer',
 'يُستخدم يومياً حسب وصف الطبيب للسيطرة على التهاب مجاري التنفس.', 'Use daily as prescribed to control airway inflammation.',
 'تمضمض بعد الاستخدام ولا توقفه دون استشارة الطبيب.', 'Rinse your mouth after use and do not stop without medical advice.', 'assets/images/medications/pulmicort.jpg', 17),
('fobumix', 'فوبوميكس', 'Fubumix', 'مسحوق جاف Easyhaler مركب', 'Combination dry powder inhaler (Easyhaler)', 'preventer',
 'تُستخدم بانتظام حسب الجرعة الموصوفة.', 'Use regularly at the prescribed dose.',
 'رجّ الجهاز جيداً قبل كل استخدام.', 'Shake the device well before each use.', 'assets/images/medications/fobumix.jpg', 18)
on conflict (code) do update set
  name_ar = excluded.name_ar,
  name_en = excluded.name_en,
  description_ar = excluded.description_ar,
  description_en = excluded.description_en,
  medication_type = excluded.medication_type,
  instructions_ar = excluded.instructions_ar,
  instructions_en = excluded.instructions_en,
  warning_ar = excluded.warning_ar,
  warning_en = excluded.warning_en,
  image_path = excluded.image_path,
  sort_order = excluded.sort_order,
  updated_at = now();


-- Monitoring v2: three-reading PEF sessions
-- Safe to run repeatedly. Existing legacy rows remain valid because the new fields are nullable.
alter table public.peak_flow_logs
  add column if not exists reading_1 integer,
  add column if not exists reading_2 integer,
  add column if not exists reading_3 integer,
  add column if not exists highest_reading integer,
  add column if not exists personal_best_at_measurement integer,
  add column if not exists zone text;

-- PostgreSQL has no ADD CONSTRAINT IF NOT EXISTS syntax, so each named
-- constraint is guarded through pg_constraint for safe repeated execution.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.peak_flow_logs'::regclass
      and conname = 'peak_flow_logs_reading_1_range_check'
  ) then
    alter table public.peak_flow_logs
      add constraint peak_flow_logs_reading_1_range_check
      check (reading_1 is null or reading_1 between 1 and 1000);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.peak_flow_logs'::regclass
      and conname = 'peak_flow_logs_reading_2_range_check'
  ) then
    alter table public.peak_flow_logs
      add constraint peak_flow_logs_reading_2_range_check
      check (reading_2 is null or reading_2 between 1 and 1000);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.peak_flow_logs'::regclass
      and conname = 'peak_flow_logs_reading_3_range_check'
  ) then
    alter table public.peak_flow_logs
      add constraint peak_flow_logs_reading_3_range_check
      check (reading_3 is null or reading_3 between 1 and 1000);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.peak_flow_logs'::regclass
      and conname = 'peak_flow_logs_highest_reading_range_check'
  ) then
    alter table public.peak_flow_logs
      add constraint peak_flow_logs_highest_reading_range_check
      check (highest_reading is null or highest_reading between 1 and 1000);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.peak_flow_logs'::regclass
      and conname = 'peak_flow_logs_personal_best_snapshot_range_check'
  ) then
    alter table public.peak_flow_logs
      add constraint peak_flow_logs_personal_best_snapshot_range_check
      check (
        personal_best_at_measurement is null
        or personal_best_at_measurement between 1 and 1000
      );
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.peak_flow_logs'::regclass
      and conname = 'peak_flow_logs_zone_check'
  ) then
    alter table public.peak_flow_logs
      add constraint peak_flow_logs_zone_check
      check (zone is null or zone in ('green', 'yellow', 'red', 'unavailable'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.peak_flow_logs'::regclass
      and conname = 'peak_flow_logs_three_readings_check'
  ) then
    alter table public.peak_flow_logs
      add constraint peak_flow_logs_three_readings_check
      check (
        (
          reading_1 is null
          and reading_2 is null
          and reading_3 is null
          and highest_reading is null
        )
        or
        (
          reading_1 is not null
          and reading_2 is not null
          and reading_3 is not null
          and highest_reading = greatest(reading_1, reading_2, reading_3)
        )
      );
  end if;
end
$$;

create index if not exists peak_flow_user_highest_idx
  on public.peak_flow_logs (user_id, highest_reading desc)
  where highest_reading is not null;

