import 'package:flutter_test/flutter_test.dart';
import 'package:viver_ativo/utils/contraindicacao_utils.dart';

void main() {
  group('contraindicacoesAplicaveis (RF006, fluxo A3.1)', () {
    test('retorna as condições em comum entre o perfil e as contraindicações', () {
      final resultado = contraindicacoesAplicaveis(
        condicoesSaudeUsuario: ['Hipertensão', 'Problemas no joelho'],
        contraindicacoesExercicio: ['Hipertensão', 'Labirintite / tontura'],
      );

      expect(resultado, ['Hipertensão']);
    });

    test('retorna lista vazia quando não há interseção (guia libera direto)', () {
      final resultado = contraindicacoesAplicaveis(
        condicoesSaudeUsuario: ['Nenhuma'],
        contraindicacoesExercicio: ['Hipertensão', 'Labirintite / tontura'],
      );

      expect(resultado, isEmpty);
    });

    test('exercício sem nenhuma contraindicação cadastrada nunca bloqueia', () {
      final resultado = contraindicacoesAplicaveis(
        condicoesSaudeUsuario: ['Hipertensão', 'Diabetes', 'Osteoporose'],
        contraindicacoesExercicio: [],
      );

      expect(resultado, isEmpty);
    });

    test('usuário sem nenhuma condição de saúde nunca é bloqueado', () {
      final resultado = contraindicacoesAplicaveis(
        condicoesSaudeUsuario: [],
        contraindicacoesExercicio: ['Hipertensão'],
      );

      expect(resultado, isEmpty);
    });

    test('"Nenhuma" no perfil e no exercício não conta como correspondência', () {
      final resultado = contraindicacoesAplicaveis(
        condicoesSaudeUsuario: ['Nenhuma'],
        contraindicacoesExercicio: ['Nenhuma'],
      );

      expect(resultado, isEmpty);
    });

    test('"Nenhuma" misturada com condições reais não atrapalha o cruzamento', () {
      final resultado = contraindicacoesAplicaveis(
        condicoesSaudeUsuario: ['Nenhuma', 'Artrose'],
        contraindicacoesExercicio: ['Nenhuma', 'Artrose', 'Hipertensão'],
      );

      expect(resultado, ['Artrose']);
    });
  });

  group('semNenhuma', () {
    test('tira só a opção "Nenhuma" e mantém as condições, na ordem', () {
      expect(semNenhuma(['Nenhuma', 'Diabetes', 'Artrose']), ['Diabetes', 'Artrose']);
    });

    test('lista só com "Nenhuma" ou vazia fica vazia', () {
      expect(semNenhuma(['Nenhuma']), isEmpty);
      expect(semNenhuma([]), isEmpty);
    });
  });
}
