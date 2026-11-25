-- New bookings are confirmed atomically with capacity and eligibility validation.
-- External payment is a method, never evidence that money was collected.
alter table public.bookings add column payment_method text not null default 'in_person' check(payment_method='in_person');
alter table public.bookings drop constraint bookings_payment_status_check;
alter table public.bookings add constraint bookings_payment_status_check check(payment_status in ('not_applicable','external_untracked'));
alter table public.bookings alter column status set default 'accepted';
alter table public.bookings alter column payment_status set default 'external_untracked';
alter policy bookings_insert_own_request on public.bookings with check(user_id=(select auth.uid()) and status='accepted' and payment_status='external_untracked' and payment_method='in_person');
update public.bookings set status='accepted',payment_status='external_untracked' where status='requested';
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

  new.status := 'accepted';
  new.payment_status := 'external_untracked';
  new.payment_method := 'in_person';
  new.unit_price := exp.price_amount;
  new.total_amount := exp.price_amount * (new.adults + new.minors);
  new.currency := exp.currency;
  return new;
end;
$$;

create or replace function private.host_action_base(action text, payload jsonb) returns jsonb
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
     if not ((booking.status in ('requested','accepted') and next_status='cancelled') or
             (booking.status='accepted' and next_status='completed' and booking.booking_date <= (now() at time zone 'America/Bogota')::date)) then
       raise exception 'No se puede realizar ese cambio de estado'; end if;
   else raise exception 'Sin permiso para cambiar esta solicitud'; end if;
   update public.bookings set status=next_status where id=booking.id;
   insert into public.notifications(user_id,kind,title,body,payload) values(booking.user_id,'booking','Tu inscripción cambió de estado',case next_status when 'accepted' then 'Tu inscripción está confirmada.' when 'rejected' then 'El anfitrión no pudo aceptar tu solicitud.' when 'completed' then 'Tu experiencia terminó. Ya puedes dejar una reseña.' else 'La inscripción fue cancelada. El pago presencial se coordina con el anfitrión.' end,jsonb_build_object('booking_id',booking.id));
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

create or replace function private.notify_booking_request() returns trigger
language plpgsql security definer set search_path='' as $$
declare host_owner uuid; experience_title text;
begin
 select h.owner_id,e.title into host_owner,experience_title from public.experiences e join public.host_profiles h on h.id=e.host_profile_id where e.id=new.experience_id;
 insert into public.notifications(user_id,kind,title,body,payload) values(new.user_id,'booking','Inscripción confirmada','Tu cupo para '||coalesce(experience_title,'la experiencia')||' está confirmado. Paga presencialmente al anfitrión; MAMBA no realiza ningún cobro.',jsonb_build_object('booking_id',new.id,'experience_id',new.experience_id));
 if host_owner is not null and host_owner<>new.user_id then
   insert into public.notifications(user_id,kind,title,body,payload) values(host_owner,'booking','Nueva inscripción confirmada','Tienes nuevos participantes para '||coalesce(experience_title,'una experiencia')||'. No necesitas aceptar la inscripción. El pago se realiza presencialmente contigo.',jsonb_build_object('booking_id',new.id,'experience_id',new.experience_id));
 end if;
 return new;
end $$;
-- Preserve the existing invoker view and column order for installed APKs.
create or replace view public.my_bookings with(security_invoker=true) as
select b.id,b.user_id,b.experience_id,e.title as experience_title,h.display_name as provider_name,h.id as provider_id,e.location_label as location,b.booking_date as date,b.adults,b.minors,b.adults+b.minors as guests,b.status,b.payment_status,b.unit_price,b.total_amount,b.currency,
 (select i.image_url from public.experience_images i where i.experience_id=e.id order by i.position limit 1) as image,b.created_at,b.payment_method
from public.bookings b join public.experiences e on e.id=b.experience_id join public.host_profiles h on h.id=e.host_profile_id;
-- The legacy flag now agrees with the enforced workflow, including future plans.
alter table public.experiences alter column instant_booking set default true;
update public.experiences set instant_booking=true;
-- Update only the MAMBA seed descriptions that still describe manual approval.
update public.experiences set description=replace(replace(replace(replace(replace(description,
 'La solicitud queda sujeta a confirmación del anfitrión; el horario se acuerda antes de asistir.','La inscripción se confirma automáticamente según los cupos disponibles. El pago se realiza presencialmente con el anfitrión; coordina el horario antes de asistir.'),
 'El lugar y el horario se coordinan al confirmar tu solicitud, en el sector Manila.','La inscripción se confirma automáticamente según los cupos disponibles. El lugar y el horario se coordinan con el anfitrión en el sector Manila. El pago se realiza presencialmente con el anfitrión.'),
 'El lugar y el horario se coordinan al confirmar tu solicitud, en el sector Manila.','El lugar y el horario se coordinan con el anfitrión, en el sector Manila.'),
 'La solicitud requiere confirmación del anfitrión y puede reprogramarse por lluvia intensa.','La inscripción se confirma automáticamente según los cupos disponibles y puede reprogramarse por lluvia intensa. El pago se realiza presencialmente con el anfitrión.'),
 'La dirección se confirma antes de aceptar la solicitud.','La dirección se coordina con el anfitrión antes de asistir.')
where slug in ('mamba-comuna-13','mamba-cafe-de-origen','mamba-santa-elena-bosque');
update public.experiences set meeting_point=replace(meeting_point,'La dirección se confirma antes de aceptar la solicitud.','La dirección se coordina con el anfitrión antes de asistir.') where slug='mamba-cafe-de-origen';
