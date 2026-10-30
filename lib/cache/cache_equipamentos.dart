import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'fonte_equipamentos.dart';

enum Caminho { hitMemoria, hitArquivo, miss }

/// Cache de leitura (cache-aside) da lista de equipamentos: índice em memória
/// + arquivo JSON, com TTL. A fonte da verdade continua sendo a [fonte].
///
/// Chave lógica: `equipamentos:lista`. Leitura: memória -> arquivo -> fonte
/// (HIT/MISS). Escrita: grava primeiro na fonte e só então invalida o cache.
class CacheEquipamentos {
  CacheEquipamentos({
    required this.fonte,
    required this.caminhoArquivo,
    this.ttl = const Duration(minutes: 5),
    DateTime Function()? agora,
    this.registrar,
  }) : _agora = agora ?? DateTime.now;

  static const chave = 'equipamentos:lista';
  static const _versao = 1;

  final FonteEquipamentos fonte;
  final String caminhoArquivo;
  final Duration ttl;
  final DateTime Function() _agora;

  /// Recebe uma linha de log a cada leitura (no app: debugPrint).
  final void Function(String mensagem)? registrar;

  List<Map<String, dynamic>>? _lista;
  Map<String, Map<String, dynamic>>? _indice;
  DateTime? _gravadoEm;
  Future<List<Map<String, dynamic>>>? _emAndamento;
  int _geracao = 0;

  int hits = 0;
  int misses = 0;
  Caminho? ultimoCaminho;
  double? ultimoTempoMs;

  bool _valido(DateTime gravadoEm) => _agora().isBefore(gravadoEm.add(ttl));

  /// Lista de equipamentos ordenada por nome (HIT em memória, HIT em arquivo ou MISS).
  Future<List<Map<String, dynamic>>> listar() async {
    final cronometro = Stopwatch()..start();
    final lista = await _listar();
    cronometro.stop();
    ultimoTempoMs = cronometro.elapsedMicroseconds / 1000.0;
    registrar?.call('[cache] ${descricaoCaminho(ultimoCaminho!)} em ${ultimoTempoMs!.toStringAsFixed(2)} ms (${lista.length} equipamentos)');
    return lista;
  }

  static String descricaoCaminho(Caminho c) => switch (c) {
        Caminho.hitMemoria => 'HIT em memória',
        Caminho.hitArquivo => 'HIT em arquivo',
        Caminho.miss => 'MISS (consulta ao Supabase)',
      };

  Future<List<Map<String, dynamic>>> _listar() {
    final gravadoEm = _gravadoEm;
    if (_lista != null && gravadoEm != null && _valido(gravadoEm)) {
      hits++;
      ultimoCaminho = Caminho.hitMemoria;
      return Future.value(_lista);
    }
    // Leituras simultâneas compartilham a mesma consulta em andamento.
    return _emAndamento ??= _carregar().whenComplete(() => _emAndamento = null);
  }

  /// Detalhe de um equipamento, pelo índice em memória (sem nova consulta).
  Future<Map<String, dynamic>?> porId(String id) async {
    await listar();
    return _indice?[id];
  }

  /// Escrita (cache-aside): executa a gravação na fonte da verdade primeiro; o
  /// cache só é apagado se ela deu certo.
  Future<void> escrever(Future<void> Function() gravarNaFonte) async {
    await gravarNaFonte();
    await invalidar();
  }

  /// Apaga a chave (memória + arquivo).
  Future<void> invalidar() async {
    _geracao++;
    _lista = null;
    _indice = null;
    _gravadoEm = null;
    final arquivo = File(caminhoArquivo);
    if (await arquivo.exists()) await arquivo.delete();
  }

  Future<List<Map<String, dynamic>>> _carregar() async {
    final doArquivo = await _lerArquivo();
    if (doArquivo != null) {
      hits++;
      ultimoCaminho = Caminho.hitArquivo;
      return doArquivo;
    }
    misses++;
    ultimoCaminho = Caminho.miss;
    final geracao = _geracao;
    final lista = await fonte.listar();
    // Se o cache foi invalidado durante a consulta, o resultado pode estar velho: não guarda.
    if (geracao == _geracao) await _guardar(lista);
    return lista;
  }

  void _definirMemoria(List<Map<String, dynamic>> lista, DateTime gravadoEm) {
    _lista = lista;
    _indice = {for (final e in lista) e['id'] as String: e};
    _gravadoEm = gravadoEm;
  }

  Future<List<Map<String, dynamic>>?> _lerArquivo() async {
    try {
      final arquivo = File(caminhoArquivo);
      if (!await arquivo.exists()) return null;
      final doc = jsonDecode(await arquivo.readAsString()) as Map<String, dynamic>;
      if (doc['versao'] != _versao) return null;
      final gravadoEm = DateTime.parse(doc['gravadoEm'] as String);
      if (!_valido(gravadoEm)) return null;
      final lista = (doc['equipamentos'] as List).cast<Map<String, dynamic>>();
      _definirMemoria(lista, gravadoEm);
      return lista;
    } on Object {
      return null; // arquivo corrompido ou ilegível: trata como MISS
    }
  }

  Future<void> _guardar(List<Map<String, dynamic>> lista) async {
    final gravadoEm = _agora();
    _definirMemoria(lista, gravadoEm);
    final doc = jsonEncode({
      'versao': _versao,
      'chave': chave,
      'gravadoEm': gravadoEm.toIso8601String(),
      'ttlSegundos': ttl.inSeconds,
      'equipamentos': lista,
    });
    final arquivo = File(caminhoArquivo);
    await arquivo.parent.create(recursive: true);
    // Grava em arquivo temporário e renomeia: nunca fica um arquivo pela metade.
    final temporario = File('$caminhoArquivo.tmp');
    await temporario.writeAsString(doc, flush: true);
    await temporario.rename(caminhoArquivo);
  }
}
