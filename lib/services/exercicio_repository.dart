import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/exercicio_model.dart';

class ExercicioRepository {
  ExercicioRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _selectCompleto = '''
    id, equipamento_id, nome, midia_url, instrucoes_passo_a_passo, orientacao_aquecimento,
    exercicio_contraindicacao ( condicoes_saude ( nome ) ),
    equipamentos ( nome, equipamento_grupo_muscular ( grupos_musculares ( nome ) ) )
  ''';

  /// RF006 - Visualizar Lista de Exercícios (Figura 15, e "Gerenciar
  /// Exercícios" no admin).
  Future<List<ExercicioModel>> buscarExercicios() async {
    final linhas = await _client.from('exercicios').select(_selectCompleto).order('nome');
    return linhas.map((linha) => ExercicioModel.fromMap(linha['id'] as String, linha)).toList();
  }

  Future<List<ExercicioModel>> buscarPorEquipamento(String equipamentoId) async {
    final linhas = await _client
        .from('exercicios')
        .select(_selectCompleto)
        .eq('equipamento_id', equipamentoId)
        .order('nome');
    return linhas.map((linha) => ExercicioModel.fromMap(linha['id'] as String, linha)).toList();
  }

  Future<ExercicioModel?> buscarPorId(String id) async {
    final linha = await _client
        .from('exercicios')
        .select(_selectCompleto)
        .eq('id', id)
        .maybeSingle();
    if (linha == null) return null;
    return ExercicioModel.fromMap(id, linha);
  }

  /// Gera um id novo antecipadamente, para nomear a mídia no Storage antes
  /// de gravar a linha do exercício.
  String novoId() => const Uuid().v4();

  /// RF006 - Cadastrar/Editar Exercício, com as contraindicações (N:N)
  /// sincronizadas na tabela de junção.
  Future<void> salvar(ExercicioModel exercicio) async {
    await _client.from('exercicios').upsert({
      'id': exercicio.id,
      ...exercicio.toMap(),
    });

    await _client
        .from('exercicio_contraindicacao')
        .delete()
        .eq('exercicio_id', exercicio.id);

    if (exercicio.contraindicacoes.isNotEmpty) {
      final condicoes = await _client
          .from('condicoes_saude')
          .select('id')
          .inFilter('nome', exercicio.contraindicacoes);
      await _client.from('exercicio_contraindicacao').insert([
        for (final condicao in condicoes)
          {'exercicio_id': exercicio.id, 'condicao_saude_id': condicao['id']},
      ]);
    }
  }

  /// RF006, fluxo A2 - Excluir Exercício.
  Future<void> excluir(String id) => _client.from('exercicios').delete().eq('id', id);
}
