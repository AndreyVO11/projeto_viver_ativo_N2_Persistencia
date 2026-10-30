-- Migração incremental: recuperação de senha por pergunta padrão (RF001, fluxo A3)
-- e troca do telefone de login (RF001, fluxo A1). Não apaga nada existente.
-- Cole no SQL Editor do Supabase e rode uma única vez (pode rodar de novo sem problemas).
--
-- Como funciona:
--  * A pergunta é fixa e vive no aplicativo ("Qual é o nome completo da sua mãe?");
--    o banco guarda só um HASH da resposta (bcrypt), nunca o texto.
--  * A tabela recuperacao_senha tem RLS LIGADO e nenhuma política: nenhum cliente
--    (nem com a anon key) consegue lê-la. Só as funções abaixo, que rodam com
--    privilégio do dono (security definer), acessam os dados.
--  * Cinco respostas erradas seguidas bloqueiam a recuperação daquela conta por 15 minutos.
--  * O Supabase Auth recusa trocar o e-mail interno (<telefone>@ders.app) pela API
--    padrão, por isso a troca de telefone de login também é feita por função.

-- 1. Hash da resposta de recuperação + controle de tentativas.
create table if not exists recuperacao_senha (
  usuario_id uuid primary key references usuarios (id) on delete cascade,
  resposta_hash text not null,
  tentativas_falhas int not null default 0,
  bloqueado_ate timestamptz,
  atualizado_em timestamptz not null default now()
);

alter table recuperacao_senha enable row level security;
revoke all on recuperacao_senha from anon, authenticated;

-- 2. Cadastra/atualiza a resposta do usuário logado.
create or replace function public.definir_resposta_recuperacao(p_resposta text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'nao_autenticado';
  end if;
  if length(btrim(coalesce(p_resposta, ''))) < 3 then
    raise exception 'resposta_invalida';
  end if;

  insert into public.recuperacao_senha (usuario_id, resposta_hash)
  values (v_uid, extensions.crypt(p_resposta, extensions.gen_salt('bf', 10)))
  on conflict (usuario_id) do update
    set resposta_hash = excluded.resposta_hash,
        tentativas_falhas = 0,
        bloqueado_ate = null,
        atualizado_em = now();
end;
$$;

-- 3. Informa se o usuário logado já cadastrou a resposta (para o aviso na tela inicial).
create or replace function public.tem_resposta_recuperacao()
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (select 1 from public.recuperacao_senha where usuario_id = auth.uid());
$$;

-- 4. Redefine a senha de quem NÃO está logado, conferindo a resposta.
--    Retorna: 'ok' | 'incorreto' | 'bloqueado' | 'senha_invalida'.
--    Conta inexistente e conta sem resposta cadastrada retornam 'incorreto' (não revela
--    se o número está cadastrado).
create or replace function public.redefinir_senha_por_resposta(
  p_telefone text, p_resposta text, p_nova_senha text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text := regexp_replace(coalesce(p_telefone, ''), '[^0-9]', '', 'g') || '@ders.app';
  v_uid uuid;
  v_rec public.recuperacao_senha%rowtype;
begin
  if length(coalesce(p_nova_senha, '')) < 6 then
    return 'senha_invalida';
  end if;

  select id into v_uid from auth.users where email = v_email;
  if v_uid is null then
    return 'incorreto';
  end if;

  select * into v_rec from public.recuperacao_senha where usuario_id = v_uid for update;
  if not found then
    return 'incorreto';
  end if;

  if v_rec.bloqueado_ate is not null and v_rec.bloqueado_ate > now() then
    return 'bloqueado';
  end if;

  if v_rec.resposta_hash = extensions.crypt(coalesce(p_resposta, ''), v_rec.resposta_hash) then
    update auth.users
       set encrypted_password = extensions.crypt(p_nova_senha, extensions.gen_salt('bf', 10)),
           updated_at = now()
     where id = v_uid;
    delete from auth.sessions where user_id = v_uid; -- encerra sessões abertas com a senha antiga
    update public.recuperacao_senha
       set tentativas_falhas = 0, bloqueado_ate = null
     where usuario_id = v_uid;
    return 'ok';
  end if;

  update public.recuperacao_senha
     set tentativas_falhas = case when tentativas_falhas + 1 >= 5 then 0 else tentativas_falhas + 1 end,
         bloqueado_ate = case when tentativas_falhas + 1 >= 5 then now() + interval '15 minutes' else bloqueado_ate end
   where usuario_id = v_uid;

  return case when v_rec.tentativas_falhas + 1 >= 5 then 'bloqueado' else 'incorreto' end;
end;
$$;

-- 5. Troca o telefone de login do usuário logado (e-mail interno + perfil).
--    Retorna: 'ok' | 'telefone_invalido' | 'telefone_em_uso'.
create or replace function public.alterar_telefone_login(p_novo_telefone text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_tel text := regexp_replace(coalesce(p_novo_telefone, ''), '[^0-9]', '', 'g');
  v_email text;
  v_email_antigo text;
begin
  if v_uid is null then
    raise exception 'nao_autenticado';
  end if;
  if length(v_tel) not in (10, 11) then
    return 'telefone_invalido';
  end if;

  v_email := v_tel || '@ders.app';
  if exists (select 1 from auth.users where email = v_email and id <> v_uid)
     or exists (
       select 1 from public.usuarios
        where regexp_replace(telefone, '[^0-9]', '', 'g') = v_tel and id <> v_uid
     ) then
    return 'telefone_em_uso';
  end if;

  select email into v_email_antigo from auth.users where id = v_uid;

  update auth.users set email = v_email, updated_at = now() where id = v_uid;
  update auth.identities
     set identity_data = jsonb_set(identity_data, '{email}', to_jsonb(v_email)),
         provider_id = case when provider_id = v_email_antigo then v_email else provider_id end,
         updated_at = now()
   where user_id = v_uid and provider = 'email';
  update public.usuarios set telefone = v_tel where id = v_uid;

  return 'ok';
end;
$$;

-- 6. Permissões: só quem precisa pode chamar cada função.
revoke execute on function public.definir_resposta_recuperacao(text) from public, anon, authenticated;
revoke execute on function public.tem_resposta_recuperacao() from public, anon, authenticated;
revoke execute on function public.redefinir_senha_por_resposta(text, text, text) from public, anon, authenticated;
revoke execute on function public.alterar_telefone_login(text) from public, anon, authenticated;

grant execute on function public.definir_resposta_recuperacao(text) to authenticated;
grant execute on function public.tem_resposta_recuperacao() to authenticated;
grant execute on function public.alterar_telefone_login(text) to authenticated;
grant execute on function public.redefinir_senha_por_resposta(text, text, text) to anon, authenticated;
