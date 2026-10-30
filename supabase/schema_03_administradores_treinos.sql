-- Migração incremental: RF008 (Administradores) + RF009 (Treinos).
-- Não apaga nada existente. Cole no SQL Editor do Supabase e rode uma única vez.

-- 1. RF008 - distingue o administrador inicial (único que pode gerenciar outros admins)
-- do administrador comum (is_admin).
alter table usuarios add column is_admin_inicial boolean not null default false;

-- 2. RF009 - Treinos, compostos por exercícios já cadastrados (RF006), em ordem definida.
create table treinos (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  descricao text not null default '',
  created_at timestamptz not null default now()
);

create table treino_exercicio (
  treino_id uuid not null references treinos (id) on delete cascade,
  exercicio_id uuid not null references exercicios (id) on delete cascade,
  ordem int not null default 0,
  primary key (treino_id, exercicio_id)
);

-- Histórico de exercícios concluídos pelo usuário dentro de um treino (RF009, fluxo A1).
create table historico_execucoes (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references usuarios (id) on delete cascade,
  treino_id uuid not null references treinos (id) on delete cascade,
  exercicio_id uuid not null references exercicios (id) on delete cascade,
  concluido_em timestamptz not null default now()
);

-- Mesmo padrão de "modo de teste" das demais tabelas (ver schema.sql original): o Supabase
-- habilita RLS automaticamente em tabelas novas, então desabilita aqui.
alter table treinos disable row level security;
alter table treino_exercicio disable row level security;
alter table historico_execucoes disable row level security;
