create or replace function private.host_action(action text,payload jsonb) returns jsonb language plpgsql security invoker set search_path='' as $$
declare result jsonb; selected_categories text[];
begin
 if action='save_experience' and payload ? 'categories' then
   select array_agg(value) into selected_categories from jsonb_array_elements_text(payload->'categories');
   if coalesce(cardinality(selected_categories),0) not between 1 and 6 then raise exception 'Elige de 1 a 6 categorías';end if;
   payload:=jsonb_set(payload,'{category}',to_jsonb(selected_categories[1]));
 end if;
 result:=private.host_action_base(action,payload);
 if action='save_experience' and selected_categories is not null then
   -- The existing privileged workflow already validated ownership. Use a narrow helper.
   perform private.set_plan_categories((result->>'id')::uuid,selected_categories);
 end if;
 return result;
end $$;

create index if not exists experiences_categories_gin on public.experiences using gin(categories);
create index if not exists profiles_country_idx on public.profiles(country_code);
create index if not exists profiles_region_idx on public.profiles(region_code);
create index if not exists profiles_city_idx on public.profiles(city_code);
create index if not exists profiles_currency_idx on public.profiles(preferred_currency);
create index if not exists cities_country_idx on public.cities(country_code);
