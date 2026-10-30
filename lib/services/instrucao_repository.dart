import 'package:supabase_flutter/supabase_flutter.dart';

import '../cache/cache_equipamentos.dart';
import '../models/instrucao_model.dart';

/// RN002 - um equipamento nunca pode ficar sem nenhuma instrução/aviso.
/// Função pura (sem I/O) para poder validar a regra em teste unitário sem
/// precisar de um banco de dados.
bool podeExcluirInstrucao(int quantidadeAtualDeInstrucoes) => quantidadeAtualDeInstrucoes > 1;

/// RF007 - Manter Instrução de Uso e Aviso de Segurança.
class InstrucaoRepository {
  /// [cache]: as instruções fazem parte da consulta da lista de equipamentos
  /// (projeto N2), então toda escrita aqui invalida a cópia em cache.
  InstrucaoRepository({SupabaseClient? client, CacheEquipamentos? cache})
      : _client = client ?? Supabase.instance.client,
        _cache = cache;

  final SupabaseClient _client;
  final CacheEquipamentos? _cache;

  Future<List<InstrucaoModel>> buscarPorEquipamento(String equipamentoId) async {
    final linhas = await _client
        .from('equipamento_instrucoes')
        .select()
        .eq('equipamento_id', equipamentoId)
        .order('created_at');
    return linhas.map(InstrucaoModel.fromMap).toList();
  }

  /// Cadastrar/Editar uma instrução (Quadro 25/26).
  Future<void> salvar(InstrucaoModel instrucao) async {
    if (instrucao.id.isEmpty) {
      await _client.from('equipamento_instrucoes').insert(instrucao.toMap());
    } else {
      await _client.from('equipamento_instrucoes').update(instrucao.toMap()).eq('id', instrucao.id);
    }
    await _cache?.invalidar();
  }

  /// Fluxo A2/A3 - Excluir Instrução, bloqueado se for a única do equipamento
  /// (RN002: equipamento sempre precisa de ao menos uma instrução).
  Future<void> excluir(String id, String equipamentoId) async {
    final restantes = await buscarPorEquipamento(equipamentoId);
    if (!podeExcluirInstrucao(restantes.length)) {
      throw StateError(
        'O equipamento deve possuir ao menos uma instrução de uso e um aviso de segurança.',
      );
    }
    await _client.from('equipamento_instrucoes').delete().eq('id', id);
    await _cache?.invalidar();
  }
}
