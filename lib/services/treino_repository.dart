import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/historico_model.dart';
import '../models/treino_model.dart';

class TreinoRepository {
  TreinoRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _selectCompleto = '''
    id, nome, descricao,
    treino_exercicio ( ordem, exercicios ( id, nome ) ),
    treino_grupo_muscular ( grupos_musculares ( nome ) )
  ''';

  /// RF009 - Visualizar Lista de Treinos (Figura 22, e "Gerenciar Treinos" no admin).
  Future<List<TreinoModel>> buscarTreinos() async {
    final linhas = await _client.from('treinos').select(_selectCompleto).order('nome');
    return linhas.map((linha) => TreinoModel.fromMap(linha['id'] as String, linha)).toList();
  }

  Future<TreinoModel?> buscarPorId(String id) async {
    final linha = await _client
        .from('treinos')
        .select(_selectCompleto)
        .eq('id', id)
        .maybeSingle();
    if (linha == null) return null;
    return TreinoModel.fromMap(id, linha);
  }

  /// Gera um id novo antecipadamente, no mesmo padrão dos demais repositórios.
  String novoId() => const Uuid().v4();

  /// RF009 - Cadastrar/Editar Treino, com os exercícios vinculados (N:N, com
  /// ordem) e os tipos do treino (N:N com grupos musculares) sincronizados nas
  /// tabelas de junção.
  Future<void> salvar(TreinoModel treino) async {
    await _client.from('treinos').upsert({
      'id': treino.id,
      ...treino.toMap(),
    });

    await _client.from('treino_exercicio').delete().eq('treino_id', treino.id);

    if (treino.exercicios.isNotEmpty) {
      await _client.from('treino_exercicio').insert([
        for (var i = 0; i < treino.exercicios.length; i++)
          {'treino_id': treino.id, 'exercicio_id': treino.exercicios[i].id, 'ordem': i},
      ]);
    }

    await _client.from('treino_grupo_muscular').delete().eq('treino_id', treino.id);

    if (treino.tipos.isNotEmpty) {
      final grupos = await _client
          .from('grupos_musculares')
          .select('id')
          .inFilter('nome', treino.tipos);
      await _client.from('treino_grupo_muscular').insert([
        for (final grupo in grupos) {'treino_id': treino.id, 'grupo_muscular_id': grupo['id']},
      ]);
    }
  }

  /// RF009, fluxo A3 - Excluir Treino.
  Future<void> excluir(String id) => _client.from('treinos').delete().eq('id', id);

  /// Treino que o usuário começou e não terminou, para a execução continuar de
  /// onde parou. Nulo se a sessão mais recente do treino já foi concluída (ou se
  /// ele nunca foi feito).
  Future<SessaoEmAndamentoModel?> buscarSessaoEmAndamento(String usuarioId, String treinoId) async {
    final linha = await _client
        .from('sessoes_treino')
        .select('id, iniciado_em, concluido_em, historico_execucoes ( exercicio_id, duracao_segundos )')
        .eq('usuario_id', usuarioId)
        .eq('treino_id', treinoId)
        .order('iniciado_em', ascending: false)
        .limit(1)
        .maybeSingle();
    return SessaoEmAndamentoModel.daSessaoMaisRecente(linha);
  }

  /// treino -> ids dos exercícios já feitos na sessão em andamento (para a lista de
  /// treinos mostrar "Em andamento"). Treinos cuja última sessão foi concluída, ou
  /// que nunca foram feitos, ficam de fora.
  Future<Map<String, Set<String>>> buscarProgressoEmAndamento(String usuarioId) async {
    final linhas = await _client
        .from('sessoes_treino')
        .select('treino_id, iniciado_em, concluido_em, historico_execucoes ( exercicio_id )')
        .eq('usuario_id', usuarioId)
        .order('iniciado_em', ascending: false);
    return SessaoEmAndamentoModel.progressoPorTreino(List<Map<String, dynamic>>.from(linhas));
  }

  /// RF009, fluxo A1 - abre uma sessão de treino (uma vez que o usuário o faz) no
  /// histórico. Chamado só quando o primeiro exercício é concluído, para que quem
  /// apenas abre a tela do treino não deixe registro.
  Future<String> iniciarSessao({
    required String usuarioId,
    required String treinoId,
    required String treinoNome,
    required int totalExercicios,
  }) async {
    final id = novoId();
    await _client.from('sessoes_treino').insert({
      'id': id,
      'usuario_id': usuarioId,
      'treino_id': treinoId,
      'treino_nome': treinoNome,
      'total_exercicios': totalExercicios,
    });
    return id;
  }

  /// RF009, fluxo A1 - registra a conclusão de um exercício dentro de um treino,
  /// com o tempo medido pelo cronômetro e uma cópia dos nomes (o histórico
  /// continua legível se o exercício ou o treino forem excluídos depois).
  Future<void> registrarExecucao({
    required String sessaoId,
    required String usuarioId,
    required String treinoId,
    required String treinoNome,
    required String exercicioId,
    required String exercicioNome,
    required int duracaoSegundos,
  }) {
    return _client.from('historico_execucoes').insert({
      'sessao_id': sessaoId,
      'usuario_id': usuarioId,
      'treino_id': treinoId,
      'treino_nome': treinoNome,
      'exercicio_id': exercicioId,
      'exercicio_nome': exercicioNome,
      'duracao_segundos': duracaoSegundos,
    });
  }

  /// RF009, fluxo A1, passo 6 - marca a sessão como concluída (todos os
  /// exercícios do treino feitos).
  Future<void> concluirSessao(String sessaoId) {
    return _client
        .from('sessoes_treino')
        .update({'concluido_em': DateTime.now().toUtc().toIso8601String()})
        .eq('id', sessaoId);
  }
}
