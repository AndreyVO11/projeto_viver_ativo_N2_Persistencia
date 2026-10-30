/// RF007 - Instrução de Uso e Aviso de Segurança de um equipamento.
/// Um equipamento pode ter várias (RN002: nunca pode ficar sem nenhuma).
class InstrucaoModel {
  final String id;
  final String equipamentoId;
  final String instrucaoUso;
  final String avisoSeguranca;

  const InstrucaoModel({
    required this.id,
    required this.equipamentoId,
    required this.instrucaoUso,
    required this.avisoSeguranca,
  });

  factory InstrucaoModel.fromMap(Map<String, dynamic> map) {
    return InstrucaoModel(
      id: map['id'] as String,
      equipamentoId: map['equipamento_id'] as String? ?? '',
      instrucaoUso: map['instrucao_uso'] as String? ?? '',
      avisoSeguranca: map['aviso_seguranca'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'equipamento_id': equipamentoId,
      'instrucao_uso': instrucaoUso,
      'aviso_seguranca': avisoSeguranca,
    };
  }
}
