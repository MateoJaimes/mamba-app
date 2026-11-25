begin;
select set_config('request.jwt.claim.sub',(select id::text from auth.users where email='somosmambaapp@gmail.com'),true);
set local role authenticated;
do $$
declare plan public.experiences; booking public.bookings; again public.bookings; day date:=current_date+27;
begin
 select e.* into plan from public.experiences e join public.host_profiles h on h.id=e.host_profile_id where h.owner_id=auth.uid() and e.status='published' limit 1;
 if plan.id is null then raise exception 'Missing test plan';end if;
 insert into public.bookings(user_id,experience_id,booking_date,adults,minors,minimum_age_confirmed,minors_supervision_confirmed) values(auth.uid(),plan.id,day,plan.maximum_people,0,true,true) returning * into booking;
 if booking.status<>'accepted' or booking.payment_status<>'external_untracked' or booking.payment_method<>'in_person' then raise exception 'Automatic confirmation or payment method failed';end if;
 if booking.total_amount<>plan.price_amount*plan.maximum_people then raise exception 'Canonical price changed';end if;
 if not exists(select 1 from public.notifications where user_id=auth.uid() and title='Inscripción confirmada' and payload->>'booking_id'=booking.id::text) then raise exception 'Confirmation notification missing';end if;
 begin
   insert into public.bookings(user_id,experience_id,booking_date,adults,minimum_age_confirmed) values(auth.uid(),plan.id,day,1,true);
   raise exception using errcode='XX000',message='Overbooking accepted';
 exception when sqlstate 'P0001' then if sqlerrm not like '%not enough places%' then raise;end if;
 end;
 begin
   perform public.host_action('booking_status',jsonb_build_object('id',booking.id,'status','accepted'));
   raise exception using errcode='XX000',message='Manual acceptance remained enabled';
 exception when sqlstate 'P0001' then if sqlerrm not like '%No se puede realizar%' then raise;end if;
 end;
 begin
   perform public.host_action('booking_status',jsonb_build_object('id',booking.id,'status','completed'));
   raise exception using errcode='XX000',message='Future experience completed';
 exception when sqlstate 'P0001' then if sqlerrm not like '%No se puede realizar%' then raise;end if;
 end;
 begin
   update public.bookings set payment_status='paid' where id=booking.id;
   raise exception using errcode='XX000',message='Client marked an unverified payment';
 exception when insufficient_privilege then null;
 end;
 begin
   insert into public.bookings(user_id,experience_id,booking_date,adults,minimum_age_confirmed) values(auth.uid(),plan.id,current_date-1,1,true);
   raise exception using errcode='XX000',message='Past date accepted';
 exception when sqlstate 'P0001' then if sqlerrm not like '%outside the allowed range%' then raise;end if;
 end;
 perform public.host_action('booking_status',jsonb_build_object('id',booking.id,'status','cancelled'));
 insert into public.bookings(user_id,experience_id,booking_date,adults,minimum_age_confirmed) values(auth.uid(),plan.id,day,1,true) returning * into again;
 if again.status<>'accepted' then raise exception 'Cancellation failed to release seats';end if;
end $$;
select 'Confirmed automatically; seats, canonical price, payment permissions, notifications and cancellation verified' as checks;
rollback;
