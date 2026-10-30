import 'package:flutter_test/flutter_test.dart';
import 'package:viver_ativo/utils/filtro_utils.dart';

void main() {
  group('gruposPresentes', () {
    test('junta os grupos dos itens sem repetir', () {
      expect(
        gruposPresentes([
          ['Pernas', 'Cardio'],
          ['Pernas'],
          ['Cardio'],
        ]),
        ['Pernas', 'Cardio'],
      );
    });

    test('segue a ordem padrão dos grupos, não a ordem em que aparecem', () {
      expect(
        gruposPresentes([
          ['Cardio', 'Glúteos'],
          ['Braços', 'Pernas'],
        ]),
        ['Pernas', 'Braços', 'Glúteos', 'Cardio'],
      );
    });

    test('grupo fora da lista padrão vai para o fim, em ordem alfabética', () {
      expect(
        gruposPresentes([
          ['Zumba', 'Pernas'],
          ['Alongamento'],
        ]),
        ['Pernas', 'Alongamento', 'Zumba'],
      );
    });

    test('sem itens ou sem grupos, não há opções', () {
      expect(gruposPresentes([]), isEmpty);
      expect(gruposPresentes([[], []]), isEmpty);
    });
  });

  group('filtrarPorGrupo', () {
    final itens = {
      'Leg Press': ['Pernas', 'Glúteos'],
      'Supino': ['Peito', 'Braços'],
      'Remada': ['Costas', 'Braços'],
    };

    test('sem grupo escolhido ("Todos"), devolve tudo', () {
      expect(filtrarPorGrupo(itens.keys, null, (n) => itens[n]!), ['Leg Press', 'Supino', 'Remada']);
    });

    test('devolve só os itens que têm o grupo, mesmo quando ele não é o primeiro', () {
      expect(filtrarPorGrupo(itens.keys, 'Braços', (n) => itens[n]!), ['Supino', 'Remada']);
      expect(filtrarPorGrupo(itens.keys, 'Glúteos', (n) => itens[n]!), ['Leg Press']);
    });

    test('grupo que nenhum item tem devolve lista vazia', () {
      expect(filtrarPorGrupo(itens.keys, 'Abdômen', (n) => itens[n]!), isEmpty);
    });
  });
}
