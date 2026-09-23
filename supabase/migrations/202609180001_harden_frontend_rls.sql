-- JRV: frontend least-privilege hardening.
-- n8n must use SUPABASE_SERVICE_ROLE_KEY. Never expose that key in Nuxt/public env.
-- Intentionally creates NO policy on public.n8n_chat_histories.

begin;

create or replace function public.get_auth_clinic_id()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  result uuid;
  candidate_table text;
begin
  if auth.uid() is null then
    return null;
  end if;

  result := nullif(auth.jwt() -> 'app_metadata' ->> 'clinic_id', '')::uuid;
  if result is not null then
    return result;
  end if;

  foreach candidate_table in array array[
    'clinic_hours', 'sistemaconfiguracao', 'appointments', 'n8n_chat_histories'
  ] loop
    if exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = candidate_table
        and column_name = 'clinic_id'
    ) then
      execute format(
        'select clinic_id::uuid from public.%I where clinic_id is not null limit 1',
        candidate_table
      ) into result;
      if result is not null then
        return result;
      end if;
    end if;
  end loop;

  return null;
end
$$;

revoke all on function public.get_auth_clinic_id() from public, anon;
grant execute on function public.get_auth_clinic_id() to authenticated, service_role;

-- Single-company installation: every account is created internally. Browser
-- access requires a valid Supabase Auth session; anon receives no CRUD access.
do $$
declare
  table_name text;
  policy_name text;
  old_policy record;
begin
  foreach table_name in array array[
    'appointments', 'clinic_hours', 'corretores', 'fila_emails_corretor',
    'fotos_pneus', 'leads', 'notificacoes', 'sistemaconfiguracao',
    'procedures', 'cadence_rules', 'ai_insights', 'lead_followups',
    'activity_logs', 'messages'
  ] loop
    if to_regclass('public.' || table_name) is null then
      continue;
    end if;

    execute format('alter table public.%I enable row level security', table_name);
    execute format('alter table public.%I force row level security', table_name);
    execute format('revoke all on public.%I from anon', table_name);
    execute format('grant select, insert, update, delete on public.%I to authenticated', table_name);
    execute format('grant all on public.%I to service_role', table_name);

    for old_policy in
      select policyname
      from pg_policies
      where schemaname = 'public' and tablename = table_name
    loop
      execute format('drop policy if exists %I on public.%I', old_policy.policyname, table_name);
    end loop;

    policy_name := table_name || '_tenant_select';
    execute format('drop policy if exists %I on public.%I', policy_name, table_name);
    execute format(
      'create policy %I on public.%I for select to authenticated using (auth.uid() is not null)',
      policy_name, table_name
    );
    policy_name := table_name || '_tenant_insert';
    execute format('drop policy if exists %I on public.%I', policy_name, table_name);
    execute format(
      'create policy %I on public.%I for insert to authenticated with check (auth.uid() is not null)',
      policy_name, table_name
    );
    policy_name := table_name || '_tenant_update';
    execute format('drop policy if exists %I on public.%I', policy_name, table_name);
    execute format(
      'create policy %I on public.%I for update to authenticated using (auth.uid() is not null) with check (auth.uid() is not null)',
      policy_name, table_name
    );
    policy_name := table_name || '_tenant_delete';
    execute format('drop policy if exists %I on public.%I', policy_name, table_name);
    execute format(
      'create policy %I on public.%I for delete to authenticated using (auth.uid() is not null)',
      policy_name, table_name
    );

  end loop;
end $$;

-- Questions use the legacy `clinic` column rather than clinic_id.
alter table if exists public.clinica_perguntas enable row level security;
alter table if exists public.clinica_perguntas force row level security;
revoke all on table public.clinica_perguntas from anon;
grant select, insert, update, delete on table public.clinica_perguntas to authenticated;
grant all on table public.clinica_perguntas to service_role;
drop policy if exists clinica_perguntas_tenant_all on public.clinica_perguntas;
create policy clinica_perguntas_tenant_all on public.clinica_perguntas
  for all to authenticated
  using (auth.uid() is not null)
  with check (auth.uid() is not null);

