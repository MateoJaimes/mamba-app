begin;
select set_config('request.jwt.claim.sub',(select id::text from auth.users where email='somosmapoapp@gmail.com'),true);
set local role authenticated;
do $$
declare plan public.experiences; payload jsonb; result jsonb;
begin
 if (select count(*) from public.profiles)<>1 then raise exception 'Profile isolation failed';end if;
 if (select count(*) from public.countries)<249 then raise exception 'Country catalog incomplete';end if;
 if (select count(*) from public.cities where country_code='CO')<>1122 then raise exception 'DIVIPOLA catalog incomplete';end if;
 begin
   update public.profiles set country_code='CO',region_code='CO-05',city_code='CO-11001' where id=auth.uid();
   raise exception using errcode='XX000',message='Invalid city was accepted';
 exception when sqlstate 'P0001' then null;
 end;
 select e.* into plan from public.experiences e join public.host_profiles h on h.id=e.host_profile_id where h.owner_id=auth.uid() limit 1;
 payload:=to_jsonb(plan)||jsonb_build_object('categories',jsonb_build_array('Cultura','Arte'),'images',(select jsonb_agg(image_url order by position) from public.experience_images where experience_id=plan.id));
 result:=public.host_action('save_experience',payload);
 if not exists(select 1 from public.experiences where id=plan.id and categories=array['Cultura','Arte']) then raise exception 'Multiple categories were not saved';end if;
 begin
   perform public.host_action('save_experience',payload||'{"categories":["INVALID"]}'::jsonb);
   raise exception using errcode='XX000',message='Unknown category accepted';
 exception when sqlstate 'P0001' then null;
 end;
end $$;
select 'Profile isolation, dependent locations and host multi-category workflow passed' as checks;
rollback;
