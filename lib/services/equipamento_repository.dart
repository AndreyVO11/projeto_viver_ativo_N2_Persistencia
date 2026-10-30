import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../cache/cache_equipamentos.dart';
import '../cache/fonte_equipamentos_supabase.dart';
import '../models/equipamento_model.dart';

class EquipamentoRepository {
  /// [cache]: camada de cache de leitura do projeto N2 (opcional; sem ela o
  /// repositório consulta o Supabase direto, como antes).
  EquipamentoRepository({SupabaseClient? client, CacheEquipamentos? cache})
      : _client = client ?? Supabase.instance.client,
        _cache = cache;

  final SupabaseClient _client;
  final CacheEquipamentos? _cache;

  static const _selectCompleto = FonteEquipamentosSupabase.selectCompleto;


  /// RF004 - Visualizar Lista de Equipamentos (também alimenta RF003 - admin).
  /// Busca única (não é stream): joins com tabelas de junção não são
  /// suportados pelo Supabase Realtime, então a lista é recarregada
  /// manualmente (pull-to-refresh, ou após criar/editar/excluir).
  ///
  /// Com cache: HIT devolve sem rede; para ignorar a cópia, chame [invalidarCache] antes.
  Future<List<EquipamentoModel>> buscarEquipamentos() async {
    final cache = _cache;
    if (cache != null) {
      final linhas = await cache.listar();
      return linhas.map((linha) => EquipamentoModel.fromMap(linha['id'] as String, linha)).toList();
    }
    final linhas = await _client.from('equipamentos').select(_selectCompleto).order('nome');
    return linhas.map((linha) => EquipamentoModel.fromMap(linha['id'] as String, linha)).toList();
  }

  /// Apaga a cópia em cache (usado ao puxar a lista para baixo para atualizar).
  Future<void> invalidarCache() async => await _cache?.invalidar();

  Future<EquipamentoModel?> buscarPorId(String id) async {
    final doCache = await _cache?.porId(id);
    if (doCache != null) return EquipamentoModel.fromMap(id, doCache);
    final linha = await _client
        .from('equipamentos')
        .select(_selectCompleto)
        .eq('id', id)
        .maybeSingle();
    if (linha == null) return null;
    return EquipamentoModel.fromMap(id, linha);
  }

  /// Gera um id novo antecipadamente, para nomear a imagem no Storage antes
  /// de gravar a linha do equipamento.
  String novoId() => const Uuid().v4();

  /// RF003 - Cadastrar/Editar Equipamento, com os grupos musculares (N:N) e
  /// benefícios (1:N) sincronizados nas tabelas de junção.
  ///
  /// [instrucaoUsoInicial]/[avisoSegurancaInicial]: preenchidos apenas ao
  /// cadastrar um equipamento novo (Quadro 17 do RF003), viram a primeira
  /// instrução do equipamento (RN002). Edições subsequentes de instruções
  /// são feitas pelo `InstrucaoRepository` (RF007).
  Future<void> salvar(
    EquipamentoModel equipamento, {
    String? instrucaoUsoInicial,
    String? avisoSegurancaInicial,
  }) async {
    // Cache-aside: grava na fonte da verdade e só então invalida a cópia. Como são
    // vários passos, invalida também se algum falhar no meio (gravação parcial).
    try {
      await _salvarNaFonte(
        equipamento,
        instrucaoUsoInicial: instrucaoUsoInicial,
        avisoSegurancaInicial: avisoSegurancaInicial,
      );
    } finally {
      await _cache?.invalidar();
    }
  }

  Future<void> _salvarNaFonte(
    EquipamentoModel equipamento, {
    String? instrucaoUsoInicial,
    String? avisoSegurancaInicial,
  }) async {
    await _client.from('equipamentos').upsert({
      'id': equipamento.id,
      ...equipamento.toMap(),
    });

    await _client
        .from('equipamento_grupo_muscular')
        .delete()
        .eq('equipamento_id', equipamento.id);
    await _client.from('equipamento_beneficios').delete().eq('equipamento_id', equipamento.id);

    if (equipamento.gruposMusculares.isNotEmpty) {
      final grupos = await _client
          .from('grupos_musculares')
          .select('id')
          .inFilter('nome', equipamento.gruposMusculares);
      await _client.from('equipamento_grupo_muscular').insert([
        for (final grupo in grupos)
          {'equipamento_id': equipamento.id, 'grupo_muscular_id': grupo['id']},
      ]);
    }

    if (equipamento.beneficios.isNotEmpty) {
      await _client.from('equipamento_beneficios').insert([
        for (var i = 0; i < equipamento.beneficios.length; i++)
          {'equipamento_id': equipamento.id, 'descricao': equipamento.beneficios[i], 'ordem': i},
      ]);
    }

    if (instrucaoUsoInicial != null && avisoSegurancaInicial != null) {
      await _client.from('equipamento_instrucoes').insert({
        'equipamento_id': equipamento.id,
        'instrucao_uso': instrucaoUsoInicial,
        'aviso_seguranca': avisoSegurancaInicial,
      });
    }
  }

  /// RF003, fluxo A2 - Excluir Equipamento.
  Future<void> excluir(String id) async {
    await _client.from('equipamentos').delete().eq('id', id);
    await _cache?.invalidar();
  }
}
