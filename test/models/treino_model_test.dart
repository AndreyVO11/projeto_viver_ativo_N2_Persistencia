import 'package:flutter_test/flutter_test.dart';
import 'package:viver_ativo/models/treino_model.dart';

void main() {
  group('TreinoModel.fromMap', () {
    test('lê nome e descrição da tabela treinos', () {
      final treino = TreinoModel.fromMap('tr-1', {
        'nome': 'Treino Iniciante',
        'descricao': 'Sequência leve para começar',
      });

      expect(treino.id, 'tr-1');
      expect(treino.nome, 'Treino Iniciante');
      expect(treino.descricao, 'Sequência leve para começar');
    });

    test('ordena os exercícios do join treino_exercicio pelo campo ordem (RF009, Quadro 30)', () {
      final treino = TreinoModel.fromMap('tr-1', {
        'nome': 'Treino Iniciante',
        'treino_exercicio': [
          {'ordem': 2, 'exercicios': {'id': 'ex-3', 'nome': 'Terceiro'}},
          {'ordem': 0, 'exercicios': {'id': 'ex-1', 'nome': 'Primeiro'}},
          {'ordem': 1, 'exercicios': {'id': 'ex-2', 'nome': 'Segundo'}},
        ],
      });

      expect(treino.exercicios.map((e) => e.nome), ['Primeiro', 'Segundo', 'Terceiro']);
      expect(treino.exercicios.map((e) => e.id), ['ex-1', 'ex-2', 'ex-3']);
    });

    test('vínculo sem o exercício embutido é ignorado (não quebra o parse)', () {
      final treino = TreinoModel.fromMap('tr-1', {
        'nome': 'Treino Iniciante',
        'treino_exercicio': [
          {'ordem': 0, 'exercicios': null},
        ],
      });

      expect(treino.exercicios, isEmpty);
    });

    test('lê os tipos do treino do join treino_grupo_muscular', () {
      final treino = TreinoModel.fromMap('tr-1', {
        'nome': 'Treino de Pernas e Equilíbrio',
        'treino_grupo_muscular': [
          {'grupos_musculares': {'nome': 'Pernas'}},
          {'grupos_musculares': null},
          {'grupos_musculares': {'nome': 'Glúteos'}},
        ],
      });

      expect(treino.tipos, ['Pernas', 'Glúteos']);
    });

    test('os tipos ficam na ordem padrão dos grupos, não na ordem devolvida pelo banco', () {
      final treino = TreinoModel.fromMap('tr-1', {
        'nome': 'Treino Iniciante',
        'treino_grupo_muscular': [
          {'grupos_musculares': {'nome': 'Abdômen'}},
          {'grupos_musculares': {'nome': 'Ombros'}},
          {'grupos_musculares': {'nome': 'Costas'}},
          {'grupos_musculares': {'nome': 'Pernas'}},
        ],
      });

      expect(treino.tipos, ['Pernas', 'Costas', 'Abdômen', 'Ombros']);
    });

    test('treino sem tipo cadastrado retorna lista vazia', () {
      expect(TreinoModel.fromMap('tr-1', {'nome': 'Treino'}).tipos, isEmpty);
    });

    test('sem exercícios vinculados retorna lista vazia', () {
      final treino = TreinoModel.fromMap('tr-1', {'nome': 'Treino Iniciante'});

      expect(treino.exercicios, isEmpty);
    });
  });

  group('TreinoModel.toMap', () {
    test('gera apenas as colunas próprias da tabela treinos', () {
      const treino = TreinoModel(id: 'tr-1', nome: 'Treino Iniciante', descricao: 'Leve');

      expect(treino.toMap(), {'nome': 'Treino Iniciante', 'descricao': 'Leve'});
    });
  });
}
