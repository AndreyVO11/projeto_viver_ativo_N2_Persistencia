import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:viver_ativo/cache/cache_equipamentos.dart';
import 'package:viver_ativo/cache/fonte_equipamentos.dart';

class FonteFalsa implements FonteEscritaEquipamentos {
  List<Map<String, dynamic>> dados = [
    {'id': 'a', 'nome': 'Bicicleta Fixa'},
    {'id': 'b', 'nome': 'Remada Sentada'},
  ];
  int listagens = 0;
  final eventos = <String>[];
  bool falharNaEscrita = false;
  Completer<void>? segurarListagem;

  @override
  Future<List<Map<String, dynamic>>> listar() async {
    listagens++;
    final copia = [for (final e in dados) Map<String, dynamic>.from(e)];
    if (segurarListagem != null) await segurarListagem!.future;
    return copia;
  }

  @override
  Future<void> atualizar(Map<String, dynamic> equipamento) async {
    if (falharNaEscrita) throw StateError('falha de rede');
    eventos.add('fonte.atualizar');
    dados = [for (final e in dados) e['id'] == equipamento['id'] ? {...e, ...equipamento} : e];
  }

  @override
  Future<void> excluir(String id) async {
    if (falharNaEscrita) throw StateError('falha de rede');
    eventos.add('fonte.excluir');
    dados = dados.where((e) => e['id'] != id).toList();
  }
}

void main() {
  late Directory pasta;
  late String arquivo;
  late FonteFalsa fonte;
  var agora = DateTime(2026, 10, 20, 10);

  CacheEquipamentos novoCache() => CacheEquipamentos(fonte: fonte, caminhoArquivo: arquivo, agora: () => agora);

  setUp(() {
    pasta = Directory.systemTemp.createTempSync('cache_n2_');
    arquivo = '${pasta.path}/cache_equipamentos.json';
    fonte = FonteFalsa();
    agora = DateTime(2026, 10, 20, 10);
  });
  tearDown(() => pasta.deleteSync(recursive: true));

  test('primeira leitura é MISS, a segunda é HIT em memória (a fonte é consultada uma vez)', () async {
    final cache = novoCache();
    await cache.listar();
    expect(cache.ultimoCaminho, Caminho.miss);
    await cache.listar();
    expect(cache.ultimoCaminho, Caminho.hitMemoria);
    expect(fonte.listagens, 1);
    expect([cache.hits, cache.misses], [1, 1]);
  });

  test('o arquivo sobrevive ao reinício: nova instância lê do arquivo (HIT em arquivo)', () async {
    await novoCache().listar();
    final reiniciado = novoCache();
    final lista = await reiniciado.listar();
    expect(reiniciado.ultimoCaminho, Caminho.hitArquivo);
    expect(lista.map((e) => e['nome']), ['Bicicleta Fixa', 'Remada Sentada']);
    expect(fonte.listagens, 1);
  });

  test('passado o TTL (5 min) a cópia expira e a leitura volta a ser MISS', () async {
    final cache = novoCache();
    await cache.listar();
    agora = agora.add(const Duration(minutes: 4, seconds: 59));
    await cache.listar();
    expect(cache.ultimoCaminho, Caminho.hitMemoria);
    agora = agora.add(const Duration(seconds: 2));
    await cache.listar();
    expect(cache.ultimoCaminho, Caminho.miss);
    expect(fonte.listagens, 2);
  });

  test('escrita: grava na fonte e invalida; a leitura seguinte traz o dado novo', () async {
    final cache = novoCache();
    await cache.listar();
    await cache.escrever(() => fonte.atualizar({'id': 'a', 'nome': 'Bicicleta Fixa 2'}));
    expect(File(arquivo).existsSync(), isFalse);
    final lista = await cache.listar();
    expect(cache.ultimoCaminho, Caminho.miss);
    expect(lista.first['nome'], 'Bicicleta Fixa 2');
  });

  test('exclusão também invalida', () async {
    final cache = novoCache();
    await cache.listar();
    await cache.escrever(() => fonte.excluir('b'));
    final lista = await cache.listar();
    expect(lista.map((e) => e['id']), ['a']);
  });

  test('se a gravação na fonte falha, o cache NÃO é apagado (cache-aside)', () async {
    final cache = novoCache();
    await cache.listar();
    fonte.falharNaEscrita = true;
    await expectLater(cache.escrever(() => fonte.atualizar({'id': 'a', 'nome': 'x'})), throwsStateError);
    expect(File(arquivo).existsSync(), isTrue);
    await cache.listar();
    expect(cache.ultimoCaminho, Caminho.hitMemoria);
  });

  test('arquivo corrompido não derruba o app: vira MISS e é regravado', () async {
    File(arquivo).writeAsStringSync('{ isso não é json');
    final cache = novoCache();
    final lista = await cache.listar();
    expect(cache.ultimoCaminho, Caminho.miss);
    expect(lista, hasLength(2));
    expect(novoCache().listar(), completion(hasLength(2)));
  });

  test('leituras simultâneas com cache vazio compartilham uma única consulta', () async {
    final cache = novoCache();
    final resultados = await Future.wait([cache.listar(), cache.listar(), cache.listar()]);
    expect(resultados, everyElement(hasLength(2)));
    expect(fonte.listagens, 1);
  });

  test('invalidação durante uma consulta em andamento não grava dado velho no cache', () async {
    final cache = novoCache();
    fonte.segurarListagem = Completer<void>();
    final leitura = cache.listar();
    await Future<void>.delayed(Duration.zero);
    await cache.invalidar();
    fonte.segurarListagem!.complete();
    await leitura;
    expect(File(arquivo).existsSync(), isFalse);
  });

  test('detalhe por id usa o índice em memória, sem nova consulta', () async {
    final cache = novoCache();
    await cache.listar();
    expect((await cache.porId('b'))?['nome'], 'Remada Sentada');
    expect(await cache.porId('zzz'), isNull);
    expect(fonte.listagens, 1);
  });
}
