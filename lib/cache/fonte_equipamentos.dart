/// Fonte da verdade da lista de equipamentos (no app, o Supabase).
abstract class FonteEquipamentos {
  Future<List<Map<String, dynamic>>> listar();
}

/// Fonte que também grava (usada pelos scripts e testes do projeto N2).
abstract class FonteEscritaEquipamentos implements FonteEquipamentos {
  Future<void> atualizar(Map<String, dynamic> equipamento);
  Future<void> excluir(String id);
}
