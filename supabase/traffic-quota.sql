-- Proposed migration; NOT applied automatically. No secret is stored here.
-- Explicit enablement and an approved daily ceiling are required before use.
create table if not exists public.traffic_quota_settings (
  singleton boolean primary key default true check(singleton),
  enabled boolean not null default false,
  daily_limit integer not null default 0 check(daily_limit between 0 and 1000)
);
insert into public.traffic_quota_settings(singleton) values(true) on conflict do nothing;
create table if not exists public.traffic_quota_usage (
  day date primary key,
  requests integer not null default 0
);
alter table public.traffic_quota_settings enable row level security;
alter table public.traffic_quota_usage enable row level security;
revoke all on public.traffic_quota_settings, public.traffic_quota_usage from anon, authenticated;
create or replace function public.consume_traffic_quota(caller uuid)
returns boolean language plpgsql security definer set search_path = '' as $$
declare ceiling integer; consumed integer;
begin
  if caller is null then return false; end if;
  select daily_limit into ceiling from public.traffic_quota_settings
    where singleton and enabled for update;
  if ceiling is null or ceiling <= 0 then return false; end if;
  insert into public.traffic_quota_usage(day,requests)
    values((now() at time zone 'UTC')::date,1)
    on conflict(day) do update set requests=public.traffic_quota_usage.requests+1
    where public.traffic_quota_usage.requests < ceiling
    returning requests into consumed;
  return consumed is not null;
end; $$;
revoke all on function public.consume_traffic_quota(uuid) from public, anon, authenticated;
grant execute on function public.consume_traffic_quota(uuid) to service_role;
