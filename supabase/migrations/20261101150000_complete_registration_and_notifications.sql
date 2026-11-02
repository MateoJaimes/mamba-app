alter table public.profiles add column if not exists first_names text not null default '', add column if not exists last_names text not null default '';
create table if not exists public.account_identity (
 user_id uuid primary key references auth.users(id) on delete cascade,
 document_type text not null check(document_type in ('cc','ce','ti','ppt','passport')),
 document_number text not null check(length(document_number) between 4 and 24),
 birth_date date not null,
 phone_number text not null check(length(phone_number) between 7 and 20),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(document_type, document_number)
);
alter table public.account_identity enable row level security;
grant select,insert,update on public.account_identity to authenticated;
create policy account_identity_select_own on public.account_identity for select to authenticated using(user_id=(select auth.uid()));
create policy account_identity_insert_own on public.account_identity for insert to authenticated with check(user_id=(select auth.uid()));
create policy account_identity_update_own on public.account_identity for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create trigger account_identity_set_updated_at before update on public.account_identity for each row execute function private.set_updated_at();

create or replace function private.handle_new_auth_user()
returns trigger language plpgsql security definer set search_path=''
as $$
declare
 first_names_value text := coalesce(nullif(trim(new.raw_user_meta_data->>'first_names'),''),'');
 last_names_value text := coalesce(nullif(trim(new.raw_user_meta_data->>'last_names'),''),'');
 display_name_value text;
 account_intent_value text;
begin
 display_name_value := coalesce(nullif(trim(first_names_value||' '||last_names_value),''),nullif(trim(new.raw_user_meta_data->>'display_name'),''),nullif(split_part(coalesce(new.email,''),'@',1),''),'Viajero MAMBA');
 account_intent_value := case when new.raw_user_meta_data->>'account_intent'='experienceHost' then 'experience_host' else 'tourist' end;
 insert into public.profiles(id,display_name,first_names,last_names,account_intent) values(new.id,display_name_value,first_names_value,last_names_value,account_intent_value)
 on conflict(id) do update set display_name=excluded.display_name,first_names=excluded.first_names,last_names=excluded.last_names,account_intent=excluded.account_intent;
 insert into public.user_roles(user_id,role) values(new.id,'tourist') on conflict(user_id,role) do nothing;
 insert into public.account_identity(user_id,document_type,document_number,birth_date,phone_number)
 values(new.id,coalesce(new.raw_user_meta_data->>'document_type','cc'),regexp_replace(upper(coalesce(new.raw_user_meta_data->>'document_number','')),'[^A-Z0-9]','','g'),(new.raw_user_meta_data->>'birth_date')::date,coalesce(new.raw_user_meta_data->>'phone_number',''))
 on conflict(user_id) do update set document_type=excluded.document_type,document_number=excluded.document_number,birth_date=excluded.birth_date,phone_number=excluded.phone_number;
 if account_intent_value='experience_host' then insert into public.host_applications(user_id,status) values(new.id,'draft') on conflict(user_id) do nothing; end if;
 return new;
end; $$;
revoke all on function private.handle_new_auth_user() from public,anon,authenticated;

create or replace view public.experience_feed with (security_invoker=true) as
select e.id,e.host_profile_id as provider_id,h.display_name as provider,h.handle as provider_handle,e.title,e.short_description,e.description,e.location_label as location,e.category,e.price_amount,e.currency,e.duration_minutes,e.maximum_people as max_people,e.meeting_point,e.latitude,e.longitude,e.includes,e.requirements,e.age_policy,e.minimum_age,e.minors_supervision_required,e.age_policy_note,e.status,e.published_at,
 coalesce((select array_agg(i.image_url order by i.position) from public.experience_images i where i.experience_id=e.id),'{}'::text[]) as images,
 coalesce((select count(*) from public.reviews r where r.experience_id=e.id and r.status='published'),0)::integer as reviews_count,
 (select avg(r.experience_score)::numeric(3,2) from public.reviews r where r.experience_id=e.id and r.status='published') as experience_rating_score,
 (select avg(r.host_score)::numeric(3,2) from public.reviews r where r.host_profile_id=e.host_profile_id and r.status='published') as host_rating_score,
 (select count(*) from public.experience_likes l where l.experience_id=e.id)::integer as likes_count,
 (select count(*) from public.experience_comments c where c.experience_id=e.id)::integer as comments_count,
 exists(select 1 from public.experience_likes l where l.experience_id=e.id and l.user_id=(select auth.uid())) as is_liked_by_me,
 exists(select 1 from public.favorites f where f.experience_id=e.id and f.user_id=(select auth.uid())) as is_saved_by_me
from public.experiences e join public.host_profiles h on h.id=e.host_profile_id where e.status='published' and (e.is_demo or h.approved_at is not null);

create or replace function private.notify_booking_request()
returns trigger language plpgsql security definer set search_path=''
as $$
declare host_owner uuid; experience_title text;
begin
 select h.owner_id,e.title into host_owner,experience_title from public.experiences e join public.host_profiles h on h.id=e.host_profile_id where e.id=new.experience_id;
 insert into public.notifications(user_id,kind,title,body,payload) values(new.user_id,'booking','Solicitud enviada','Tu solicitud para '||coalesce(experience_title,'la experiencia')||' está pendiente de respuesta.',jsonb_build_object('booking_id',new.id,'experience_id',new.experience_id));
 if host_owner is not null and host_owner<>new.user_id then insert into public.notifications(user_id,kind,title,body,payload) values(host_owner,'booking','Nueva solicitud de experiencia','Tienes una nueva solicitud para '||coalesce(experience_title,'una experiencia'),jsonb_build_object('booking_id',new.id,'experience_id',new.experience_id)); end if;
 return new;
end; $$;
revoke all on function private.notify_booking_request() from public,anon,authenticated;
create trigger booking_request_notification after insert on public.bookings for each row execute function private.notify_booking_request();
