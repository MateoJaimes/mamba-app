insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('user-media','user-media',false,4194304,array['image/webp','image/jpeg','image/png']) on conflict(id) do update set public = false;
drop policy if exists media_insert_own on storage.objects;
create policy media_insert_own on storage.objects for insert to authenticated with check(bucket_id='user-media' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists media_select_own on storage.objects;
create policy media_select_own on storage.objects for select to authenticated using(bucket_id='user-media' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists media_delete_own on storage.objects;
create policy media_delete_own on storage.objects for delete to authenticated using(bucket_id='user-media' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists media_update_own on storage.objects;
create policy media_update_own on storage.objects for update to authenticated using(bucket_id='user-media' and (storage.foldername(name))[1]=(select auth.uid())::text) with check(bucket_id='user-media' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists media_read_published_plan on storage.objects;
create policy media_read_published_plan on storage.objects for select to authenticated
using (
  bucket_id = 'user-media' and exists (
    select 1
      from public.experience_images i
      join public.experiences e on e.id = i.experience_id
      join public.host_profiles h on h.id = e.host_profile_id
     where e.status = 'published'
       and (e.is_demo or h.approved_at is not null)
       and h.owner_id::text = (storage.foldername(storage.objects.name))[1]
       and split_part(i.image_url, '/storage/v1/object/authenticated/user-media/', 2) = storage.objects.name
  )
);
