# Projeto N2 — Camada de cache em arquivo no Viver Ativo

Disciplina ESW441 · Turma A · Prof. Gustavo Martins Lima · Entrega 03/11/2026

Integrantes: Andrey Vieira, Guilherme Marques Lima e Gabriel Cardoso

O **Viver Ativo** (aplicativo Flutter + Supabase que orienta idosos em academias ao ar livre) ganhou uma
**camada de cache de leitura em arquivo JSON + índice em memória** (cache-aside, TTL de 5 min, invalidação na
escrita) para a lista de equipamentos. O Supabase continua sendo a fonte da verdade.

## Resultado (30/10/2026, N = 1.000)

| Cenário | Média | Ganho |
|---|---|---|
| Antes: consulta direta ao Supabase | 269,03 ms | — |
| Depois: HIT em memória | 0,024 ms | ~11.200× |
| Depois: HIT em arquivo (app reiniciado) | 0,872 ms | ~310× |

Detalhes, condições do teste e ressalvas: [`n2/entrega/ficha_de_medicao.docx`](n2/entrega/ficha_de_medicao.docx).

## Como rodar

Pré-requisito: Flutter instalado (`flutter --version`) e internet.

```
flutter pub get
flutter test --concurrency=1          # 152 testes (10 deles da camada de cache)
flutter run -d <dispositivo>          # app com o cache; a tela Equipamentos mostra MISS/HIT e o tempo
dart run n2/demo_cache.dart           # MISS, HIT em memória, HIT em arquivo e invalidação
dart run n2/demo_escrita.dart         # invalidação na escrita (cria e apaga um equipamento de teste)
dart run n2/benchmark_baseline.dart 1000   # "antes"
dart run n2/benchmark_depois.dart 1000     # "depois"
```

O app e os scripts usam o projeto Supabase já configurado em `lib/supabase_config.dart` (chave publishable).
Não há servidor nem Docker: o caminho escolhido é **arquivo**.

## Onde está o quê

- `lib/cache/` — a camada de cache (Dart puro) e a fonte Supabase do app.
- `lib/services/equipamento_repository.dart`, `instrucao_repository.dart` — usam o cache e o invalidam nas escritas.
- `n2/` — README detalhado, scripts de demonstração e medição, documentos das semanas 1 a 4 e diagrama.
- `test/n2/` — testes da camada (fonte falsa, sem rede).
- `supabase/` — scripts SQL do banco do TFC.
