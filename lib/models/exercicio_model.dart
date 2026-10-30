import '../utils/contraindicacao_utils.dart';
import '../utils/filtro_utils.dart';

/// RF006 - Exercício, sempre vinculado a um equipamento.
class ExercicioModel {
  final String id;
  final String equipamentoId;
  final String nome;
  final String midiaUrl;
  final String instrucoesPassoAPasso;
  final String orientacaoAquecimento;

  /// Condições de saúde que contraindicam este exercício (cruzadas com o
  /// perfil do usuário no fluxo A3 do RF006).
  final List<String> contraindicacoes;

  /// Preenchidos apenas quando o exercício vem de uma busca com join no
  /// equipamento (nome do equipamento e seu primeiro grupo muscular, usados
  /// como categoria na listagem do RF006).
  final String equipamentoNome;
  final String equipamentoCategoria;

  /// Todos os grupos musculares do equipamento (a categoria acima é só o primeiro);
  /// o filtro da lista de exercícios usa estes.
  final List<String> equipamentoGrupos;

  const ExercicioModel({
    required this.id,
    required this.equipamentoId,
    required this.nome,
    required this.instrucoesPassoAPasso,
    required this.orientacaoAquecimento,
    this.midiaUrl = '',
    this.contraindicacoes = const [],
    this.equipamentoNome = '',
    this.equipamentoCategoria = '',
    this.equipamentoGrupos = const [],
  });

  /// [map] vem do Postgrest já com os joins
  /// `exercicio_contraindicacao ( condicoes_saude ( nome ) )` e
  /// `equipamentos ( nome, equipamento_grupo_muscular ( grupos_musculares ( nome ) ) )`.
  factory ExercicioModel.fromMap(String id, Map<String, dynamic> map) {
    final vinculosContraindicacao = List<Map<String, dynamic>>.from(
      map['exercicio_contraindicacao'] as List? ?? const [],
    );
    // "Nenhuma" não é uma contraindicação (registros antigos podem tê-la gravado).
    final contraindicacoes = semNenhuma(
      vinculosContraindicacao
          .map((v) => (v['condicoes_saude'] as Map<String, dynamic>?)?['nome'] as String?)
          .whereType<String>(),
    );

    final equipamento = map['equipamentos'] as Map<String, dynamic>?;
    final gruposVinculados = List<Map<String, dynamic>>.from(
      equipamento?['equipamento_grupo_muscular'] as List? ?? const [],
    );
    final nomesDosGrupos = gruposVinculados
        .map((v) => (v['grupos_musculares'] as Map<String, dynamic>?)?['nome'] as String?)
        .whereType<String>()
        .toList();
    final primeiraCategoria = nomesDosGrupos.isNotEmpty ? nomesDosGrupos.first : null;
    // Para exibir e filtrar, os grupos ficam na ordem padrão (o banco devolve em qualquer ordem).
    final grupos = gruposPresentes([nomesDosGrupos]);

    return ExercicioModel(
      id: id,
      equipamentoId: map['equipamento_id'] as String? ?? '',
      nome: map['nome'] as String? ?? '',
      midiaUrl: map['midia_url'] as String? ?? '',
      instrucoesPassoAPasso: map['instrucoes_passo_a_passo'] as String? ?? '',
      orientacaoAquecimento: map['orientacao_aquecimento'] as String? ?? '',
      contraindicacoes: contraindicacoes,
      equipamentoNome: equipamento?['nome'] as String? ?? '',
      equipamentoCategoria: primeiraCategoria ?? '',
      equipamentoGrupos: grupos,
    );
  }

  /// Colunas próprias da tabela `exercicios` (a lista de contraindicações é
  /// sincronizada à parte pelo `ExercicioRepository`).
  Map<String, dynamic> toMap() {
    return {
      'equipamento_id': equipamentoId,
      'nome': nome,
      'midia_url': midiaUrl,
      'instrucoes_passo_a_passo': instrucoesPassoAPasso,
      'orientacao_aquecimento': orientacaoAquecimento,
    };
  }
}
