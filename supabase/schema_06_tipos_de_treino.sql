-- Migração incremental: tipos de treino (Pernas, Braços, ...), usados no filtro da
-- lista de treinos. Não apaga nada existente. Cole no SQL Editor do Supabase e rode
-- uma única vez.

-- 1. Junção N:N entre treinos e grupos musculares (mesmo padrão de equipamento_grupo_muscular).
create table if not exists treino_grupo_muscular (
  treino_id uuid not null references treinos (id) on delete cascade,
  grupo_muscular_id uuid not null references grupos_musculares (id) on delete cascade,
  primary key (treino_id, grupo_muscular_id)
);

-- Mesmo padrão de "modo de teste" das demais tabelas de catálogo.
alter table treino_grupo_muscular disable row level security;

-- 2. Tipos dos treinos que já existem (pelo nome do treino). O administrador pode
-- alterá-los depois em "Gerenciar Treinos".
insert into treino_grupo_muscular (treino_id, grupo_muscular_id)
select t.id, g.id
from (values
  ('Treino Iniciante', 'Pernas'),
  ('Treino Iniciante', 'Costas'),
  ('Treino Iniciante', 'Ombros'),
  ('Treino Iniciante', 'Abdômen'),
  ('Treino Cardio Leve', 'Cardio'),
  ('Treino Cardio Leve', 'Pernas'),
  ('Treino de Mobilidade e Postura', 'Costas'),
  ('Treino de Mobilidade e Postura', 'Abdômen'),
  ('Treino de Mobilidade e Postura', 'Ombros'),
  ('Treino de Parte Superior', 'Braços'),
  ('Treino de Parte Superior', 'Costas'),
  ('Treino de Parte Superior', 'Ombros'),
  ('Treino de Parte Superior', 'Peito'), 
  ('Treino de Pernas e Equilíbrio', 'Pernas'),
  ('Treino de Pernas e Equilíbrio', 'Glúteos'),
  ('Treino Desafio (Avançado)', 'Pernas'),
  ('Treino Desafio (Avançado)', 'Braços'),
  ('Treino Desafio (Avançado)', 'Peito'),
  ('Treino Desafio (Avançado)', 'Cardio')
) as v (treino, grupo)
join treinos t on t.nome = v.treino
join grupos_musculares g on g.nome = v.grupo
on conflict do nothing;
