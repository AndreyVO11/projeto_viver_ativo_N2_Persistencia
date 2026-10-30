# Projeto N2 — Camada de cache em arquivo (Viver Ativo)

Cache de leitura (cache-aside) da **lista de equipamentos**, em Dart puro: índice em memória + arquivo JSON
local, com TTL de 5 minutos. A fonte da verdade continua sendo o Supabase.

Caminho escolhido: **arquivo** (nenhum servidor ou Docker é necessário).
Desenho completo: `semana2_modelagem_camada.docx` e `semana2_diagrama_cache.png`.

## Pré-requisitos

- Flutter/Dart instalados (`dart --version`).
- Rodar a partir da raiz deste repositório (branch `n2-persistencia`): `flutter pub get`.
- Internet (as demonstrações leem do Supabase; nenhuma delas grava no banco).

## Como rodar

| O que | Comando |
|---|---|
| Testes da camada (10 testes, fonte falsa, sem rede) | `flutter test test/n2` |
| Todos os testes do projeto (152) | `flutter test --concurrency=1` |
| Demonstração: MISS, HIT em memória, HIT em arquivo e invalidação | `dart run n2/demo_cache.dart` |
| Baseline ("antes", sem cache) | `dart run n2/benchmark_baseline.dart 1000` |
| Medição do "depois" (com cache) | `dart run n2/benchmark_depois.dart 1000` |

Os resultados brutos ficam em `n2/baseline_resultado.json` e `n2/depois_resultado.json`.

## Como funciona

- **Leitura** (`CacheEquipamentos.listar()`): memória válida → HIT; senão arquivo válido → HIT (carrega na
  memória); senão MISS → consulta o Supabase, grava o arquivo (temporário + renomear) e a memória.
- **Detalhe** (`porId`): usa o índice em memória, sem nova consulta.
- **Escrita** (`atualizar` / `excluir`): grava **primeiro** na fonte da verdade e só então apaga a chave
  (memória e arquivo). Se a gravação falhar, o cache não é apagado.
- **TTL**: 5 minutos, como rede de segurança (outros aparelhos só percebem alterações quando o TTL vence).
- **Proteções**: leituras simultâneas com cache vazio dividem uma única consulta; invalidar durante uma
  consulta em andamento impede que o resultado velho seja guardado; arquivo corrompido vira MISS.

## Arquivos

- `lib/cache/cache_equipamentos.dart` — a camada de cache (Dart puro).
- `lib/cache/fonte_equipamentos*.dart` — fonte da verdade (interface; implementação Supabase do app).
- `n2/cache/fonte_supabase_http.dart` — fonte via `dart:io`, usada pelos scripts.
- `test/n2/cache_equipamentos_test.dart` — testes.
- `n2/demo_cache.dart`, `n2/benchmark_baseline.dart`, `n2/benchmark_depois.dart` — demonstração e medições.

## Status

A camada está **integrada ao app** (branch `n2-persistencia`, a partir do TFC atual): `EquipamentoRepository` e
`InstrucaoRepository` usam `lib/cache/cache_equipamentos.dart`; salvar/excluir equipamento e salvar/excluir
instrução invalidam o cache; puxar a lista para baixo força nova consulta. A tela **Equipamentos** mostra uma
faixa com o caminho (MISS / HIT em memória / HIT em arquivo) e o tempo da leitura.

## Como rodar o app com o cache

```
flutter pub get
flutter run -d emulator-5554     # ou outro dispositivo; abrir Equipamentos duas vezes e comparar a faixa amarela
```

O arquivo fica na pasta de suporte do app (`cache_equipamentos.json`); o log `[cache] ...` aparece no console.

## Demonstração da invalidação na escrita (sem mexer nos dados reais)

`dart run n2/demo_escrita.dart` cria um equipamento de teste, mostra o cache sendo invalidado, mostra o dado
velho que apareceria se a escrita não invalidasse, e apaga o equipamento de teste no final.

## Medição final (30/10/2026, N = 1.000, mesma máquina, "antes" e "depois" em sequência)

| Cenário | Média | Mediana | Ganho (média) |
|---|---|---|---|
| Antes: consulta direta ao Supabase | 269,03 ms | 63,50 ms | — |
| Depois: HIT em memória | 0,024 ms | 0,015 ms | ~11.200× |
| Depois: HIT em arquivo (app reiniciado) | 0,872 ms | 0,748 ms | ~310× |
| Primeira leitura (MISS), uma vez | 815,85 ms | — | mais lenta (conexão fria + gravação do arquivo) |

O "antes" varia com a rede: 46,12 ms (10/10), 45,03 ms (20/10) e 269,03 ms (30/10, rede instável, p95 706 ms).
Resultados brutos em `baseline_resultado*.json` e `depois_resultado*.json`; ficha de medição em `entrega/ficha_de_medicao.docx`.
