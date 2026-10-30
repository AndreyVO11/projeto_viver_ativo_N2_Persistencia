import '../utils/filtro_utils.dart';

/// Resumo de um exercício vinculado a um treino, na ordem definida pelo
/// administrador (RF009, Quadro 30 - "Seleção múltipla com ordem definida").
class ExercicioDoTreino {
  final String id;
  final String nome;
  final int ordem;

  const ExercicioDoTreino({required this.id, required this.nome, required this.ordem});
}

/// RF009 - Treino, composto por exercícios já cadastrados (RF006).
class TreinoModel {
  final String id;
  final String nome;
  final String descricao;
  final List<ExercicioDoTreino> exercicios;

  /// Tipos do treino (Pernas, Braços, ...), escolhidos pelo administrador entre os
  /// grupos musculares; é por eles que a lista de treinos é filtrada.
  final List<String> tipos;

  const TreinoModel({
    required this.id,
    required this.nome,
    this.descricao = '',
    this.exercicios = const [],
    this.tipos = const [],
  });

  /// [map] vem do Postgrest já com os joins
  /// `treino_exercicio ( ordem, exercicios ( id, nome ) )` e
  /// `treino_grupo_muscular ( grupos_musculares ( nome ) )` embutidos.
  factory TreinoModel.fromMap(String id, Map<String, dynamic> map) {
    final vinculos = List<Map<String, dynamic>>.from(
      map['treino_exercicio'] as List? ?? const [],
    );
    final exercicios = vinculos
        .map((v) {
          final exercicio = v['exercicios'] as Map<String, dynamic>?;
          if (exercicio == null) return null;
          return ExercicioDoTreino(
            id: exercicio['id'] as String,
            nome: exercicio['nome'] as String? ?? '',
            ordem: v['ordem'] as int? ?? 0,
          );
        })
        .whereType<ExercicioDoTreino>()
        .toList();
    exercicios.sort((a, b) => a.ordem.compareTo(b.ordem));

    final vinculosTipos = List<Map<String, dynamic>>.from(
      map['treino_grupo_muscular'] as List? ?? const [],
    );
    // O banco devolve os vínculos em qualquer ordem: aqui ficam na ordem padrão dos grupos.
    final tipos = gruposPresentes([
      vinculosTipos
          .map((v) => (v['grupos_musculares'] as Map<String, dynamic>?)?['nome'] as String?)
          .whereType<String>()
          .toList(),
    ]);

    return TreinoModel(
      id: id,
      nome: map['nome'] as String? ?? '',
      descricao: map['descricao'] as String? ?? '',
      exercicios: exercicios,
      tipos: tipos,
    );
  }

  /// Colunas próprias da tabela `treinos` (o vínculo com exercícios é
  /// sincronizado à parte pelo `TreinoRepository`).
  Map<String, dynamic> toMap() {
    return {'nome': nome, 'descricao': descricao};
  }
}
