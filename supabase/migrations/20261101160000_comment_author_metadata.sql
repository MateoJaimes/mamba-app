alter table public.experience_comments
  add column if not exists author_name text,
  add column if not exists author_avatar_url text;

update public.experience_comments c
set author_name = coalesce(p.display_name, 'Viajero MAMBA'),
    author_avatar_url = p.avatar_url
from public.profiles p
where p.id = c.user_id and c.author_name is null;

create or replace function private.prepare_experience_comment()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if new.user_id is distinct from (select auth.uid()) then
    raise exception 'A comment can only be created by the signed-in user';
  end if;
  select p.display_name, p.avatar_url into new.author_name, new.author_avatar_url
  from public.profiles p where p.id = new.user_id;
  if not found then raise exception 'A profile is required before commenting'; end if;
  return new;
end;
$$;
revoke all on function private.prepare_experience_comment() from public, anon, authenticated;
create trigger experience_comments_prepare before insert on public.experience_comments
for each row execute function private.prepare_experience_comment();
comment on column public.experience_comments.author_name is 'Public display name snapshot set by the trusted insert trigger.';
comment on column public.experience_comments.author_avatar_url is 'Public avatar URL snapshot set by the trusted insert trigger.';
