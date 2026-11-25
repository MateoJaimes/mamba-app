-- Seed optional demo plans for the verified MAPO owner.
-- Deliberately not an automatic migration: review before running again.
begin;
do $body$
declare actor uuid; host uuid; plan uuid; 
begin
 select id into actor from auth.users where lower(email)='somosmapoapp@gmail.com' and email_confirmed_at is not null;
 if actor is null then raise exception 'Cuenta MAPO sin verificar'; end if;
 if exists(select 1 from public.bookings b join public.experiences e on e.id=b.experience_id where e.is_demo) then raise exception 'Hay inscripciones de demostración; conservar historial'; end if;
 delete from public.experiences where is_demo;
 delete from public.host_profiles where is_demo and owner_id is null and not exists(select 1 from public.experiences e where e.host_profile_id=host_profiles.id);
 insert into public.user_roles(user_id,role) values(actor,'host') on conflict do nothing;
 insert into public.host_applications(user_id,status,business_name,city,experience_description,reviewer_notes,reviewed_at)
 values(actor,'approved','MAPO Experiencias','Medellín','Experiencias culturales, de café y naturaleza en Medellín, gestionadas por el equipo MAPO.','Alta de la cuenta propietaria solicitada por MAPO. Sin documentos ni reseñas fabricadas.',now())
 on conflict(user_id) do update set status='approved',business_name=excluded.business_name,city=excluded.city,reviewer_notes=excluded.reviewer_notes,reviewed_at=now();
 insert into public.host_profiles(owner_id,handle,display_name,bio,city,avatar_url,cover_url,approved_at,is_demo)
 values(actor,'somosmapo','MAPO Experiencias','Descubrimos Medellín a través de sus barrios, el café y las montañas. Solicita tu cupo y coordinamos contigo horario, disponibilidad y detalles del encuentro.','Medellín','https://mapo-experiencias-api.vercel.app/branding/mapo-icon.png','https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=1000&q=80',now(),false)
 on conflict(owner_id) do update set display_name=excluded.display_name,handle=excluded.handle,approved_at=now(),is_demo=false returning id into host;
 update public.profiles set account_intent='experience_host' where id=actor;
 insert into public.experiences(host_profile_id,title,slug,short_description,description,category,categories,location_label,meeting_point,latitude,longitude,duration_minutes,price_amount,maximum_people,age_policy,minimum_age,includes,requirements,status,is_demo,published_at)
 values(host,'Comuna 13: arte, memoria y sabores','mapo-comuna-13','Un recorrido a pie entre murales, historias del barrio y sabores locales.',
 'Caminamos por el sector de Las Independencias para descubrir el arte urbano y las historias que han transformado la Comuna 13. El recorrido combina paradas para observar murales, miradores y una pausa para un helado artesanal. Duración aproximada: 3 horas, en español y en grupo pequeño. La solicitud queda sujeta a confirmación del anfitrión; el horario se acuerda antes de asistir. No incluye transporte ni consumos adicionales. Fotografías de referencia; no representan un convenio con operadores externos.',
 'Cultura',array['Cultura','Arte','Historia','Gastronomía'],'Medellín · Comuna 13','Acceso al sistema de escaleras eléctricas, sector Las Independencias. Punto exacto confirmado al aceptar.',6.2479,-75.6228,180,60000,10,'all_ages',0,'Acompañamiento durante el recorrido y un helado artesanal por persona.','Calzado cómodo, agua y protección solar. Menores acompañados por un adulto. Hay pendientes y escaleras.','published',false,now())
 on conflict(slug) do update set host_profile_id=excluded.host_profile_id returning id into plan;
 insert into public.experience_images(experience_id,image_url,position)
 select plan,url,n from (values('https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=900&q=80',0),('https://images.unsplash.com/photo-1519501025264-65ba15a82390?auto=format&fit=crop&w=900&q=80',1))v(url,n)
 where not exists(select 1 from public.experience_images where experience_id=plan);
 insert into public.experiences(host_profile_id,title,slug,short_description,description,category,categories,location_label,meeting_point,latitude,longitude,duration_minutes,price_amount,maximum_people,age_policy,minimum_age,includes,requirements,status,is_demo,published_at)
 values(host,'Café de origen: del aroma a la taza','mapo-cafe-de-origen','Una experiencia sensorial para conocer el café colombiano y sus métodos de preparación.',
 'Una introducción cercana al café de especialidad en Medellín. Exploramos aroma, acidez y cuerpo con una degustación guiada de tres cafés colombianos y una demostración de preparación manual. No necesitas conocimientos previos. La actividad dura alrededor de 2 horas, en español, para un grupo de hasta 8 personas. El lugar y el horario se coordinan al confirmar tu solicitud, en el sector Manila. No incluye transporte, almuerzo ni bolsas de café para llevar. Fotografías de referencia; no representa una alianza con una cafetería específica.',
 'Gastronomía',array['Gastronomía','Cultura','Talleres'],'Medellín · Manila, El Poblado','Sector Manila, cerca del parque de El Poblado. La dirección se confirma antes de aceptar la solicitud.',6.2125,-75.5701,120,65000,8,'minimum_age',12,'Degustación de tres cafés, demostración de preparación y acompañamiento durante la actividad.','Informar sensibilidad a la cafeína. Menores de edad acompañados por un adulto.','published',false,now())
 on conflict(slug) do update set host_profile_id=excluded.host_profile_id returning id into plan;
 insert into public.experience_images(experience_id,image_url,position)
 select plan,url,n from(values('https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=900&q=80',0),('https://images.unsplash.com/photo-1447933601403-0c6688de566e?auto=format&fit=crop&w=900&q=80',1))v(url,n)
 where not exists(select 1 from public.experience_images where experience_id=plan);
 insert into public.experiences(host_profile_id,title,slug,short_description,description,category,categories,location_label,meeting_point,latitude,longitude,duration_minutes,price_amount,maximum_people,age_policy,minimum_age,includes,requirements,status,is_demo,published_at)
 values(host,'Santa Elena: bosque, senderos y aire de montaña','mapo-santa-elena-bosque','Una caminata de ritmo tranquilo por el entorno rural de Santa Elena.',
 'Nos encontramos en el parque principal de Santa Elena para una caminata de aproximadamente 5 km por caminos rurales y sectores de bosque, con pausas de observación y descanso. Duración estimada: 3 horas, dificultad moderada y grupo de hasta 10 personas. El trazado final depende del clima y de las condiciones de acceso. La solicitud requiere confirmación del anfitrión y puede reprogramarse por lluvia intensa. No incluye transporte desde Medellín, Metrocable, entradas a predios privados ni actividades de la Corporación Parque Arví. Fotografías de referencia.',
 'Naturaleza',array['Naturaleza','Aventura','Rural','Bienestar'],'Medellín · Santa Elena','Parque principal de Santa Elena, junto a la iglesia. Confirmación del lugar y horario antes de asistir.',6.2099,-75.5016,180,55000,10,'minimum_age',10,'Acompañamiento durante la caminata y una pausa con bebida caliente.','Zapatos con buen agarre, chaqueta impermeable y al menos 1 litro de agua. Informar condiciones que puedan afectar la caminata. Menores acompañados.','published',false,now())
 on conflict(slug) do update set host_profile_id=excluded.host_profile_id returning id into plan;
 insert into public.experience_images(experience_id,image_url,position)
 select plan,url,n from(values('https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=900&q=80',0),('https://images.unsplash.com/photo-1551632811-561732d1e306?auto=format&fit=crop&w=900&q=80',1))v(url,n)
 where not exists(select 1 from public.experience_images where experience_id=plan);
end $body$;
commit;
select h.display_name,e.title,e.price_amount,e.categories from public.experiences e join public.host_profiles h on h.id=e.host_profile_id where h.owner_id=(select id from auth.users where email='somosmapoapp@gmail.com');
