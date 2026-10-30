// Demonstração da camada de cache contra o Supabase real (somente leitura).
// Uso: dart run n2/demo_cache.dart
import 'dart:io';

import 'package:viver_ativo/cache/cache_equipamentos.dart';

import 'cache/fonte_supabase_http.dart';

Future<void> main() async {
  final fonte = FonteSupabaseHttp();
  final arquivo = '${Directory.systemTemp.path}/viver_ativo_n2/cache_equipamentos.json';
  File(arquivo).parent.createSync(recursive: true);
  if (File(arquivo).existsSync()) File(arquivo).deleteSync();

  Future<void> passo(String titulo, CacheEquipamentos cache) async {
    final sw = Stopwatch()..start();
    final lista = await cache.listar();
    sw.stop();
    final ms = (sw.elapsedMicroseconds / 1000).toStringAsFixed(2);
    stdout.writeln('${titulo.padRight(46)} ${cache.ultimoCaminho!.name.padRight(11)} ${ms.padLeft(8)} ms  (${lista.length} equipamentos)');
  }

  final cache = CacheEquipamentos(fonte: fonte, caminhoArquivo: arquivo);
  await passo('1. primeira leitura (cache vazio)', cache);
  await passo('2. segunda leitura', cache);
  await passo('3. app reiniciado (nova instância, mesmo arquivo)', CacheEquipamentos(fonte: fonte, caminhoArquivo: arquivo));
  await cache.invalidar();
  await passo('4. depois de invalidar (como após uma escrita)', cache);
  stdout.writeln('\nArquivo: $arquivo (${File(arquivo).lengthSync()} bytes)');
  fonte.fechar();
}
