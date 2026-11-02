-- MAMBA initial Supabase schema.
-- Auth is owned by Supabase. Public roles are assigned only by trusted SQL.

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to anon, authenticated;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (length(trim(display_name)) between 1 and 120),
  handle text,
  avatar_url text,
  cover_url text,
  bio text not null default '' check (length(bio) <= 1000),
  city text not null default '',
  country text not null default 'Colombia',
  account_intent text not null default 'tourist'
    check (account_intent in ('tourist', 'experience_host')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index profiles_handle_unique on public.profiles (lower(handle))
  where handle is not null;

create table public.user_roles (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('tourist', 'host', 'admin')),
  granted_at timestamptz not null default now(),
  granted_by uuid references auth.users(id) on delete set null,
  unique (user_id, role)
);

create table public.host_applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'draft'
    check (status in ('draft', 'submitted', 'under_review', 'approved', 'rejected', 'suspended')),
  business_name text,
  city text,
  experience_description text,
  evidence_urls text[] not null default '{}',
  reviewer_notes text,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id)
);

create table public.host_profiles (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid unique references auth.users(id) on delete set null,
  handle text not null,
  display_name text not null,
  bio text not null default '',
  city text not null default '',
  avatar_url text,
  cover_url text,
  approved_at timestamptz,
  is_demo boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (owner_id is null or is_demo = false)
);
create unique index host_profiles_handle_unique on public.host_profiles (lower(handle));
create index host_profiles_owner_idx on public.host_profiles(owner_id) where owner_id is not null;

create table public.experiences (
  id uuid primary key default gen_random_uuid(),
  host_profile_id uuid not null references public.host_profiles(id) on delete restrict,
  title text not null check (length(trim(title)) between 3 and 160),
  slug text not null unique,
  short_description text not null default '' check (length(short_description) <= 500),
  description text not null default '',
  category text not null check (category in ('Aventura', 'Cultura', 'Gastronomía', 'Naturaleza', 'Bienestar', 'Otro')),
  location_label text not null,
  meeting_point text not null,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  duration_minutes integer not null check (duration_minutes between 1 and 10080),
  price_amount numeric(12,2) not null check (price_amount >= 0),
  currency char(3) not null default 'COP' check (currency = 'COP'),
  minimum_people integer not null default 1 check (minimum_people >= 1),
  maximum_people integer not null check (maximum_people >= minimum_people and maximum_people <= 1000),
  age_policy text not null default 'all_ages'
    check (age_policy in ('all_ages', 'minimum_age', 'adults_only')),
  minimum_age integer not null default 0 check (minimum_age between 0 and 100),
  minors_supervision_required boolean not null default true,
  age_policy_note text not null default '',
  includes text not null default '',
  requirements text not null default '',
  instant_booking boolean not null default false,
  status text not null default 'draft' check (status in ('draft', 'published', 'paused', 'archived')),
  is_demo boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((age_policy = 'minimum_age' and minimum_age >= 1) or age_policy <> 'minimum_age')
);
create index experiences_published_order_idx on public.experiences(status, published_at desc);
create index experiences_host_idx on public.experiences(host_profile_id, status);
create index experiences_category_idx on public.experiences(category, published_at desc);
create index experiences_coordinates_idx on public.experiences(latitude, longitude) where status = 'published';

