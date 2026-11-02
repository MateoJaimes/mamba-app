create index if not exists experience_comments_user_idx on public.experience_comments(user_id);
create index if not exists favorites_experience_idx on public.favorites(experience_id);
create index if not exists host_applications_reviewer_idx on public.host_applications(reviewed_by) where reviewed_by is not null;
create index if not exists reviews_reviewer_idx on public.reviews(reviewer_id) where reviewer_id is not null;
create index if not exists user_roles_granted_by_idx on public.user_roles(granted_by) where granted_by is not null;

create or replace view public.host_public_profiles with (security_invoker=true) as
select h.id, h.display_name as name, h.handle, h.bio, h.city as location,
  h.avatar_url as avatar, h.cover_url as cover,
  (h.is_demo or h.approved_at is not null) as verified, h.is_demo, h.created_at,
  'Desde ' || extract(year from h.created_at)::integer::text as joined,
  coalesce((select count(*) from public.host_follows f where f.host_profile_id=h.id), 0)::integer as followers_count,
  coalesce((select count(*) from public.reviews r where r.host_profile_id=h.id and r.status='published'), 0)::integer as reviews_count,
  (select avg(r.host_score)::numeric(3,2) from public.reviews r where r.host_profile_id=h.id and r.status='published') as host_rating_score
from public.host_profiles h where h.is_demo or h.approved_at is not null;
