create or replace function private.is_experience_saved(p_experience_id uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select (select auth.uid()) is not null and exists (select 1 from public.favorites f where f.experience_id=p_experience_id and f.user_id=(select auth.uid()));
$$;
revoke all on function private.is_experience_saved(uuid) from public;
grant execute on function private.is_experience_saved(uuid) to anon,authenticated;
create or replace view public.experience_feed with (security_invoker=true) as
select e.id,e.host_profile_id as provider_id,h.display_name as provider,h.handle as provider_handle,e.title,e.short_description,e.description,e.location_label as location,e.category,e.price_amount,e.currency,e.duration_minutes,e.maximum_people as max_people,e.meeting_point,e.latitude,e.longitude,e.includes,e.requirements,e.age_policy,e.minimum_age,e.minors_supervision_required,e.age_policy_note,e.status,e.published_at,
 coalesce((select array_agg(i.image_url order by i.position) from public.experience_images i where i.experience_id=e.id),'{}'::text[]) as images,
 coalesce((select count(*) from public.reviews r where r.experience_id=e.id and r.status='published'),0)::integer as reviews_count,
 (select avg(r.experience_score)::numeric(3,2) from public.reviews r where r.experience_id=e.id and r.status='published') as experience_rating_score,
 (select avg(r.host_score)::numeric(3,2) from public.reviews r where r.host_profile_id=e.host_profile_id and r.status='published') as host_rating_score,
 (select count(*) from public.experience_likes l where l.experience_id=e.id)::integer as likes_count,
 (select count(*) from public.experience_comments c where c.experience_id=e.id)::integer as comments_count,
 exists(select 1 from public.experience_likes l where l.experience_id=e.id and l.user_id=(select auth.uid())) as is_liked_by_me,
 private.is_experience_saved(e.id) as is_saved_by_me
from public.experiences e join public.host_profiles h on h.id=e.host_profile_id where e.status='published' and (e.is_demo or h.approved_at is not null);