create table public.experience_images (
  id uuid primary key default gen_random_uuid(),
  experience_id uuid not null references public.experiences(id) on delete cascade,
  image_url text not null,
  position integer not null default 0 check (position >= 0),
  created_at timestamptz not null default now(),
  unique (experience_id, position)
);
create index experience_images_experience_idx on public.experience_images(experience_id, position);

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete restrict,
  experience_id uuid not null references public.experiences(id) on delete restrict,
  booking_date date not null,
  adults integer not null check (adults >= 1),
  minors integer not null default 0 check (minors >= 0),
  minors_supervision_confirmed boolean not null default false,
  minimum_age_confirmed boolean not null default false,
  status text not null default 'requested'
    check (status in ('requested', 'accepted', 'rejected', 'cancelled', 'completed')),
  payment_status text not null default 'not_applicable'
    check (payment_status = 'not_applicable'),
  unit_price numeric(12,2) not null default 0 check (unit_price >= 0),
  total_amount numeric(12,2) not null default 0 check (total_amount >= 0),
  currency char(3) not null default 'COP' check (currency = 'COP'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index bookings_user_date_idx on public.bookings(user_id, booking_date desc);
create index bookings_experience_date_idx on public.bookings(experience_id, booking_date, status);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid unique references public.bookings(id) on delete set null,
  reviewer_id uuid references auth.users(id) on delete set null,
  reviewer_name text,
  experience_id uuid not null references public.experiences(id) on delete cascade,
  host_profile_id uuid not null references public.host_profiles(id) on delete cascade,
  experience_score smallint not null check (experience_score between 1 and 5),
  host_score smallint not null check (host_score between 1 and 5),
  comment text not null default '' check (length(comment) <= 2000),
  status text not null default 'published' check (status in ('published', 'hidden')),
  is_demo boolean not null default false,
  created_at timestamptz not null default now(),
  check ((is_demo and reviewer_id is null and reviewer_name is not null and booking_id is null)
      or (not is_demo and reviewer_id is not null and booking_id is not null))
);
create index reviews_experience_idx on public.reviews(experience_id, status, created_at desc);
create index reviews_host_idx on public.reviews(host_profile_id, status, created_at desc);

