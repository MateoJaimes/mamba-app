-- Transactional integration test. All fixtures are rolled back.
begin;
insert into auth.users(id,email,raw_user_meta_data) values
('11111111-1111-4111-8111-111111111111','host-test@example.invalid','{"display_name":"Host prueba","document_number":"TESTHOST111","document_type":"cc","birth_date":"1990-01-01","phone_number":"3000000001","account_intent":"experienceHost"}'),
('22222222-2222-4222-8222-222222222222','tourist-test@example.invalid','{"display_name":"Turista prueba","document_number":"TESTTOUR222","document_type":"cc","birth_date":"1990-01-01","phone_number":"3000000002"}'),
('33333333-3333-4333-8333-333333333333','admin-test@example.invalid','{"display_name":"Admin prueba","document_number":"TESTADMIN333","document_type":"cc","birth_date":"1990-01-01","phone_number":"3000000003"}');
insert into public.user_roles(user_id,role) values('33333333-3333-4333-8333-333333333333','admin');
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
set local role authenticated;
do $$begin
 if exists(select 1 from public.user_roles where role='host') then raise exception 'FAILED: registration escalated role'; end if;
 begin
   perform public.host_action('review_application','{"user_id":"11111111-1111-4111-8111-111111111111","status":"approved"}');
   raise exception 'FAILED: tourist approved self';
 exception when raise_exception then if sqlerrm like 'FAILED:%' then raise; end if; end;
 begin
   insert into public.user_roles(user_id,role) values(auth.uid(),'admin');
   raise exception 'FAILED: role insert allowed';
 exception when insufficient_privilege then null; end;
 perform public.host_action('submit_application','{"business_name":"Planes de prueba","city":"Medellín","experience_description":"Experiencias culturales guiadas por anfitriones locales para grupos pequeños."}');
end $$;
reset role;
select set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
set local role authenticated;
select public.host_action('review_application','{"user_id":"11111111-1111-4111-8111-111111111111","status":"approved","notes":"Revisión de prueba"}');
reset role;
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
set local role authenticated;
select public.host_action('save_experience','{"id":"44444444-4444-4444-8444-444444444444","title":"Plan cultural de prueba","description":"Recorrido cultural de prueba con acompañamiento local y grupos pequeños.","category":"Cultura","location_label":"Medellín","meeting_point":"Parque principal","latitude":6.24,"longitude":-75.58,"duration_minutes":120,"price_amount":25000,"maximum_people":2,"age_policy":"all_ages","minimum_age":0,"images":["https://example.com/photo.jpg"],"status":"published"}');
do $$begin
 if not exists(select 1 from public.experiences where id='44444444-4444-4444-8444-444444444444') then raise exception 'FAILED: host cannot read plan'; end if;
end $$;
reset role;
select set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
set local role authenticated;
insert into public.bookings(user_id,experience_id,booking_date,adults,minors) values(auth.uid(),'44444444-4444-4444-8444-444444444444',(now() at time zone 'America/Bogota')::date+1,2,0);
select set_config('test.booking_id',(select id::text from public.bookings where experience_id='44444444-4444-4444-8444-444444444444'),true);
do $$begin
 if (select total_amount from public.bookings where id=current_setting('test.booking_id')::uuid)<>50000 then raise exception 'FAILED: price calculation'; end if;
 begin
   insert into public.bookings(user_id,experience_id,booking_date,adults,minors) values(auth.uid(),'44444444-4444-4444-8444-444444444444',(now() at time zone 'America/Bogota')::date+1,1,0);
   raise exception 'FAILED: overbooking';
 exception when raise_exception then if sqlerrm like 'FAILED:%' then raise; end if; end;
 begin
   perform public.host_action('booking_status',jsonb_build_object('id',current_setting('test.booking_id'),'status','accepted'));
   raise exception 'FAILED: tourist accepted booking';
 exception when raise_exception then if sqlerrm like 'FAILED:%' then raise; end if; end;
end $$;
reset role;
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
set local role authenticated;
select public.host_action('booking_status',jsonb_build_object('id',current_setting('test.booking_id'),'status','accepted'));
do $$begin
 begin
   perform public.host_action('booking_status',jsonb_build_object('id',current_setting('test.booking_id'),'status','completed'));
   raise exception 'FAILED: future completion';
 exception when raise_exception then if sqlerrm like 'FAILED:%' then raise; end if; end;
end $$;
reset role;
select set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
set local role authenticated;
select public.host_action('review_application','{"user_id":"11111111-1111-4111-8111-111111111111","status":"suspended","notes":"Suspensión de prueba"}');
reset role;
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
set local role authenticated;
do $$begin
 begin
   perform public.host_action('update_host_profile','{"display_name":"Host","handle":"host_test","city":"Medellín","bio":"Prueba"}');
   raise exception 'FAILED: suspended host edited profile';
 exception when raise_exception then if sqlerrm like 'FAILED:%' then raise; end if; end;
end $$;
reset role;
rollback;
