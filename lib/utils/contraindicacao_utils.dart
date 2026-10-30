/// Opção "Nenhuma" das listas de condições de saúde (cadastro/perfil do usuário e
/// contraindicações do exercício). Ela quer dizer "sem condição", não é uma
/// condição: não é gravada e nunca entra no cruzamento do aviso (RF006, A3.1).
const String condicaoNenhuma = 'Nenhuma';

/// Remove "Nenhuma", deixando só as condições de saúde de verdade.
List<String> semNenhuma(Iterable<String> condicoes) {
  return condicoes.where((condicao) => condicao != condicaoNenhuma).toList();
}

/// RF006, fluxo A3.1 - cruza as condições de saúde do perfil do usuário com
/// as contraindicações cadastradas no exercício, retornando só as que
/// coincidem (usadas para decidir se o aviso bloqueante deve aparecer).
List<String> contraindicacoesAplicaveis({
  required List<String> condicoesSaudeUsuario,
  required List<String> contraindicacoesExercicio,
}) {
  final condicoes = semNenhuma(condicoesSaudeUsuario);
  return semNenhuma(contraindicacoesExercicio).where(condicoes.contains).toList();
}