create table public.experience_likes (
  user_id uuid not null references auth.users(id) on delete cascade,
  experience_id uuid not null references public.experiences(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(user_id, experience_id)
);
create index experience_likes_experience_idx on public.experience_likes(experience_id);

create table public.experience_comments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  experience_id uuid not null references public.experiences(id) on delete cascade,
  body text not null check (length(trim(body)) between 1 and 1000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index experience_comments_experience_idx on public.experience_comments(experience_id, created_at);
create index experience_comments_user_idx on public.experience_comments(user_id);

create table public.favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  experience_id uuid not null references public.experiences(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(user_id, experience_id)
);
create index favorites_experience_idx on public.favorites(experience_id);

create table public.host_follows (
  follower_id uuid not null references auth.users(id) on delete cascade,
  host_profile_id uuid not null references public.host_profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(follower_id, host_profile_id)
);
create index host_follows_host_idx on public.host_follows(host_profile_id);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('booking', 'review', 'follow', 'system')),
  title text not null,
  body text not null default '',
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index notifications_user_created_idx on public.notifications(user_id, created_at desc);
create index host_applications_reviewer_idx on public.host_applications(reviewed_by)
  where reviewed_by is not null;
create index reviews_reviewer_idx on public.reviews(reviewer_id)
  where reviewer_id is not null;
create index user_roles_granted_by_idx on public.user_roles(granted_by)
  where granted_by is not null;

create or replace function private.has_role(p_user_id uuid, p_role text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_user_id = (select auth.uid())
    and exists (
      select 1 from public.user_roles r
      where r.user_id = p_user_id and r.role = p_role
    );
$$;
revoke all on function private.has_role(uuid, text) from public;
grant execute on function private.has_role(uuid, text) to anon, authenticated;

create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  display_name_value text;
  account_intent_value text;
begin
  display_name_value := coalesce(
    nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    'Viajero MAMBA'
  );
  account_intent_value := case
    when new.raw_user_meta_data ->> 'account_intent' = 'experienceHost' then 'experience_host'
    else 'tourist'
  end;

  insert into public.profiles(id, display_name, account_intent)
  values (new.id, display_name_value, account_intent_value)
  on conflict (id) do nothing;

  -- Requesting the host path never grants host permissions.
  insert into public.user_roles(user_id, role)
  values (new.id, 'tourist')
  on conflict (user_id, role) do nothing;

  if account_intent_value = 'experience_host' then
    insert into public.host_applications(user_id, status)
    values (new.id, 'draft')
    on conflict (user_id) do nothing;
  end if;
  return new;
end;
$$;
revoke all on function private.handle_new_auth_user() from public, anon, authenticated;

create trigger profiles_set_updated_at before update on public.profiles
  for each row execute function private.set_updated_at();
create trigger host_applications_set_updated_at before update on public.host_applications
  for each row execute function private.set_updated_at();
create trigger host_profiles_set_updated_at before update on public.host_profiles
  for each row execute function private.set_updated_at();
create trigger experiences_set_updated_at before update on public.experiences
  for each row execute function private.set_updated_at();
create trigger bookings_set_updated_at before update on public.bookings
  for each row execute function private.set_updated_at();
create trigger experience_comments_set_updated_at before update on public.experience_comments
  for each row execute function private.set_updated_at();

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_auth_user();

create or replace function private.prepare_booking()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  exp public.experiences%rowtype;
  occupied integer;
begin
  if new.user_id is distinct from (select auth.uid()) then
    raise exception 'A booking can only be created for the signed-in user';
  end if;
  if new.booking_date < current_date or new.booking_date > current_date + 365 then
    raise exception 'Booking date is outside the allowed range';
  end if;

  select e.* into exp
  from public.experiences e
  join public.host_profiles h on h.id = e.host_profile_id
  where e.id = new.experience_id
    and e.status = 'published'
    and (e.is_demo or h.approved_at is not null)
  for update of e;
  if not found then raise exception 'Experience is not available'; end if;
  if new.adults < 1 or new.minors < 0 or new.adults + new.minors > exp.maximum_people then
    raise exception 'Guest count is outside the allowed range';
  end if;
  if exp.age_policy = 'adults_only' and new.minors > 0 then
    raise exception 'This experience is for adults only';
  end if;
  if exp.age_policy = 'minimum_age' and not new.minimum_age_confirmed then
    raise exception 'Minimum age confirmation is required';
  end if;
  if new.minors > 0 and exp.minors_supervision_required and not new.minors_supervision_confirmed then
    raise exception 'Adult supervision confirmation is required';
  end if;

  select coalesce(sum(b.adults + b.minors), 0)::integer into occupied
  from public.bookings b
  where b.experience_id = new.experience_id
    and b.booking_date = new.booking_date
    and b.status in ('requested', 'accepted');
  if occupied + new.adults + new.minors > exp.maximum_people then
    raise exception 'There are not enough places available for this date';
  end if;

  new.status := 'requested';
  new.payment_status := 'not_applicable';
  new.unit_price := exp.price_amount;
  new.total_amount := exp.price_amount * (new.adults + new.minors);
  new.currency := exp.currency;
  return new;
end;
$$;
revoke all on function private.prepare_booking() from public, anon, authenticated;
create trigger bookings_prepare before insert on public.bookings
  for each row execute function private.prepare_booking();

create or replace function private.prepare_review()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  booking_row public.bookings%rowtype;
begin
  if new.reviewer_id is distinct from (select auth.uid()) then
    raise exception 'A review can only be created by the signed-in user';
  end if;
  select * into booking_row from public.bookings b
  where b.id = new.booking_id and b.user_id = new.reviewer_id;
  if not found or booking_row.status <> 'completed' then
    raise exception 'Only completed bookings can be reviewed';
  end if;
  if booking_row.experience_id <> new.experience_id then
    raise exception 'Review experience does not match the booking';
  end if;
  if not exists (
    select 1 from public.experiences e
    where e.id = booking_row.experience_id
      and e.host_profile_id = new.host_profile_id
  ) then
    raise exception 'Review host does not match the booking';
  end if;
  select p.display_name into new.reviewer_name
  from public.profiles p where p.id = new.reviewer_id;
  new.is_demo := false;
  new.status := 'published';
  return new;
end;
$$;
revoke all on function private.prepare_review() from public, anon, authenticated;
create trigger reviews_prepare before insert on public.reviews
  for each row when (new.is_demo = false)
  execute function private.prepare_review();

alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.host_applications enable row level security;
alter table public.host_profiles enable row level security;
alter table public.experiences enable row level security;
alter table public.experience_images enable row level security;
alter table public.bookings enable row level security;
alter table public.reviews enable row level security;
alter table public.experience_likes enable row level security;
alter table public.experience_comments enable row level security;
alter table public.favorites enable row level security;
alter table public.host_follows enable row level security;
alter table public.notifications enable row level security;

grant select on public.profiles, public.user_roles, public.host_applications to authenticated;
grant update (display_name, handle, avatar_url, cover_url, bio, city, country, account_intent)
  on public.profiles to authenticated;
grant insert (user_id, status) on public.host_applications to authenticated;
grant update (business_name, city, experience_description, evidence_urls)
  on public.host_applications to authenticated;

grant select on public.host_profiles to anon, authenticated;
grant select on public.experiences, public.experience_images to anon, authenticated;
grant insert, update, delete on public.experiences, public.experience_images to authenticated;
grant select on public.bookings to authenticated;
grant insert (user_id, experience_id, booking_date, adults, minors,
  minors_supervision_confirmed, minimum_age_confirmed) on public.bookings to authenticated;
grant select on public.reviews, public.experience_likes, public.experience_comments,
  public.host_follows to anon, authenticated;
grant insert (booking_id, reviewer_id, reviewer_name, experience_id, host_profile_id,
  experience_score, host_score, comment) on public.reviews to authenticated;
grant insert, delete on public.experience_likes, public.host_follows to authenticated;
grant insert (user_id, experience_id, body) on public.experience_comments to authenticated;
grant update (body), delete on public.experience_comments to authenticated;
grant select, insert, delete on public.favorites to authenticated;
grant select on public.notifications to authenticated;
grant update (read_at) on public.notifications to authenticated;

create policy profiles_select_own on public.profiles for select to authenticated
  using (id = (select auth.uid()));
create policy profiles_update_own on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy user_roles_select_own on public.user_roles for select to authenticated
  using (user_id = (select auth.uid()));

create policy host_applications_select_own on public.host_applications for select to authenticated
  using (user_id = (select auth.uid()));
create policy host_applications_insert_draft on public.host_applications for insert to authenticated
  with check (user_id = (select auth.uid()) and status = 'draft');
create policy host_applications_update_draft on public.host_applications for update to authenticated
  using (user_id = (select auth.uid()) and status = 'draft')
  with check (user_id = (select auth.uid()) and status = 'draft');

create policy host_profiles_public_read on public.host_profiles for select to anon, authenticated
  using (is_demo or approved_at is not null);

create policy experiences_public_read on public.experiences for select to anon, authenticated
  using (
    status = 'published'
    and exists (
      select 1 from public.host_profiles h
      where h.id = host_profile_id and (h.is_demo or h.approved_at is not null)
    )
  );
create policy experiences_host_insert on public.experiences for insert to authenticated
  with check (
    not is_demo and private.has_role((select auth.uid()), 'host')
    and exists (select 1 from public.host_profiles h
      where h.id = host_profile_id and h.owner_id = (select auth.uid()) and h.approved_at is not null)
  );
create policy experiences_host_update on public.experiences for update to authenticated
  using (private.has_role((select auth.uid()), 'host') and exists (
    select 1 from public.host_profiles h where h.id = host_profile_id
      and h.owner_id = (select auth.uid()) and h.approved_at is not null
  ))
  with check (not is_demo and private.has_role((select auth.uid()), 'host') and exists (
    select 1 from public.host_profiles h where h.id = host_profile_id
      and h.owner_id = (select auth.uid()) and h.approved_at is not null
  ));
create policy experiences_host_delete on public.experiences for delete to authenticated
  using (private.has_role((select auth.uid()), 'host') and exists (
    select 1 from public.host_profiles h where h.id = host_profile_id
      and h.owner_id = (select auth.uid()) and h.approved_at is not null
  ));

create policy experience_images_public_read on public.experience_images for select to anon, authenticated
  using (exists (select 1 from public.experiences e where e.id = experience_id and e.status = 'published'));
create policy experience_images_host_insert on public.experience_images for insert to authenticated
  with check (exists (select 1 from public.experiences e join public.host_profiles h on h.id=e.host_profile_id
    where e.id = experience_id and h.owner_id=(select auth.uid()) and h.approved_at is not null
      and private.has_role((select auth.uid()), 'host')));
create policy experience_images_host_update on public.experience_images for update to authenticated
  using (exists (select 1 from public.experiences e join public.host_profiles h on h.id=e.host_profile_id
    where e.id=experience_id and h.owner_id=(select auth.uid()) and h.approved_at is not null
      and private.has_role((select auth.uid()), 'host')))
  with check (exists (select 1 from public.experiences e join public.host_profiles h on h.id=e.host_profile_id
    where e.id=experience_id and h.owner_id=(select auth.uid()) and h.approved_at is not null
      and private.has_role((select auth.uid()), 'host')));
create policy experience_images_host_delete on public.experience_images for delete to authenticated
  using (exists (select 1 from public.experiences e join public.host_profiles h on h.id=e.host_profile_id
    where e.id=experience_id and h.owner_id=(select auth.uid()) and h.approved_at is not null
      and private.has_role((select auth.uid()), 'host')));

create policy bookings_select_participant on public.bookings for select to authenticated
  using (user_id = (select auth.uid()) or exists (
    select 1 from public.experiences e join public.host_profiles h on h.id=e.host_profile_id
    where e.id=experience_id and h.owner_id=(select auth.uid())
  ));
create policy bookings_insert_own_request on public.bookings for insert to authenticated
  with check (user_id = (select auth.uid()) and status='requested' and payment_status='not_applicable');

create policy reviews_public_read on public.reviews for select to anon, authenticated
  using (status='published' and (is_demo or booking_id is not null));
create policy reviews_insert_completed_booking on public.reviews for insert to authenticated
  with check (
    not is_demo and reviewer_id=(select auth.uid()) and status='published'
    and exists (select 1 from public.bookings b
      where b.id=booking_id and b.user_id=(select auth.uid()) and b.status='completed'
        and b.experience_id=experience_id)
  );

create policy experience_likes_public_read on public.experience_likes for select to anon, authenticated
  using (exists (select 1 from public.experiences e where e.id=experience_id and e.status='published'));
create policy experience_likes_insert_own on public.experience_likes for insert to authenticated
  with check (user_id=(select auth.uid()));
create policy experience_likes_delete_own on public.experience_likes for delete to authenticated
  using (user_id=(select auth.uid()));

create policy experience_comments_public_read on public.experience_comments for select to anon, authenticated
  using (exists (select 1 from public.experiences e where e.id=experience_id and e.status='published'));
create policy experience_comments_insert_own on public.experience_comments for insert to authenticated
  with check (user_id=(select auth.uid()));
create policy experience_comments_update_own on public.experience_comments for update to authenticated
  using (user_id=(select auth.uid())) with check (user_id=(select auth.uid()));
create policy experience_comments_delete_own on public.experience_comments for delete to authenticated
  using (user_id=(select auth.uid()));

create policy favorites_select_own on public.favorites for select to authenticated
  using (user_id=(select auth.uid()));
create policy favorites_insert_own on public.favorites for insert to authenticated
  with check (user_id=(select auth.uid()));
create policy favorites_delete_own on public.favorites for delete to authenticated
  using (user_id=(select auth.uid()));

create policy host_follows_public_read on public.host_follows for select to anon, authenticated
  using (exists (select 1 from public.host_profiles h where h.id=host_profile_id and (h.is_demo or h.approved_at is not null)));
create policy host_follows_insert_own on public.host_follows for insert to authenticated
  with check (follower_id=(select auth.uid()));
create policy host_follows_delete_own on public.host_follows for delete to authenticated
  using (follower_id=(select auth.uid()));

create policy notifications_select_own on public.notifications for select to authenticated
  using (user_id=(select auth.uid()));
create policy notifications_update_own on public.notifications for update to authenticated
  using (user_id=(select auth.uid())) with check (user_id=(select auth.uid()));

create or replace view public.experience_feed with (security_invoker=true) as
select
  e.id,
  e.host_profile_id as provider_id,
  h.display_name as provider,
  h.handle as provider_handle,
  e.title,
  e.short_description,
  e.description,
  e.location_label as location,
  e.category,
  e.price_amount as price_amount,
  e.currency,
  e.duration_minutes,
  e.maximum_people as max_people,
  e.meeting_point,
  e.latitude,
  e.longitude,
  e.includes,
  e.requirements,
  e.age_policy,
  e.minimum_age,
  e.minors_supervision_required,
  e.age_policy_note,
  e.status,
  e.published_at,
  coalesce((select array_agg(i.image_url order by i.position)
    from public.experience_images i where i.experience_id=e.id), '{}'::text[]) as images,
  coalesce((select count(*) from public.reviews r where r.experience_id=e.id and r.status='published'), 0)::integer as reviews_count,
  (select avg(r.experience_score)::numeric(3,2) from public.reviews r where r.experience_id=e.id and r.status='published') as experience_rating_score,
  (select avg(r.host_score)::numeric(3,2) from public.reviews r where r.host_profile_id=e.host_profile_id and r.status='published') as host_rating_score,
  (select count(*) from public.experience_likes l where l.experience_id=e.id)::integer as likes_count,
  (select count(*) from public.experience_comments c where c.experience_id=e.id)::integer as comments_count
from public.experiences e
join public.host_profiles h on h.id=e.host_profile_id
where e.status='published' and (e.is_demo or h.approved_at is not null);

create or replace view public.host_public_profiles with (security_invoker=true) as
select
  h.id,
  h.display_name as name,
  h.handle,
  h.bio,
  h.city as location,
  h.avatar_url as avatar,
  h.cover_url as cover,
  (h.is_demo or h.approved_at is not null) as verified,
  h.is_demo,
  h.created_at,
  'Desde ' || extract(year from h.created_at)::integer::text as joined,
  coalesce((select count(*) from public.host_follows f where f.host_profile_id=h.id), 0)::integer as followers_count,
  coalesce((select count(*) from public.reviews r where r.host_profile_id=h.id and r.status='published'), 0)::integer as reviews_count,
  (select avg(r.host_score)::numeric(3,2) from public.reviews r where r.host_profile_id=h.id and r.status='published') as host_rating_score
from public.host_profiles h
where h.is_demo or h.approved_at is not null;

create or replace view public.review_feed with (security_invoker=true) as
select r.id, r.host_profile_id, r.experience_id, r.reviewer_name as author,
  e.title as experience, r.created_at, r.experience_score, r.host_score,
  r.comment, r.is_demo
from public.reviews r
join public.experiences e on e.id=r.experience_id
where r.status='published';

create or replace view public.my_bookings with (security_invoker=true) as
select b.id, b.user_id, b.experience_id, e.title as experience_title,
  h.display_name as provider_name, h.id as provider_id, e.location_label as location,
  b.booking_date as date, b.adults, b.minors, b.adults+b.minors as guests,
  b.status, b.payment_status, b.unit_price, b.total_amount, b.currency,
  (select i.image_url from public.experience_images i where i.experience_id=e.id order by i.position limit 1) as image,
  b.created_at
from public.bookings b
join public.experiences e on e.id=b.experience_id
join public.host_profiles h on h.id=e.host_profile_id;

grant select on public.experience_feed, public.host_public_profiles, public.review_feed to anon, authenticated;
grant select on public.my_bookings to authenticated;

insert into public.host_profiles(id, handle, display_name, bio, city, avatar_url, cover_url, is_demo)
values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa13', '@guiasdela13', 'Guías de la 13',
   'Historias, arte urbano y cultura local contadas por quienes vivimos la Comuna 13. ¡Vení a parchar con nosotros!',
   'Medellín, Antioquia', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=300',
   'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=1200', true),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa14', '@origencafe', 'Origen Café',
   'Café de origen, historias de finca y experiencias para disfrutar sin afán. Del grano a la taza.',
   'El Poblado, Medellín', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=300',
   'https://images.unsplash.com/photo-1445116572660-236099ec97a0?w=1200', true),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa15', '@rutasdeantioquia', 'Rutas de Antioquia',
   'Montaña, naturaleza y caminos para volver a respirar. Guías locales y grupos pequeños.',
   'Envigado, Antioquia', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300',
   'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1200', true)
