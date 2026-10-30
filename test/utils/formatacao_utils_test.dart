import 'package:flutter_test/flutter_test.dart';
import 'package:viver_ativo/utils/formatacao_utils.dart';

void main() {
  group('formatarDuracao (cronômetro e histórico, RF009)', () {
    test('formata minutos e segundos com dois dígitos', () {
      expect(formatarDuracao(0), '00:00');
      expect(formatarDuracao(5), '00:05');
      expect(formatarDuracao(222), '03:42');
      expect(formatarDuracao(3599), '59:59');
    });

    test('mostra as horas só quando passa de uma hora', () {
      expect(formatarDuracao(3600), '1:00:00');
      expect(formatarDuracao(3725), '1:02:05');
    });

    test('valor negativo é tratado como zero', () {
      expect(formatarDuracao(-10), '00:00');
    });
  });

  group('formatarData / formatarDataHora', () {
    test('formata dia/mês/ano e hora com zeros à esquerda', () {
      final data = DateTime(2026, 10, 7, 9, 5);
      expect(formatarData(data), '07/10/2026');
      expect(formatarDataHora(data), '07/10/2026 às 09:05');
    });
  });
}
