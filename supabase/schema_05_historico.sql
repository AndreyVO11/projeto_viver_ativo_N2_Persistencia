-- Migração incremental: histórico de treinos e exercícios (RF009) com duração.
-- Não apaga dados existentes. Cole no SQL Editor do Supabase e rode uma única vez
-- (pode rodar de novo sem problemas).
--
-- O que muda:
--  * sessoes_treino: cada vez que a pessoa faz um treino (início, conclusão, quantos
--    exercícios o treino tinha).
--  * historico_execucoes: ganha a duração em segundos, a sessão a que pertence e uma
--    CÓPIA dos nomes do exercício e do treino.
--  * O histórico passa a sobreviver à exclusão de um exercício/treino pelo
--    administrador: as chaves viram "apagar = deixar em branco" e os nomes
--    copiados continuam aparecendo.
--  * Histórico é dado pessoal: as duas tabelas ficam com RLS LIGADO e cada usuário
--    só enxerga e grava o que é dele.

-- 1. Sessões de treino.
create table if not exists sessoes_treino (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references usuarios (id) on delete cascade,
  treino_id uuid references treinos (id) on delete set null,
  treino_nome text not null,
  total_exercicios int not null default 0,
  iniciado_em timestamptz not null default now(),
  concluido_em timestamptz
);

create index if not exists idx_sessoes_treino_usuario on sessoes_treino (usuario_id, iniciado_em desc);

-- 2. Novas colunas do histórico de exercícios.
alter table historico_execucoes add column if not exists sessao_id uuid references sessoes_treino (id) on delete cascade;
alter table historico_execucoes add column if not exists duracao_segundos int;
alter table historico_execucoes add column if not exists exercicio_nome text;
alter table historico_execucoes add column if not exists treino_nome text;

alter table historico_execucoes alter column treino_id drop not null;
alter table historico_execucoes alter column exercicio_id drop not null;

-- 3. Troca as chaves "on delete cascade" (treino/exercício) por "on delete set null".
do $$
declare
  r record;
begin
  for r in
    select c.conname
      from pg_constraint c
     where c.conrelid = 'public.historico_execucoes'::regclass
       and c.contype = 'f'
       and c.confrelid in ('public.treinos'::regclass, 'public.exercicios'::regclass)
  loop
    execute format('alter table historico_execucoes drop constraint %I', r.conname);
  end loop;
end $$;

alter table historico_execucoes
  add constraint historico_execucoes_treino_id_fkey
  foreign key (treino_id) references treinos (id) on delete set null;
alter table historico_execucoes
  add constraint historico_execucoes_exercicio_id_fkey
  foreign key (exercicio_id) references exercicios (id) on delete set null;

-- 4. Preenche os nomes dos registros que já existiam.
update historico_execucoes h set exercicio_nome = e.nome
  from exercicios e where h.exercicio_id = e.id and h.exercicio_nome is null;
update historico_execucoes h set treino_nome = t.nome
  from treinos t where h.treino_id = t.id and h.treino_nome is null;

create index if not exists idx_historico_usuario on historico_execucoes (usuario_id, concluido_em desc);

-- 5. Privacidade: cada usuário vê e grava só o próprio histórico.
alter table sessoes_treino enable row level security;
alter table historico_execucoes enable row level security;

drop policy if exists "sessoes_do_proprio_usuario" on sessoes_treino;
create policy "sessoes_do_proprio_usuario" on sessoes_treino
  for all to authenticated
  using (usuario_id = auth.uid())
  with check (usuario_id = auth.uid());

drop policy if exists "historico_do_proprio_usuario" on historico_execucoes;
create policy "historico_do_proprio_usuario" on historico_execucoes
  for all to authenticated
  using (usuario_id = auth.uid())
  with check (usuario_id = auth.uid());

grant select, insert, update on sessoes_treino to authenticated;
grant select, insert, update on historico_execucoes to authenticated;
