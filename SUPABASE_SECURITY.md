# Segurança do Supabase — JRV

## Aplicação

Execute `supabase/migrations/202609180001_harden_frontend_rls.sql` no SQL Editor do projeto Supabase usando uma conta administrativa. Esta instalação é de uma única empresa: não são necessárias as tabelas `public.users` ou `public.clinics`. Todos os acessos são internos e criados manualmente no Supabase Authentication.

Opcionalmente, o `clinic_id` pode ser registrado em `app_metadata` para compatibilidade com tabelas legadas que possuam essa coluna:

```sql
update auth.users
set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
  || jsonb_build_object('clinic_id', '<UUID_DA_IMOBILIARIA>')
where email = '<EMAIL_DO_USUARIO>';
```

Para conferir todos os acessos:

```sql
select id, email, raw_app_meta_data ->> 'clinic_id' as clinic_id
from auth.users
order by email;
```

Não use `user_metadata` para autorização, pois o próprio usuário pode alterar esse campo. Como existe apenas uma empresa neste banco, as policies liberam os dados somente para sessões autenticadas e bloqueiam completamente o papel `anon`, exceto nas tabelas deliberadamente públicas do catálogo.

O cadastro público também deve permanecer desabilitado em **Authentication → Providers → Email → Allow new users to sign up**. A rota `/cadastro` foi bloqueada no frontend, mas a configuração do Supabase é a proteção definitiva contra criação pública de contas.

## Credencial do n8n

No n8n, configure a integração Supabase com:

- URL do projeto em `SUPABASE_URL`;
- chave **service_role** em `SUPABASE_SERVICE_ROLE_KEY`;
- header `Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>`;
- header `apikey: <SUPABASE_SERVICE_ROLE_KEY>`.

Nunca coloque a chave `service_role` em variável `NUXT_PUBLIC_*`, código Vue, navegador, Git ou mensagem de webhook. A chave deve existir apenas nas credenciais criptografadas do n8n.

`n8n_chat_histories` não possui policies. O acesso direto de `anon` e `authenticated` é revogado, o n8n acessa com `service_role` e o frontend lê somente pela RPC `get_secure_chat_histories`, filtrada pelo `clinic_id` do usuário autenticado.

## Testes obrigatórios após aplicar

1. Sem login, confirmar que dashboard, leads, corretores, agenda e configurações não retornam dados.
2. Com um usuário interno autenticado, confirmar os fluxos de leitura e gravação.
3. Confirmar que usuário não autenticado somente enxerga imóveis/procedimentos destinados ao catálogo público.
4. Executar o workflow do n8n e confirmar inserção em `n8n_chat_histories`.
5. Abrir `/chats` e confirmar que as mensagens aparecem e atualizam em até cinco segundos.
6. Fazer upload de imagem e confirmar que somente uma sessão autenticada consegue gravar no bucket.

## Auditoria rápida

```sql
select schemaname, tablename, rowsecurity
from pg_tables
where schemaname = 'public'
order by tablename;

select schemaname, tablename, policyname, roles, cmd
from pg_policies
where schemaname = 'public'
order by tablename, policyname;

select grantee, privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name = 'n8n_chat_histories'
order by grantee, privilege_type;
```

A última consulta não deve mostrar privilégios para `anon` ou `authenticated`, e a consulta de policies não deve mostrar nenhuma policy em `n8n_chat_histories`.
