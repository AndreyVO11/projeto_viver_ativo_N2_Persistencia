/// Um exercício concluído pelo usuário (linha de `historico_execucoes`).
/// Os nomes são uma cópia gravada na hora: o registro continua legível mesmo que
/// o administrador exclua o exercício ou o treino depois.
class ExecucaoModel {
  final String id;
  final String exercicioNome;
  final String treinoNome;
  final int? duracaoSegundos;
  final DateTime concluidoEm;

  const ExecucaoModel({
    required this.id,
    required this.exercicioNome,
    required this.treinoNome,
    required this.duracaoSegundos,
    required this.concluidoEm,
  });

  factory ExecucaoModel.fromMap(Map<String, dynamic> map) {
    return ExecucaoModel(
      id: map['id'] as String,
      exercicioNome: (map['exercicio_nome'] as String?) ?? 'Exercício removido',
      treinoNome: (map['treino_nome'] as String?) ?? '',
      duracaoSegundos: map['duracao_segundos'] as int?,
      concluidoEm: DateTime.parse(map['concluido_em'] as String),
    );
  }
}

/// Uma vez que o usuário fez um treino (linha de `sessoes_treino`), com os
/// exercícios concluídos nela.
class SessaoTreinoModel {
  final String id;
  final String treinoNome;
  final int totalExercicios;
  final DateTime iniciadoEm;
  final DateTime? concluidoEm;
  final List<ExecucaoModel> execucoes;

  const SessaoTreinoModel({
    required this.id,
    required this.treinoNome,
    required this.totalExercicios,
    required this.iniciadoEm,
    required this.concluidoEm,
    required this.execucoes,
  });

  bool get concluida => concluidoEm != null;

  int get exerciciosConcluidos => execucoes.length;

  /// Soma só dos exercícios que tiveram o tempo medido.
  int get duracaoTotalSegundos =>
      execucoes.fold(0, (soma, e) => soma + (e.duracaoSegundos ?? 0));

  /// [map] vem do Postgrest com o join
  /// `historico_execucoes ( id, exercicio_nome, treino_nome, duracao_segundos, concluido_em )`.
  factory SessaoTreinoModel.fromMap(Map<String, dynamic> map) {
    final execucoes = List<Map<String, dynamic>>.from(
      map['historico_execucoes'] as List? ?? const [],
    ).map(ExecucaoModel.fromMap).toList()
      ..sort((a, b) => a.concluidoEm.compareTo(b.concluidoEm));

    final concluido = map['concluido_em'] as String?;
    return SessaoTreinoModel(
      id: map['id'] as String,
      treinoNome: (map['treino_nome'] as String?) ?? 'Treino removido',
      totalExercicios: map['total_exercicios'] as int? ?? 0,
      iniciadoEm: DateTime.parse(map['iniciado_em'] as String),
      concluidoEm: concluido == null ? null : DateTime.parse(concluido),
      execucoes: execucoes,
    );
  }
}

/// Treino que a pessoa começou e ainda não terminou: guarda quais exercícios já
/// foram concluídos (e em quanto tempo) para a execução poder continuar de onde parou.
class SessaoEmAndamentoModel {
  final String id;
  final DateTime iniciadoEm;

  /// exercício concluído -> segundos gastos nele.
  final Map<String, int> duracoes;

  const SessaoEmAndamentoModel({
    required this.id,
    required this.iniciadoEm,
    required this.duracoes,
  });

  /// [map] vem do Postgrest com o join `historico_execucoes ( exercicio_id, duracao_segundos )`.
  /// Exercícios excluídos pelo administrador (exercicio_id nulo) ficam de fora.
  factory SessaoEmAndamentoModel.fromMap(Map<String, dynamic> map) {
    final duracoes = <String, int>{};
    for (final linha in List<Map<String, dynamic>>.from(map['historico_execucoes'] as List? ?? const [])) {
      final exercicioId = linha['exercicio_id'] as String?;
      if (exercicioId != null) duracoes[exercicioId] = linha['duracao_segundos'] as int? ?? 0;
    }
    return SessaoEmAndamentoModel(
      id: map['id'] as String,
      iniciadoEm: DateTime.parse(map['iniciado_em'] as String),
      duracoes: duracoes,
    );
  }

  /// Só a sessão mais recente do treino pode estar em andamento: se a pessoa
  /// recomeçou ou já refez o treino, uma sessão antiga que ficou aberta é
  /// parcial e não volta a aparecer como "em andamento".
  ///
  /// [maisRecente] é a sessão mais recente do treino (aberta ou concluída), com o
  /// join `historico_execucoes ( exercicio_id, duracao_segundos )`.
  static SessaoEmAndamentoModel? daSessaoMaisRecente(Map<String, dynamic>? maisRecente) {
    if (maisRecente == null || maisRecente['concluido_em'] != null) return null;
    return SessaoEmAndamentoModel.fromMap(maisRecente);
  }

  /// treino -> ids dos exercícios já feitos na sessão em andamento.
  /// [sessoes] vêm da mais recente para a mais antiga; vale a primeira de cada
  /// treino, e só entra se ainda estiver aberta e com algum exercício feito.
  /// Execuções de exercícios excluídos pelo administrador (exercicio_id nulo) ficam de fora.
  static Map<String, Set<String>> progressoPorTreino(List<Map<String, dynamic>> sessoes) {
    final progresso = <String, Set<String>>{};
    final vistos = <String>{};
    for (final sessao in sessoes) {
      final treinoId = sessao['treino_id'] as String?;
      if (treinoId == null || !vistos.add(treinoId)) continue;
      if (sessao['concluido_em'] != null) continue;
      final feitos = <String>{};
      for (final linha in sessao['historico_execucoes'] as List? ?? const []) {
        final exercicioId = (linha as Map<String, dynamic>)['exercicio_id'];
        if (exercicioId is String) feitos.add(exercicioId);
      }
      if (feitos.isNotEmpty) progresso[treinoId] = feitos;
    }
    return progresso;
  }

  /// Quantos dos exercícios que o treino tem hoje ([idsDoTreino]) já foram feitos na
  /// sessão em andamento ([feitos]). Um exercício feito que depois saiu do treino (ou
  /// foi excluído) não conta, para o "Em andamento: X de N" bater com o treino atual.
  static int feitosNoTreino(Set<String>? feitos, Iterable<String> idsDoTreino) =>
      feitos == null ? 0 : idsDoTreino.where(feitos.contains).length;
}
