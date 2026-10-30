import 'instrucao_model.dart';

/// Nível de dificuldade do equipamento (RF003, Quadro 17 - domínio da tela:
/// Fácil, Médio, Difícil).
enum NivelDificuldade { facil, medio, dificil }

extension NivelDificuldadeLabel on NivelDificuldade {
  String get label {
    switch (this) {
      case NivelDificuldade.facil:
        return 'Fácil';
      case NivelDificuldade.medio:
        return 'Médio';
      case NivelDificuldade.dificil:
        return 'Difícil';
    }
  }

  static NivelDificuldade fromLabel(String? value) {
    switch (value) {
      case 'Médio':
        return NivelDificuldade.medio;
      case 'Difícil':
        return NivelDificuldade.dificil;
      case 'Fácil':
      default:
        return NivelDificuldade.facil;
    }
  }
}

/// Grupos musculares disponíveis para vínculo do equipamento (RN001, Quadro 17).
const List<String> gruposMuscularesDisponiveis = [
  'Pernas',
  'Costas',
  'Braços',
  'Peito',
  'Abdômen',
  'Ombros',
  'Glúteos',
  'Cardio',
];

class EquipamentoModel {
  final String id;
  final String nome;
  final String imagemUrl;
  final List<String> gruposMusculares;
  final NivelDificuldade nivelDificuldade;

  /// RF005 - texto introdutório sobre o equipamento.
  final String descricao;

  /// RF005 - finalidade e músculos trabalhados.
  final String paraQueServe;

  /// RF005 - lista de benefícios exibidos com ícone de confirmação.
  final List<String> beneficios;

  /// RF005 - dica prática de uso seguro.
  final String dicaDeOuro;

  /// RF007 - instruções de uso e avisos de segurança do equipamento
  /// (RN002: precisa ter ao menos uma).
  final List<InstrucaoModel> instrucoes;

  const EquipamentoModel({
    required this.id,
    required this.nome,
    required this.imagemUrl,
    required this.gruposMusculares,
    required this.nivelDificuldade,
    this.instrucoes = const [],
    this.descricao = '',
    this.paraQueServe = '',
    this.beneficios = const [],
    this.dicaDeOuro = '',
  });

  /// Categoria exibida na lista (RF004, Quadro 19): gerada a partir do
  /// primeiro grupo muscular vinculado ao equipamento.
  String get tagCategoria => gruposMusculares.isNotEmpty ? gruposMusculares.first : '';

  /// [map] vem do Postgrest já com os joins
  /// `equipamento_grupo_muscular ( grupos_musculares ( nome ) )`,
  /// `equipamento_beneficios ( descricao, ordem )` e
  /// `equipamento_instrucoes ( id, instrucao_uso, aviso_seguranca )` embutidos.
  factory EquipamentoModel.fromMap(String id, Map<String, dynamic> map) {
    final vinculosGrupos = List<Map<String, dynamic>>.from(
      map['equipamento_grupo_muscular'] as List? ?? const [],
    );
    final gruposMusculares = vinculosGrupos
        .map((v) => (v['grupos_musculares'] as Map<String, dynamic>?)?['nome'] as String?)
        .whereType<String>()
        .toList();

    final linhasBeneficios = List<Map<String, dynamic>>.from(
      map['equipamento_beneficios'] as List? ?? const [],
    );
    linhasBeneficios.sort(
      (a, b) => (a['ordem'] as int? ?? 0).compareTo(b['ordem'] as int? ?? 0),
    );
    final beneficios = linhasBeneficios.map((b) => b['descricao'] as String).toList();

    final linhasInstrucoes = List<Map<String, dynamic>>.from(
      map['equipamento_instrucoes'] as List? ?? const [],
    );
    final instrucoes = linhasInstrucoes.map(InstrucaoModel.fromMap).toList();

    return EquipamentoModel(
      id: id,
      nome: map['nome'] as String? ?? '',
      imagemUrl: map['imagem_url'] as String? ?? '',
      gruposMusculares: gruposMusculares,
      nivelDificuldade: NivelDificuldadeLabel.fromLabel(map['nivel_dificuldade'] as String?),
      instrucoes: instrucoes,
      descricao: map['descricao'] as String? ?? '',
      paraQueServe: map['para_que_serve'] as String? ?? '',
      beneficios: beneficios,
      dicaDeOuro: map['dica_de_ouro'] as String? ?? '',
    );
  }

  /// Colunas próprias da tabela `equipamentos` (os relacionamentos N:N/1:N
  /// são sincronizados à parte pelo `EquipamentoRepository`).
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'imagem_url': imagemUrl,
      'nivel_dificuldade': nivelDificuldade.label,
      'descricao': descricao,
      'para_que_serve': paraQueServe,
      'dica_de_ouro': dicaDeOuro,
    };
  }
}
