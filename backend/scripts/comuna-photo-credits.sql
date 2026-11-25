begin;
update public.experience_images i set image_url=case position when 0 then 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/40/Comuna_13%2C_Medell%C3%ADn_01.jpg/960px-Comuna_13%2C_Medell%C3%ADn_01.jpg' else 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c0/Comuna_13%2C_Medell%C3%ADn_02.jpg/960px-Comuna_13%2C_Medell%C3%ADn_02.jpg' end
from public.experiences e join public.host_profiles h on h.id=e.host_profile_id
where i.experience_id=e.id and e.slug='mapo-comuna-13' and h.owner_id=(select id from auth.users where email='somosmapoapp@gmail.com');
update public.experiences set description=replace(description,'Fotografías de referencia; no representan un convenio con operadores externos.','Fotos de Comuna 13: Bernard Gagnon, Wikimedia Commons, CC BY-SA 4.0. Se ajusta el encuadre en pantalla. Fuente: https://commons.wikimedia.org/wiki/File:Comuna_13,_Medellín_01.jpg y https://commons.wikimedia.org/wiki/File:Comuna_13,_Medellín_02.jpg · Licencia: https://creativecommons.org/licenses/by-sa/4.0/ · No implica respaldo del fotógrafo ni alianzas con operadores externos.') where slug='mapo-comuna-13';
commit;
