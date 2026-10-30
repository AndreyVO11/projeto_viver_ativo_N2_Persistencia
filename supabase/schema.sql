-- Schema relacional do app Viver Ativo (substitui o Firestore por PostgreSQL/Supabase).
-- Corresponde ao Diagrama de Entidade e Relacionamento do DERS (seção 2.10.2).
--
-- Como usar: cole este arquivo inteiro no SQL Editor do Supabase (Project > SQL Editor >
-- New query) e clique em "Run". Pode rodar mais de uma vez se precisar recriar do zero
-- (os DROP TABLE no início cuidam disso).
--
-- Observação de segurança: por simplicidade nesta fase acadêmica/de testes, o Row Level
-- Security (RLS) fica DESABILITADO nestas tabelas — equivalente ao "modo de teste" que
-- usávamos no Firestore/Storage. Qualquer cliente com a anon key consegue ler/escrever.
-- Antes de uma publicação real, adicionar políticas RLS (ex: só admin escreve em
-- equipamentos) é o próximo passo recomendado.
--
-- Atenção: o Supabase habilita RLS automaticamente em toda tabela nova por padrão de
-- segurança da plataforma (mesmo criada via SQL puro) — por isso este script desabilita
-- explicitamente no final, depois de criar todas as tabelas.

drop table if exists equipamento_beneficios cascade;
drop table if exists equipamento_grupo_muscular cascade;
drop table if exists usuario_condicao_saude cascade;
drop table if exists equipamentos cascade;
drop table if exists grupos_musculares cascade;
drop table if exists condicoes_saude cascade;
drop table if exists usuarios cascade;

-- RF001 - Manter Usuários. O id é o mesmo id gerado pelo Supabase Auth (auth.users).
create table usuarios (
  id uuid primary key references auth.users (id) on delete cascade,
  nome text not null,
  telefone text not null unique,
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);

-- Tabela de referência para as condições de saúde exibidas no cadastro (RF001, Quadro 12).
create table condicoes_saude (
  id uuid primary key default gen_random_uuid(),
  nome text not null unique
);

insert into condicoes_saude (nome) values
  ('Nenhuma'),
  ('Hipertensão'),
  ('Diabetes'),
  ('Artrose'),
  ('Problemas no joelho'),
  ('Problemas na coluna'),
  ('Osteoporose'),
  ('Problemas cardíacos'),
  ('Labirintite / tontura');

-- Junção N:N entre usuários e condições de saúde.
create table usuario_condicao_saude (
  usuario_id uuid not null references usuarios (id) on delete cascade,
  condicao_saude_id uuid not null references condicoes_saude (id) on delete cascade,
  primary key (usuario_id, condicao_saude_id)
);

-- Tabela de referência para os grupos musculares (RN001, Quadro 17).
create table grupos_musculares (
  id uuid primary key default gen_random_uuid(),
  nome text not null unique
);

insert into grupos_musculares (nome) values
  ('Pernas'),
  ('Costas'),
  ('Braços'),
  ('Peito'),
  ('Abdômen'),
  ('Ombros'),
  ('Glúteos'),
  ('Cardio');

-- RF003 - Manter Equipamentos.
create table equipamentos (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  imagem_url text not null default '',
  nivel_dificuldade text not null check (nivel_dificuldade in ('Fácil', 'Médio', 'Difícil')),
  descricao text not null default '',
  para_que_serve text not null default '',
  dica_de_ouro text not null default '',
  -- RN002: todo equipamento precisa de ao menos uma instrução e um aviso.
  instrucao_uso text not null,
  aviso_seguranca text not null,
  created_at timestamptz not null default now()
);

-- Junção N:N entre equipamentos e grupos musculares (RN001).
create table equipamento_grupo_muscular (
  equipamento_id uuid not null references equipamentos (id) on delete cascade,
  grupo_muscular_id uuid not null references grupos_musculares (id) on delete cascade,
  primary key (equipamento_id, grupo_muscular_id)
);

-- 1:N entre equipamentos e seus benefícios (RF005, Quadro 20).
create table equipamento_beneficios (
  id uuid primary key default gen_random_uuid(),
  equipamento_id uuid not null references equipamentos (id) on delete cascade,
  descricao text not null,
  ordem int not null default 0
);