on conflict (id) do nothing;

insert into public.experiences(
  id, host_profile_id, title, slug, short_description, description, category,
  location_label, meeting_point, latitude, longitude, duration_minutes,
  price_amount, minimum_people, maximum_people, age_policy, minimum_age,
  minors_supervision_required, age_policy_note, includes, requirements,
  status, is_demo, published_at
)
values
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb013', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa13',
   'Explora la Comuna 13', 'demo-explora-la-comuna-13',
   'Arte urbano, cultura e historias de Medellín.',
   'Descubre la historia, cultura y arte urbano de uno de los lugares más representativos de Medellín.',
   'Cultura', 'Comuna 13, Medellín', 'Escaleras eléctricas de la Comuna 13',
   6.2557, -75.6173, 180, 85000, 1, 10, 'all_ages', 0, true,
   'Menores de 18 años pueden asistir acompañados por una persona adulta responsable.',
   'Guía local, recorrido de arte urbano y una bebida tradicional.',
   'Usa zapatos cómodos, protector solar y trae muchas ganas de conocer.', 'published', true, now()),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb014', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa14',
   'Café de especialidad', 'demo-cafe-de-especialidad',
   'Conoce el proceso detrás de un excelente café.',
   'Conoce el proceso detrás de un excelente café y disfruta una experiencia auténtica en Medellín.',
   'Gastronomía', 'El Poblado, Medellín', 'Café Origen, El Poblado',
   6.2088, -75.5679, 120, 65000, 1, 8, 'minimum_age', 12, true,
   'Desde los 12 años. Menores de 18 años deben asistir con una persona adulta responsable.',
   'Cata guiada de tres cafés y método de preparación.', 'No necesitas experiencia previa con café.',
   'published', true, now()),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb015', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa15',
   'Senderismo en las montañas', 'demo-senderismo-en-las-montanas',
   'Paisajes naturales y caminos locales alrededor del Valle de Aburrá.',
   'Una experiencia al aire libre para descubrir los paisajes naturales que rodean el Valle de Aburrá.',
   'Aventura', 'Envigado, Antioquia', 'Parque principal de Envigado',
   6.1711, -75.5871, 300, 95000, 1, 8, 'adults_only', 18, false,
   'Esta ruta es solo para personas mayores de 18 años.',
   'Guía local, hidratación y pausa para disfrutar el paisaje.', 'Lleva ropa cómoda, agua y calzado para caminar.',
   'published', true, now())
