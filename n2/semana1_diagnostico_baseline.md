# Projeto N2 — Semana 1: Diagnóstico e Baseline

Disciplina ESW441 · Turma A · Prof. Gustavo Martins Lima
Trio: _[preencher os 3 integrantes]_

## 1. Sistema escolhido

**Viver Ativo** (TFC de Andrey Vieira de Oliveira): aplicativo Flutter/Android que orienta idosos no uso
seguro de academias públicas ao ar livre. Backend: Supabase (PostgreSQL relacional + API REST/PostgREST).

## 2. Ponto de dor (uma frase)

> Hoje o sistema, a cada abertura da tela **Equipamentos**, faz uma consulta remota ao Supabase com join em
> 3 tabelas relacionadas (~21 KB de resposta), e isso é lento e frágil porque **depende de rede a cada
> leitura**, repete um resultado que quase nunca muda e **não funciona sem internet**.

## 3. Hipótese de caminho (pode mudar na semana 2)

Camada de cache de leitura (padrão cache-aside) para a lista de equipamentos:

1. **Arquivo local (JSON) no dispositivo** — hipótese principal: o app é móvel, sem servidor próprio, e o
   dado muda raramente; também resolveria o uso offline.
2. MongoDB ou Redis — alternativas a avaliar na semana 2 (exigiriam um servidor intermediário, que o
   projeto hoje não tem).

Pontos a modelar na semana 2: estrutura do arquivo/chave, e **invalidação** do cache quando o administrador
cadastra, edita ou exclui equipamento, instrução ou exercício.

## 4. Baseline (o "antes")

| Item | Valor |
|---|---|
| Operação medida | `GET /equipamentos` com join (grupos musculares, benefícios, instruções), ordenado por nome — mesma consulta de `EquipamentoRepository.buscarEquipamentos()` |
| **Tempo médio** | **46,12 ms por operação** |
| N (repetições) | 1.000, sequenciais, mais 5 de aquecimento fora da média |
| Tempo total | 46,12 s |
| Mediana / p95 / mín / máx | 43,52 ms / 63,35 ms / 35,93 ms / 153,65 ms |
| Tamanho dos dados | 11 equipamentos, 22 exercícios, 6 treinos no banco; resposta de 21.118 bytes |
| Máquina | AMD Ryzen 7 5825U (8 núcleos/16 threads), 31,4 GB RAM, Windows 11 |
| Rede | Internet residencial, banco Supabase remoto (plano gratuito) |
| Data | 10/10/2026 |

Reprodução: `dart run n2/benchmark_baseline.dart 1000` (resultado bruto em `n2/baseline_resultado.json`).

### Cuidado com o número

O tempo é dominado pela **rede**, então varia com o momento. Uma rodada preliminar de apenas 20 repetições
deu média de ~249 ms (conexão fria e rede mais lenta naquele instante), contra 46 ms nas 1.000 repetições.
Para a comparação "depois" valer, a medição final deve usar o mesmo script, a mesma operação, o mesmo N e
preferencialmente rodar o "antes" de novo no mesmo dia, em condições de rede parecidas.
