// Medição do "depois": mesma operação do baseline (listar equipamentos), agora
// passando pela camada de cache. Uso: dart run n2/benchmark_depois.dart [N]
import 'dart:convert';
import 'dart:io';

import 'package:viver_ativo/cache/cache_equipamentos.dart';

import 'cache/fonte_supabase_http.dart';

Future<Map<String, Object>> medir(int n, Future<void> Function() operacao) async {
  final tempos = <double>[];
  final total = Stopwatch()..start();
  for (var i = 0; i < n; i++) {
    final sw = Stopwatch()..start();
    await operacao();
    sw.stop();
    tempos.add(sw.elapsedMicroseconds / 1000.0);
  }
  total.stop();
  tempos.sort();
  double pct(double p) => tempos[((tempos.length - 1) * p).round()];
  double r(double v) => double.parse(v.toStringAsFixed(3));
  return {
    'N': n,
    'tempo_total_ms': r(total.elapsedMicroseconds / 1000.0),
    'tempo_medio_ms': r(total.elapsedMicroseconds / 1000.0 / n),
    'mediana_ms': r(pct(0.5)),
    'p95_ms': r(pct(0.95)),
    'min_ms': r(tempos.first),
    'max_ms': r(tempos.last),
  };
}

Future<void> main(List<String> args) async {
  final n = args.isNotEmpty ? int.parse(args.first) : 1000;
  final fonte = FonteSupabaseHttp();
  final arquivo = '${Directory.systemTemp.path}/viver_ativo_n2/cache_benchmark.json';
  File(arquivo).parent.createSync(recursive: true);
  if (File(arquivo).existsSync()) File(arquivo).deleteSync();

  // Primeira leitura (MISS): enche o cache.
  final cache = CacheEquipamentos(fonte: fonte, caminhoArquivo: arquivo);
  final miss = await medir(1, () async => cache.listar());

  // HIT em memória: o caso comum (app aberto, cache válido).
  final hitMemoria = await medir(n, () async => cache.listar());

  // HIT em arquivo: app reiniciado a cada chamada (lê e interpreta o JSON do disco).
  final hitArquivo = await medir(n, () async {
    await CacheEquipamentos(fonte: fonte, caminhoArquivo: arquivo).listar();
  });
  fonte.fechar();

  final resultado = {
    'operacao': 'listar equipamentos pela camada de cache',
    'ttl_s': 300,
    'tamanho_arquivo_bytes': File(arquivo).lengthSync(),
    'primeira_leitura_miss': miss,
    'hit_memoria': hitMemoria,
    'hit_arquivo': hitArquivo,
    'data': DateTime.now().toIso8601String(),
  };
  final json = const JsonEncoder.withIndent('  ').convert(resultado);
  File('n2/depois_resultado.json').writeAsStringSync(json);
  stdout.writeln(json);
}