on conflict (id) do nothing;

insert into public.experience_images(experience_id, image_url, position)
values
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb013', 'https://images.unsplash.com/photo-1583531352515-888e8f7b3c7c', 0),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb013', 'https://images.unsplash.com/photo-1533105079780-92b9be482077', 1),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb013', 'https://images.unsplash.com/photo-1519501025264-65ba15a82390', 2),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb014', 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085', 0),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb014', 'https://images.unsplash.com/photo-1447933601403-0c6688de566e', 1),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb015', 'https://images.unsplash.com/photo-1551632811-561732d1e306', 0)
on conflict (experience_id, position) do nothing;

insert into public.reviews(
  id, reviewer_name, experience_id, host_profile_id, experience_score, host_score, comment, is_demo
)
values
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc01', 'Valentina R.', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb013', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa13', 5, 5,
   'Se nota el amor por el barrio. La pasamos buenísimo y aprendimos un montón.', true),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc02', 'Andrés M.', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb013', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa13', 4, 4,
   'Un recorrido cercano, respetuoso y lleno de historias que no conocíamos.', true),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc03', 'Camila P.', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb014', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa14', 4, 5,
   'Aprendí a reconocer sabores y el anfitrión hizo todo muy fácil y divertido.', true),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc04', 'Juan D.', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb014', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa14', 4, 3,
   'Un plan tranquilo, buen café y una explicación muy completa.', true),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc05', 'Sofía G.', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb015', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa15', 3, 4,
   'El guía estuvo pendiente del grupo y nos llevó por unos paisajes increíbles.', true),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc06', 'Mateo C.', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb015', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa15', 3, 3,
   'Buena organización y recomendaciones útiles para disfrutar la caminata.', true)
on conflict (id) do nothing;

comment on table public.user_roles is 'Trusted access roles. Never grant client-side insert, update, or delete.';
comment on table public.host_applications is 'A host request does not grant the host role. Approval must be performed by trusted staff.';
comment on table public.bookings is 'A request only; payments are intentionally not implemented.';
