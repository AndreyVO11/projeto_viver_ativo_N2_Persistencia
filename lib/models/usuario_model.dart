import '../utils/contraindicacao_utils.dart';

class UsuarioModel {
  final String id;
  final String nome;
  final String telefone;
  final List<String> condicoesSaude;
  final bool isAdmin;

  /// RF008 - só o administrador inicial (cadastrado direto no banco na
  /// implantação do sistema) pode gerenciar outros administradores.
  final bool isAdminInicial;

  const UsuarioModel({
    required this.id,
    required this.nome,
    required this.telefone,
    this.condicoesSaude = const [],
    this.isAdmin = false,
    this.isAdminInicial = false,
  });

  /// [map] vem do Postgrest já com o join
  /// `usuario_condicao_saude ( condicoes_saude ( nome ) )` embutido.
  factory UsuarioModel.fromMap(String id, Map<String, dynamic> map) {
    final vinculos = List<Map<String, dynamic>>.from(
      map['usuario_condicao_saude'] as List? ?? const [],
    );
    // "Nenhuma" não é uma condição (registros antigos podem tê-la gravado).
    final condicoes = semNenhuma(
      vinculos
          .map((vinculo) => (vinculo['condicoes_saude'] as Map<String, dynamic>?)?['nome'] as String?)
          .whereType<String>(),
    );

    return UsuarioModel(
      id: id,
      nome: map['nome'] as String? ?? '',
      telefone: map['telefone'] as String? ?? '',
      condicoesSaude: condicoes,
      isAdmin: map['is_admin'] as bool? ?? false,
      isAdminInicial: map['is_admin_inicial'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'telefone': telefone,
      'is_admin': isAdmin,
      'is_admin_inicial': isAdminInicial,
    };
  }

  UsuarioModel copyWith({
    String? nome,
    String? telefone,
    List<String>? condicoesSaude,
    bool? isAdmin,
    bool? isAdminInicial,
  }) {
    return UsuarioModel(
      id: id,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      condicoesSaude: condicoesSaude ?? this.condicoesSaude,
      isAdmin: isAdmin ?? this.isAdmin,
      isAdminInicial: isAdminInicial ?? this.isAdminInicial,
    );
  }
}

/// Lista pré-definida de condições de saúde exibida no cadastro (RF001, Quadro 12)
/// e usada para cruzar com contraindicações de exercícios em rodadas futuras (RF006).
const List<String> condicoesSaudeDisponiveis = [
  condicaoNenhuma,
  'Hipertensão',
  'Diabetes',
  'Artrose',
  'Problemas no joelho',
  'Problemas na coluna',
  'Osteoporose',
  'Problemas cardíacos',
  'Labirintite / tontura',
];