-- Global pipeline stages are readable but never writable from the browser.
alter table public.stage enable row level security;
alter table public.stage force row level security;
revoke all on table public.stage from anon, authenticated;
grant select on table public.stage to authenticated;
grant all on table public.stage to service_role;
drop policy if exists stage_authenticated_read on public.stage;
create policy stage_authenticated_read on public.stage for select to authenticated using (true);

-- Public catalogue: read-only public access to listing tables when present.
do $$ begin
  if to_regclass('public.procedures') is not null then
    grant select on table public.procedures to anon;
    drop policy if exists procedures_public_catalog_read on public.procedures;
    create policy procedures_public_catalog_read on public.procedures for select to anon using (true);
  end if;
  if to_regclass('public.fotos_pneus') is not null then
    grant select on table public.fotos_pneus to anon;
    drop policy if exists fotos_pneus_public_catalog_read on public.fotos_pneus;
    create policy fotos_pneus_public_catalog_read on public.fotos_pneus for select to anon using (true);
  end if;
end $$;

-- n8n_chat_histories: intentionally NO policies. Browser roles lose all table
-- privileges; service_role keeps unrestricted n8n access without RLS policies.
do $$
declare p record;
begin
  if to_regclass('public.n8n_chat_histories') is not null then
    for p in select policyname from pg_policies where schemaname = 'public' and tablename = 'n8n_chat_histories'
    loop
      execute format('drop policy if exists %I on public.n8n_chat_histories', p.policyname);
    end loop;
    alter table public.n8n_chat_histories disable row level security;
    revoke all on table public.n8n_chat_histories from public, anon, authenticated;
    grant all on table public.n8n_chat_histories to service_role;
  end if;
end $$;

-- Secure browser gateway for chat history, filtered inside a SECURITY DEFINER
-- function. Returning jsonb avoids coupling the API to the table row type.
create or replace function public.get_secure_chat_histories(p_session_id text default null)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(to_jsonb(h) order by h.id), '[]'::jsonb)
  from public.n8n_chat_histories h
  where auth.uid() is not null
    and (p_session_id is null or h.session_id = p_session_id)
$$;

revoke all on function public.get_secure_chat_histories(text) from public, anon;
grant execute on function public.get_secure_chat_histories(text) to authenticated, service_role;

-- Views must obey the RLS policies of their source tables.
do $$
declare view_name text;
begin
  foreach view_name in array array['vw_lembretes_1_dia', 'vw_lembretes_2_horas', 'vw_relatorio_semanal'] loop
    if to_regclass('public.' || view_name) is not null then
      execute format('alter view public.%I set (security_invoker = true)', view_name);
      execute format('revoke all on public.%I from anon', view_name);
      execute format('grant select on public.%I to authenticated, service_role', view_name);
    end if;
  end loop;
end $$;

-- Storage bucket `imgs`: public catalogue reads and authenticated-only writes.
drop policy if exists imgs_public_read on storage.objects;
create policy imgs_public_read on storage.objects for select to anon, authenticated
  using (bucket_id = 'imgs');
drop policy if exists imgs_tenant_insert on storage.objects;
create policy imgs_tenant_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'imgs' and auth.uid() is not null);
drop policy if exists imgs_tenant_update on storage.objects;
create policy imgs_tenant_update on storage.objects for update to authenticated
  using (bucket_id = 'imgs' and auth.uid() is not null)
  with check (bucket_id = 'imgs' and auth.uid() is not null);
drop policy if exists imgs_tenant_delete on storage.objects;
create policy imgs_tenant_delete on storage.objects for delete to authenticated
  using (bucket_id = 'imgs' and auth.uid() is not null);

commit;
