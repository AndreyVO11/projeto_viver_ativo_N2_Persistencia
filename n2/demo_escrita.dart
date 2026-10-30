// Demonstração da INVALIDAÇÃO NA ESCRITA contra o Supabase real.
// Cria um equipamento de TESTE ("ZZ Teste N2"), mostra o cache sendo invalidado e
// apaga o equipamento no final. Não mexe nos equipamentos reais.
// Uso: dart run n2/demo_escrita.dart
import 'dart:io';

import 'package:viver_ativo/cache/cache_equipamentos.dart';

import 'cache/fonte_supabase_http.dart';

Future<void> main() async {
  final fonte = FonteSupabaseHttp();
  final arquivo = '${Directory.systemTemp.path}/viver_ativo_n2/cache_demo_escrita.json';
  File(arquivo).parent.createSync(recursive: true);
  if (File(arquivo).existsSync()) File(arquivo).deleteSync();
  final cache = CacheEquipamentos(fonte: fonte, caminhoArquivo: arquivo);

  Future<void> ler(String titulo, String id) async {
    final lista = await cache.listar();
    final nome = lista.where((e) => e['id'] == id).map((e) => e['nome']).firstOrNull ?? '(não existe)';
    final ms = cache.ultimoTempoMs!.toStringAsFixed(2).padLeft(8);
    stdout.writeln('${titulo.padRight(52)} ${CacheEquipamentos.descricaoCaminho(cache.ultimoCaminho!).padRight(30)} $ms ms | nome: $nome');
  }

  final id = await fonte.inserir({
    'nome': 'ZZ Teste N2 (original)',
    'nivel_dificuldade': 'Fácil',
    'descricao': 'Equipamento de teste da demonstração; é apagado no final.',
  });
  try {
    await ler('1. primeira leitura', id);
    await ler('2. segunda leitura', id);

    stdout.writeln('\n--- escrita CORRETA: grava na fonte e invalida ---');
    await cache.escrever(() => fonte.atualizar({'id': id, 'nome': 'ZZ Teste N2 (editado)'}));
    await ler('3. leitura depois da escrita', id);

    stdout.writeln('\n--- contra-exemplo: escrita SEM invalidar (o problema que o cache resolve) ---');
    await fonte.atualizar({'id': id, 'nome': 'ZZ Teste N2 (alterado por fora)'});
    await ler('4. leitura sem invalidar -> dado VELHO', id);
    await cache.invalidar();
    await ler('5. depois de invalidar -> dado novo', id);
  } finally {
    await cache.escrever(() => fonte.excluir(id));
    await ler('\n6. teste apagado; leitura confirma', id);
    fonte.fechar();
  }
}
