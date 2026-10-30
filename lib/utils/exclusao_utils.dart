/// Texto do aviso de exclusão de um equipamento (RF003, fluxo A2).
///
/// O banco exclui, junto com o equipamento, os exercícios vinculados a ele, e os
/// exercícios saem dos treinos; o histórico de quem já os fez continua guardado.
/// O aviso lista esses exercícios para o administrador saber o que vai perder.
///
/// [nomesExercicios] é a lista dos exercícios vinculados, ou nulo se não foi possível
/// consultá-la (então o aviso diz, em geral, que eles também serão excluídos).
/// Mostra no máximo [limite] nomes e resume o resto em "e mais N".
String mensagemExclusaoEquipamento(List<String>? nomesExercicios, {int limite = 10}) {
  const fim = 'Esta ação não pode ser desfeita.';

  if (nomesExercicios == null) {
    return 'Os exercícios vinculados a este equipamento também serão excluídos e retirados dos treinos. '
        'O histórico de quem já os fez será mantido.\n\n$fim';
  }
  if (nomesExercicios.isEmpty) {
    return 'Este equipamento não tem exercícios vinculados.\n\n$fim';
  }

  final total = nomesExercicios.length;
  final cabecalho = total == 1
      ? 'O exercício abaixo também será excluído e retirado dos treinos:'
      : 'Os $total exercícios abaixo também serão excluídos e retirados dos treinos:';
  final linhas = [for (final nome in nomesExercicios.take(limite)) '• $nome'];
  if (total > limite) {
    final resto = total - limite;
    linhas.add(resto == 1 ? '• e mais 1 exercício' : '• e mais $resto exercícios');
  }
  final historico = total == 1
      ? 'O histórico de quem já fez esse exercício será mantido.'
      : 'O histórico de quem já fez esses exercícios será mantido.';

  return '$cabecalho\n${linhas.join('\n')}\n\n$historico\n\n$fim';
}
