import 'package:flutter/services.dart';

/// Pergunta padrão de recuperação de senha (RF001, fluxo A3). Fica no app: o
/// banco guarda apenas o hash da resposta.
const perguntaRecuperacao = 'Qual é o nome completo da sua mãe?';

/// Deixa só os dígitos e remove o prefixo do país (55) e o zero à esquerda,
/// para que "+55 (64) 99300-2156", "064993002156" e "64993002156" sejam a
/// mesma conta.
String normalizarTelefone(String entrada) {
  var digitos = entrada.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.length > 11 && digitos.startsWith('55')) {
    digitos = digitos.substring(2);
  }
  return digitos.replaceFirst(RegExp(r'^0+'), '');
}

/// Telefone brasileiro com DDD: 10 dígitos (fixo) ou 11 (celular, começando em 9
/// depois do DDD).
bool telefoneValido(String entrada) {
  final t = normalizarTelefone(entrada);
  if (t.length != 10 && t.length != 11) return false;
  final ddd = int.parse(t.substring(0, 2));
  if (ddd < 11 || ddd % 10 == 0) return false;
  if (t.length == 11 && t[2] != '9') return false;
  return true;
}

/// Formata para exibição: (64) 99300-2156 ou (64) 3621-1234. Aceita número
/// incompleto, para ser usado enquanto a pessoa digita.
String formatarTelefone(String entrada) {
  final t = normalizarTelefone(entrada);
  if (t.isEmpty) return '';
  final buffer = StringBuffer('(');
  buffer.write(t.substring(0, t.length < 2 ? t.length : 2));
  if (t.length <= 2) return buffer.toString();
  // Separadores só aparecem quando há dígitos depois deles; do contrário a
  // tecla de apagar ficaria presa em "(64) ".
  buffer.write(') ');
  final resto = t.substring(2);
  final corte = t.length > 10 ? 5 : 4;
  if (resto.length <= corte) {
    buffer.write(resto);
  } else {
    buffer
      ..write(resto.substring(0, corte))
      ..write('-')
      ..write(resto.substring(corte));
  }
  return buffer.toString();
}

/// Validador dos campos de telefone dos formulários.
String? validarTelefone(String? valor) {
  if (valor == null || valor.trim().isEmpty) return 'Informe o número de telefone';
  if (!telefoneValido(valor)) {
    return 'Informe o telefone com DDD, por exemplo (64) 99999-9999';
  }
  return null;
}

/// Normaliza a resposta de recuperação antes de enviá-la ao banco, para que
/// "Maria da Conceição", "maria da conceicao" e " MARIA  DA CONCEIÇÃO " sejam a
/// mesma resposta.
String normalizarResposta(String entrada) {
  const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const semAcento = 'aaaaaeeeeiiiiooooouuuucn';
  final minuscula = entrada.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final caractere in minuscula.split('')) {
    final posicao = comAcento.indexOf(caractere);
    buffer.write(posicao >= 0 ? semAcento[posicao] : caractere);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
}

/// Aplica a máscara (DD) 99999-9999 enquanto a pessoa digita.
class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue anterior, TextEditingValue novo) {
    var digitos = normalizarTelefone(novo.text);
    if (digitos.length > 11) digitos = digitos.substring(0, 11);
    final formatado = formatarTelefone(digitos);
    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }
}
