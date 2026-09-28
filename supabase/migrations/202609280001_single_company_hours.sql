-- Single-company installation: business hours do not require a clinic row.
-- Some JRV databases never had clinic_id, so this migration is intentionally safe in both schemas.
begin;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'clinic_hours'
      and column_name = 'clinic_id'
  ) then
    alter table public.clinic_hours
      alter column clinic_id drop not null;
  end if;
end
$$;

commit;