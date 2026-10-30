import 'package:flutter_test/flutter_test.dart';
import 'package:viver_ativo/utils/exclusao_utils.dart';

void main() {
  group('mensagemExclusaoEquipamento (aviso ao excluir um equipamento)', () {
    test('lista cada exercício vinculado, na ordem recebida, e avisa que eles saem dos treinos', () {
      final texto = mensagemExclusaoEquipamento(['Supino Sentado', 'Supino Inclinado', 'Voador']);

      expect(texto, contains('Os 3 exercícios abaixo também serão excluídos e retirados dos treinos:'));
      expect(
        texto,
        contains('• Supino Sentado\n• Supino Inclinado\n• Voador'),
      );
      expect(texto, contains('O histórico de quem já fez esses exercícios será mantido.'));
      expect(texto, contains('Esta ação não pode ser desfeita.'));
    });

    test('com um só exercício, usa o singular', () {
      final texto = mensagemExclusaoEquipamento(['Remada Sentada']);

      expect(texto, contains('O exercício abaixo também será excluído e retirado dos treinos:'));
      expect(texto, contains('• Remada Sentada'));
      expect(texto, contains('O histórico de quem já fez esse exercício será mantido.'));
    });

    test('sem exercícios vinculados, diz isso e não fala em treinos nem em histórico', () {
      final texto = mensagemExclusaoEquipamento([]);

      expect(texto, contains('Este equipamento não tem exercícios vinculados.'));
      expect(texto, isNot(contains('treinos')));
      expect(texto, contains('Esta ação não pode ser desfeita.'));
    });

    test('lista longa: mostra os dez primeiros e resume o resto em "e mais N"', () {
      final nomes = [for (var i = 1; i <= 12; i++) 'Exercício $i'];
      final texto = mensagemExclusaoEquipamento(nomes);

      expect(texto, contains('Os 12 exercícios abaixo'));
      expect(texto, contains('• Exercício 10'));
      expect(texto, isNot(contains('• Exercício 11')));
      expect(texto, contains('• e mais 2 exercícios'));
    });

    test('com um exercício além do limite, o resumo fica no singular', () {
      final nomes = [for (var i = 1; i <= 11; i++) 'Exercício $i'];

      expect(mensagemExclusaoEquipamento(nomes), contains('• e mais 1 exercício'));
    });

    test('sem conseguir consultar os exercícios (nulo), avisa em geral que eles também serão excluídos', () {
      final texto = mensagemExclusaoEquipamento(null);

      expect(texto, contains('Os exercícios vinculados a este equipamento também serão excluídos'));
      expect(texto, contains('Esta ação não pode ser desfeita.'));
    });
  });
}
