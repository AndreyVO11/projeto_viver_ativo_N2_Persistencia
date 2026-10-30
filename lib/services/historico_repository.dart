import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/historico_model.dart';

/// Leitura do histórico do usuário logado. A gravação acontece durante a
/// execução de um treino, em `TreinoRepository`.
class HistoricoRepository {
  HistoricoRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _selectSessao = '''
    id, treino_nome, total_exercicios, iniciado_em, concluido_em,
    historico_execucoes ( id, exercicio_nome, treino_nome, duracao_segundos, concluido_em )
  ''';

  /// Treinos feitos, do mais recente para o mais antigo. Sessões em que nenhum
  /// exercício chegou a ser concluído não aparecem.
  Future<List<SessaoTreinoModel>> buscarSessoes(String usuarioId, {int limite = 50}) async {
    final linhas = await _client
        .from('sessoes_treino')
        .select(_selectSessao)
        .eq('usuario_id', usuarioId)
        .order('iniciado_em', ascending: false)
        .limit(limite);
    return linhas
        .map(SessaoTreinoModel.fromMap)
        .where((sessao) => sessao.execucoes.isNotEmpty)
        .toList();
  }

  /// Exercícios concluídos (dentro de treinos), do mais recente para o mais antigo.
  Future<List<ExecucaoModel>> buscarExecucoes(String usuarioId, {int limite = 100}) async {
    final linhas = await _client
        .from('historico_execucoes')
        .select('id, exercicio_nome, treino_nome, duracao_segundos, concluido_em')
        .eq('usuario_id', usuarioId)
        .order('concluido_em', ascending: false)
        .limit(limite);
    return linhas.map(ExecucaoModel.fromMap).toList();
  }
}