-- Seed: recria o equipamento de teste que já existia no Firestore ("Simulador de Caminhada"),
-- para você continuar testando sem precisar recadastrar tudo pela UI.
with novo_equipamento as (
  insert into equipamentos (
    nome, imagem_url, nivel_dificuldade, descricao, para_que_serve, dica_de_ouro,
    instrucao_uso, aviso_seguranca
  ) values (
    'Simulador de Caminhada',
    '',
    'Fácil',
    'Equipamento que simula o movimento natural da caminhada, ideal para o aquecimento inicial e para exercícios cardiovasculares de baixo impacto.',
    'Trabalha a resistência cardiovascular e a mobilidade das pernas, fortalecendo a musculatura das coxas e panturrilhas através do movimento alternado dos pedais.',
    'Comece sempre em ritmo lento por 1 a 2 minutos antes de acelerar o movimento, e mantenha a coluna ereta durante todo o exercício.',
    '1. Segure-se firmemente nas barras de apoio com as duas mãos antes de subir no equipamento.
2. Posicione os pés sobre os pedais, um em cada lado.
3. Movimente as pernas para frente e para trás, alternadamente, como se estivesse caminhando.
4. Mantenha um ritmo constante e controlado, sem movimentos bruscos ou muito rápidos.
5. Realize de 5 a 10 minutos de uso contínuo, respeitando o próprio limite.
6. Ao descer, espere o equipamento parar completamente e desça com cuidado, sempre apoiado nas barras.',
    'Antes de iniciar, faça um aquecimento prévio de ao menos 5 minutos. Não utilize o equipamento em caso de tontura, labirintite ou dores articulares sem orientação médica. Mantenha sempre um ponto de apoio nas barras durante todo o movimento e evite acelerar bruscamente. Em caso de dor, tontura ou falta de ar, pare imediatamente o exercício.'
  )
  returning id
)
insert into equipamento_grupo_muscular (equipamento_id, grupo_muscular_id)
select novo_equipamento.id, grupos_musculares.id
from novo_equipamento, grupos_musculares
where grupos_musculares.nome in ('Pernas', 'Cardio');

insert into equipamento_beneficios (equipamento_id, descricao, ordem)
select id, beneficio, ordem
from equipamentos,
  (values
    ('Melhora a circulação sanguínea e a saúde do coração', 0),
    ('Fortalece a musculatura das pernas e panturrilhas', 1),
    ('Baixo impacto nas articulações dos joelhos e quadris', 2),
    ('Ajuda na manutenção do equilíbrio e da coordenação motora', 3)
  ) as beneficios(beneficio, ordem)
where equipamentos.nome = 'Simulador de Caminhada';

-- O Supabase habilita RLS automaticamente em tabelas novas; desabilita aqui para manter
-- o comportamento de "modo de teste" descrito no topo deste arquivo.
alter table usuarios disable row level security;
alter table condicoes_saude disable row level security;
alter table usuario_condicao_saude disable row level security;
alter table grupos_musculares disable row level security;
alter table equipamentos disable row level security;
alter table equipamento_grupo_muscular disable row level security;
alter table equipamento_beneficios disable row level security;

-- storage.objects é uma tabela gerenciada pelo Supabase (compartilhada entre todos os
-- buckets do projeto) e não pode ter o RLS desabilitado por completo sem afetar outros
-- buckets. Em vez disso, cria políticas específicas para o bucket "equipamentos": mesmo
-- marcado como público (o que só libera leitura), upload/edição/exclusão continuam
-- bloqueados por padrão até existir uma política explícita.
drop policy if exists "Leitura publica equipamentos" on storage.objects;
create policy "Leitura publica equipamentos"
on storage.objects for select
using (bucket_id = 'equipamentos');

drop policy if exists "Upload equipamentos" on storage.objects;
create policy "Upload equipamentos"
on storage.objects for insert
with check (bucket_id = 'equipamentos');

drop policy if exists "Atualizar equipamentos" on storage.objects;
create policy "Atualizar equipamentos"
on storage.objects for update
using (bucket_id = 'equipamentos');

drop policy if exists "Excluir equipamentos" on storage.objects;
create policy "Excluir equipamentos"
on storage.objects for delete
using (bucket_id = 'equipamentos');
