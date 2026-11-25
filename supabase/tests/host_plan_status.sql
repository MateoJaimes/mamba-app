begin;
select set_config('request.jwt.claim.sub',(select id::text from auth.users where email='somosmapoapp@gmail.com'),true);
set local role authenticated;
do $$
declare plan public.experiences; payload jsonb; count_before integer;
begin
 select e.* into plan from public.experiences e join public.host_profiles h on h.id=e.host_profile_id where h.owner_id=auth.uid() limit 1;
 if plan.id is null then raise exception 'Missing host fixture';end if;
 payload:=to_jsonb(plan)||jsonb_build_object('categories',to_jsonb(plan.categories),'images',(select jsonb_agg(image_url order by position) from public.experience_images where experience_id=plan.id));
 select count(*) into count_before from public.my_bookings where experience_id=plan.id;
 perform public.host_action('save_experience',payload||'{"status":"paused"}'::jsonb);
 if exists(select 1 from public.experience_feed where id=plan.id) then raise exception 'Paused plan still public';end if;
 perform public.host_action('save_experience',payload||'{"status":"published"}'::jsonb);
 if not exists(select 1 from public.experience_feed where id=plan.id) then raise exception 'Published plan missing';end if;
 perform public.host_action('save_experience',payload||'{"status":"archived"}'::jsonb);
 if exists(select 1 from public.experience_feed where id=plan.id) then raise exception 'Archived plan still public';end if;
 if not exists(select 1 from public.experiences where id=plan.id and status='archived') then raise exception 'Archive removed plan';end if;
 if (select count(*) from public.my_bookings where experience_id=plan.id)<>count_before then raise exception 'History changed';end if;
end $$;
select 'Host publish, pause and archive preserve history; changes rolled back' as checks;
rollback;
