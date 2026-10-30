import '../models/equipamento_model.dart';

/// Grupos musculares que aparecem em pelo menos um item da lista, para a barra de
/// filtro só oferecer opções que têm resultado. Seguem a ordem padrão dos grupos
/// (Pernas, Costas, Braços...); grupos fora dessa lista vão para o fim, em ordem
/// alfabética.
List<String> gruposPresentes(Iterable<List<String>> gruposPorItem) {
  final presentes = {for (final grupos in gruposPorItem) ...grupos};
  final ordemPadrao = gruposMuscularesDisponiveis.where(presentes.contains).toList();
  final outros = presentes.where((g) => !gruposMuscularesDisponiveis.contains(g)).toList()..sort();
  return [...ordemPadrao, ...outros];
}

/// Itens do grupo escolhido; sem grupo (nulo, a opção "Todos"), a lista inteira.
List<T> filtrarPorGrupo<T>(Iterable<T> itens, String? grupo, List<String> Function(T) gruposDe) {
  if (grupo == null) return itens.toList();
  return itens.where((item) => gruposDe(item).contains(grupo)).toList();
}
