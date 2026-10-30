-- Migração incremental: RF006 (Exercícios) + RF007 (Instruções/Avisos separados).
-- Diferente do schema.sql original, este arquivo NÃO apaga nada — só adiciona/migra.
-- Cole no SQL Editor do Supabase e rode uma única vez.

-- 1. RF007 - normaliza instrução/aviso do equipamento (antes eram 2 campos únicos).
create table equipamento_instrucoes (
  id uuid primary key default gen_random_uuid(),
  equipamento_id uuid not null references equipamentos (id) on delete cascade,
  instrucao_uso text not null,
  aviso_seguranca text not null,
  created_at timestamptz not null default now()
);

-- Migra os dados existentes (o que já estava direto na tabela equipamentos vira a
-- primeira instrução de cada equipamento).
insert into equipamento_instrucoes (equipamento_id, instrucao_uso, aviso_seguranca)
select id, instrucao_uso, aviso_seguranca from equipamentos;

alter table equipamentos drop column instrucao_uso;
alter table equipamentos drop column aviso_seguranca;

-- 2. RF006 - Exercícios, sempre vinculados a um equipamento.
create table exercicios (
  id uuid primary key default gen_random_uuid(),
  equipamento_id uuid not null references equipamentos (id) on delete cascade,
  nome text not null,
  midia_url text not null default '',
  instrucoes_passo_a_passo text not null,
  orientacao_aquecimento text not null,
  created_at timestamptz not null default now()
);

-- Contraindicações reaproveitam a tabela condicoes_saude (já usada no perfil do usuário,
-- RF001) para cruzar automaticamente com o perfil de saúde no fluxo A3 do RF006.
create table exercicio_contraindicacao (
  exercicio_id uuid not null references exercicios (id) on delete cascade,
  condicao_saude_id uuid not null references condicoes_saude (id) on delete cascade,
  primary key (exercicio_id, condicao_saude_id)
);

-- Mesmo padrão de "modo de teste" das demais tabelas (ver schema.sql original).
alter table equipamento_instrucoes disable row level security;
alter table exercicios disable row level security;
alter table exercicio_contraindicacao disable row level security;
