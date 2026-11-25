-- Host workflows: public RPCs use invoker rights; privileged implementations
-- stay in the unexposed private schema and validate the caller on every call.
create policy experiences_owner_read on public.experiences for select to authenticated
using (exists (select 1 from public.host_profiles h where h.id=host_profile_id and h.owner_id=(select auth.uid())));
create policy images_owner_read on public.experience_images for select to authenticated
using (exists (select 1 from public.experiences e join public.host_profiles h on h.id=e.host_profile_id where e.id=experience_id and h.owner_id=(select auth.uid())));
create policy host_owner_read on public.host_profiles for select to authenticated using(owner_id=(select auth.uid()));

create function private.host_action(action text, payload jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare
 actor uuid := auth.uid(); app public.host_applications; host public.host_profiles;
 exp public.experiences; booking public.bookings; target uuid; result jsonb;
 next_status text; image text; pos integer := 0;
begin
 if actor is null then raise exception 'Inicia sesión'; end if;
 if action='submit_application' then
   if length(trim(coalesce(payload->>'business_name','')))<3 or length(trim(coalesce(payload->>'city','')))<2
      or length(trim(coalesce(payload->>'experience_description','')))<30 then
     raise exception 'Completa nombre, ciudad y una descripción de al menos 30 caracteres'; end if;
   insert into public.host_applications(user_id) values(actor) on conflict(user_id) do nothing;
   select * into app from public.host_applications where user_id=actor for update;
   if app.status not in ('draft','rejected') then raise exception 'La solicitud ya fue enviada'; end if;
   update public.host_applications set business_name=trim(payload->>'business_name'), city=trim(payload->>'city'),
     experience_description=trim(payload->>'experience_description'),status='submitted',reviewer_notes=null,
     reviewed_by=null,reviewed_at=null where user_id=actor returning to_jsonb(host_applications.*) into result;
   update public.profiles set account_intent='experience_host' where id=actor;
   return result;
 elsif action='review_application' then
   if not private.has_role(actor,'admin') then raise exception 'Acceso solo para administración'; end if;
   target := (payload->>'user_id')::uuid;
   next_status := payload->>'status';
   select * into app from public.host_applications where user_id=target for update;
   if not found then raise exception 'Solicitud no encontrada'; end if;
   if next_status not in ('approved','rejected','suspended') then raise exception 'Estado inválido'; end if;
   if next_status='approved' and app.status not in ('submitted','under_review','suspended') then raise exception 'Solicitud no revisable'; end if;
   if next_status='rejected' and app.status not in ('submitted','under_review') then raise exception 'Solicitud no revisable'; end if;
   if next_status='suspended' and app.status<>'approved' then raise exception 'Solo se puede suspender un anfitrión aprobado'; end if;
   update public.host_applications set status=next_status,reviewer_notes=left(payload->>'notes',2000),reviewed_by=actor,reviewed_at=now() where user_id=target;
   if next_status='approved' then
     insert into public.user_roles(user_id,role,granted_by) values(target,'host',actor) on conflict(user_id,role) do nothing;
     insert into public.host_profiles(owner_id,handle,display_name,bio,city,approved_at)
       values(target,'mamba_'||replace(target::text,'-',''),app.business_name,app.experience_description,app.city,now())
       on conflict(owner_id) do update set approved_at=now();
   else
     delete from public.user_roles where user_id=target and role='host';
     update public.host_profiles set approved_at=null where owner_id=target;
     update public.experiences set status='paused' where host_profile_id in(select id from public.host_profiles where owner_id=target) and status='published';
   end if;
   insert into public.notifications(user_id,kind,title,body) values(target,'system','Solicitud de anfitrión actualizada',case next_status when 'approved' then 'Ya puedes crear y publicar tus experiencias.' when 'suspended' then 'Tu acceso de anfitrión fue suspendido. Contacta a soporte.' else 'Revisa las observaciones y vuelve a enviar tu solicitud.' end);
   return jsonb_build_object('status',next_status);
 end if;
 -- All following host operations require both a trusted role and approval.
 select * into host from public.host_profiles where owner_id=actor and approved_at is not null;
 if action='booking_status' then
   select * into booking from public.bookings where id=(payload->>'id')::uuid for update;
   if not found then raise exception 'Solicitud no encontrada'; end if;
   next_status:=payload->>'status';
   if booking.user_id=actor and next_status='cancelled' and booking.status in ('requested','accepted') then null;
   elsif host.id is not null and private.has_role(actor,'host') and exists(select 1 from public.experiences e where e.id=booking.experience_id and e.host_profile_id=host.id) then
     if not ((booking.status='requested' and next_status in ('accepted','rejected')) or
             (booking.status='accepted' and next_status='cancelled') or
             (booking.status='accepted' and next_status='completed' and booking.booking_date <= (now() at time zone 'America/Bogota')::date)) then
       raise exception 'No se puede realizar ese cambio de estado'; end if;
   else raise exception 'Sin permiso para cambiar esta solicitud'; end if;
   update public.bookings set status=next_status where id=booking.id;
   insert into public.notifications(user_id,kind,title,body,payload) values(booking.user_id,'booking','Tu solicitud cambió de estado',case next_status when 'accepted' then 'El anfitrión aceptó tu solicitud.' when 'rejected' then 'El anfitrión no pudo aceptar tu solicitud.' when 'completed' then 'Tu experiencia terminó. Ya puedes dejar una reseña.' else 'La inscripción fue cancelada.' end,jsonb_build_object('booking_id',booking.id));
   return jsonb_build_object('status',next_status);
 end if;
 if host.id is null or not private.has_role(actor,'host') then raise exception 'Necesitas aprobación como anfitrión'; end if;
 if action='update_host_profile' then
   if length(trim(coalesce(payload->>'display_name','')))<3 or (payload->>'handle') !~ '^[a-zA-Z0-9_]{3,30}$' then raise exception 'Revisa nombre y usuario (3 a 30 letras, números o guion bajo)'; end if;
   if length(coalesce(payload->>'bio',''))>1000 then raise exception 'La biografía admite hasta 1000 caracteres'; end if;
   update public.host_profiles set display_name=trim(payload->>'display_name'),handle=lower(payload->>'handle'),city=trim(payload->>'city'),bio=payload->>'bio',avatar_url=nullif(payload->>'avatar_url',''),cover_url=nullif(payload->>'cover_url','') where id=host.id;
   return jsonb_build_object('id',host.id);
 elsif action='save_experience' then
   target:=coalesce(nullif(payload->>'id','')::uuid,gen_random_uuid());
   next_status:=coalesce(payload->>'status','draft');
   if next_status not in ('draft','published','paused','archived') then raise exception 'Estado inválido'; end if;
   if exists(select 1 from public.experiences where id=target and host_profile_id<>host.id) then raise exception 'Experiencia ajena'; end if;
   if length(trim(coalesce(payload->>'description','')))<30 then raise exception 'Describe tu experiencia en al menos 30 caracteres'; end if;
   if jsonb_array_length(coalesce(payload->'images','[]'::jsonb)) not between 1 and 8 then raise exception 'Agrega entre 1 y 8 fotos'; end if;
   insert into public.experiences(id,host_profile_id,title,slug,description,short_description,category,location_label,meeting_point,latitude,longitude,duration_minutes,price_amount,maximum_people,age_policy,minimum_age,minors_supervision_required,includes,requirements,status,published_at)
   values(target,host.id,trim(payload->>'title'),'plan-'||target::text,payload->>'description',left(payload->>'description',500),payload->>'category',payload->>'location_label',payload->>'meeting_point',(payload->>'latitude')::double precision,(payload->>'longitude')::double precision,(payload->>'duration_minutes')::integer,(payload->>'price_amount')::numeric,(payload->>'maximum_people')::integer,payload->>'age_policy',coalesce((payload->>'minimum_age')::integer,0),true,coalesce(payload->>'includes',''),coalesce(payload->>'requirements',''),next_status,case when next_status='published' then now() end)
   on conflict(id) do update set title=excluded.title,description=excluded.description,short_description=excluded.short_description,category=excluded.category,location_label=excluded.location_label,meeting_point=excluded.meeting_point,latitude=excluded.latitude,longitude=excluded.longitude,duration_minutes=excluded.duration_minutes,price_amount=excluded.price_amount,maximum_people=excluded.maximum_people,age_policy=excluded.age_policy,minimum_age=excluded.minimum_age,includes=excluded.includes,requirements=excluded.requirements,status=excluded.status,published_at=case when excluded.status='published' then coalesce(public.experiences.published_at,now()) else public.experiences.published_at end;
   delete from public.experience_images where experience_id=target;
   for image in select jsonb_array_elements_text(payload->'images') loop
     if image !~ '^https://' then raise exception 'Las fotos requieren una URL HTTPS'; end if;
     insert into public.experience_images(experience_id,image_url,position) values(target,image,pos); pos:=pos+1;
   end loop;
   return jsonb_build_object('id',target);
 end if;
 raise exception 'Acción desconocida';
end $$;
revoke all on function private.host_action(text,jsonb) from public,anon;
grant execute on function private.host_action(text,jsonb) to authenticated;
create function public.host_action(action text,payload jsonb default '{}'::jsonb) returns jsonb
language sql security invoker set search_path='' as $$ select private.host_action(action,payload); $$;
revoke all on function public.host_action(text,jsonb) from public,anon;
grant execute on function public.host_action(text,jsonb) to authenticated;

-- Reviews of applications are private to staff; users see only their own.
create policy host_applications_admin_read on public.host_applications for select to authenticated using(private.has_role((select auth.uid()),'admin'));
-- Remove alternate client write paths for lifecycle state and price validation.
revoke insert,update,delete on public.experiences,public.experience_images from authenticated;
revoke insert,update on public.host_applications from authenticated;

-- Tourists keep access to their own booking history if a plan is paused.
create function private.booked_experience_ids() returns setof uuid
language sql stable security definer set search_path='' as $$
select b.experience_id from public.bookings b where b.user_id=(select auth.uid());
$$;
revoke all on function private.booked_experience_ids() from public,anon;
grant execute on function private.booked_experience_ids() to authenticated;
create policy booked_experience_read on public.experiences for select to authenticated
using (id in(select private.booked_experience_ids()));
