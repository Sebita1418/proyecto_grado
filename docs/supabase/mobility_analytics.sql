-- PROPUESTA: requiere aplicación manual en Supabase. No ejecutada remotamente.
-- Inspeccionar primero el esquema real y la propiedad de la función.
-- Verificar owner antes y después: rol confiable de migración/base de datos,
-- capaz de leer históricos; nunca anon ni authenticated.
-- Mantiene RLS operacional; no otorga SELECT histórico sobre la tabla.
begin;
create index if not exists reportes_viales_analytics_created_idx
  on public.reportes_viales (creado_en, id);
create or replace function public.mobility_analytics_observations(
  period_start timestamptz, period_end timestamptz
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  result jsonb;
  evaluated timestamptz := pg_catalog.statement_timestamp();
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if period_start is null or period_end is null
    or period_start >= period_end
    or period_end - period_start > interval '30 days'
    or period_start < evaluated - interval '31 days'
    or period_end > evaluated + interval '5 minutes' then
    raise exception 'Invalid analytics window' using errcode = '22023';
  end if;
  -- Owner must be a trusted migration role able to read historical rows.
  -- Projection deliberately excludes IDs, author, description and coordinates.
  with bounded as materialized (
    select id, tipo, creado_en, expira_en, estado
    from public.reportes_viales
    where creado_en >= period_start and creado_en < period_end
    order by creado_en, id limit 5001
  ), visible as (
    select id, tipo, creado_en, expira_en, estado from bounded
    order by creado_en, id limit 5000
  )
  select pg_catalog.jsonb_build_object(
    'version', 1, 'evaluated_at', evaluated,
    'truncated', (select pg_catalog.count(*) > 5000 from bounded),
    -- ID solo sirve para ordenar; la lista blanca impide proyectarlo al JSON.
    'observations', coalesce((select pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'tipo', v.tipo, 'creado_en', v.creado_en,
        'expira_en', v.expira_en, 'estado', v.estado
      ) order by v.creado_en, v.id
    ) from visible v), '[]'::jsonb)
  ) into result;
  return result;
end;
$$;
revoke all on function public.mobility_analytics_observations(timestamptz, timestamptz)
  from public, anon;
-- Normalizar también privilegios directos previos antes de conceder EXECUTE.
revoke all on function public.mobility_analytics_observations(timestamptz, timestamptz)
  from authenticated;
grant execute on function public.mobility_analytics_observations(timestamptz, timestamptz)
  to authenticated;
commit;
