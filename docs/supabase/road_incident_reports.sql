-- Execute once in the Supabase SQL Editor. No existing tables are changed.
-- Deliberately fails if the table already exists: inspect that schema first.
begin;
create table public.reportes_viales (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  tipo text not null check (tipo in
    ('accident', 'congestion', 'road_work', 'road_closed', 'hazard', 'other')),
  latitud double precision not null check (latitud between -90 and 90),
  longitud double precision not null check (longitud between -180 and 180),
  descripcion text check (char_length(descripcion) <= 200),
  creado_en timestamptz not null default now(),
  expira_en timestamptz not null default (now() + interval '6 hours'),
  estado text not null default 'activo' check (estado in ('activo', 'cancelado')),
  check (expira_en > creado_en)
);
create index reportes_viales_activos_idx
  on public.reportes_viales (creado_en desc, expira_en) where estado = 'activo';

alter table public.reportes_viales enable row level security;
revoke all on public.reportes_viales from public, anon, authenticated;
grant select on public.reportes_viales to authenticated;
-- Clients cannot choose timestamps, expiry, status or primary keys.
grant insert (usuario_id, tipo, latitud, longitud, descripcion)
  on public.reportes_viales to authenticated;
create policy reportes_viales_leer_activos on public.reportes_viales
  for select to authenticated using (estado = 'activo' and expira_en > now());
create policy reportes_viales_crear_propios on public.reportes_viales
  for insert to authenticated with check ((select auth.uid()) = usuario_id);
-- No UPDATE/DELETE grants or policies: cancellation is not implemented in V1.
commit;

-- BLOQUE 2: ejecutar después del bloque anterior; se puede repetir.
-- Habilita Postgres Changes sin modificar otras tablas de la publication.
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    raise exception 'No existe supabase_realtime. Habilite Realtime en el proyecto.';
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public'
      and tablename = 'reportes_viales'
  ) then
    alter publication supabase_realtime add table public.reportes_viales;
  end if;
end $$;
