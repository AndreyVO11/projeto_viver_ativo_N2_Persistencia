import 'package:flutter_test/flutter_test.dart';
import 'package:viver_ativo/services/instrucao_repository.dart';

void main() {
  group('podeExcluirInstrucao (RN002)', () {
    test('bloqueia a exclusão quando é a única instrução do equipamento', () {
      expect(podeExcluirInstrucao(1), isFalse);
    });

    test('bloqueia também quando a contagem chega a zero (estado inconsistente)', () {
      expect(podeExcluirInstrucao(0), isFalse);
    });

    test('permite excluir quando há mais de uma instrução cadastrada', () {
      expect(podeExcluirInstrucao(2), isTrue);
      expect(podeExcluirInstrucao(5), isTrue);
    });
  });
}
