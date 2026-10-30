import 'package:flutter_test/flutter_test.dart';
import 'package:viver_ativo/models/exercicio_model.dart';

void main() {
  group('ExercicioModel.fromMap', () {
    test('lê os campos simples da tabela exercicios', () {
      final exercicio = ExercicioModel.fromMap('ex-1', {
        'equipamento_id': 'eq-1',
        'nome': 'Caminhada no simulador',
        'midia_url': 'https://exemplo.com/foto.jpg',
        'instrucoes_passo_a_passo': 'Passo a passo',
        'orientacao_aquecimento': 'Aqueça antes',
      });

      expect(exercicio.id, 'ex-1');
      expect(exercicio.equipamentoId, 'eq-1');
      expect(exercicio.nome, 'Caminhada no simulador');
      expect(exercicio.midiaUrl, 'https://exemplo.com/foto.jpg');
      expect(exercicio.instrucoesPassoAPasso, 'Passo a passo');
      expect(exercicio.orientacaoAquecimento, 'Aqueça antes');
    });

    test('extrai as contraindicações do join exercicio_contraindicacao', () {
      final exercicio = ExercicioModel.fromMap('ex-1', {
        'nome': 'Caminhada no simulador',
        'exercicio_contraindicacao': [
          {'condicoes_saude': {'nome': 'Hipertensão'}},
          {'condicoes_saude': {'nome': 'Labirintite / tontura'}},
        ],
      });

      expect(exercicio.contraindicacoes, ['Hipertensão', 'Labirintite / tontura']);
    });

    test('"Nenhuma" gravada em registro antigo não vira contraindicação', () {
      final exercicio = ExercicioModel.fromMap('ex-1', {
        'nome': 'Caminhada',
        'exercicio_contraindicacao': [
          {'condicoes_saude': {'nome': 'Nenhuma'}},
          {'condicoes_saude': {'nome': 'Artrose'}},
        ],
      });

      expect(exercicio.contraindicacoes, ['Artrose']);
    });

    test('extrai nome e categoria do equipamento vinculado (join equipamentos)', () {
      final exercicio = ExercicioModel.fromMap('ex-1', {
        'nome': 'Caminhada no simulador',
        'equipamentos': {
          'nome': 'Simulador de Caminhada',
          'equipamento_grupo_muscular': [
            {'grupos_musculares': {'nome': 'Pernas'}},
            {'grupos_musculares': {'nome': 'Cardio'}},
          ],
        },
      });

      expect(exercicio.equipamentoNome, 'Simulador de Caminhada');
      // Mesmo critério do RF004: categoria é o primeiro grupo muscular vinculado.
      expect(exercicio.equipamentoCategoria, 'Pernas');
    });

    test('guarda todos os grupos do equipamento, para o filtro da lista', () {
      final exercicio = ExercicioModel.fromMap('ex-1', {
        'nome': 'Caminhada no simulador',
        'equipamentos': {
          'nome': 'Simulador de Caminhada',
          'equipamento_grupo_muscular': [
            {'grupos_musculares': {'nome': 'Pernas'}},
            {'grupos_musculares': null},
            {'grupos_musculares': {'nome': 'Cardio'}},
          ],
        },
      });

      expect(exercicio.equipamentoGrupos, ['Pernas', 'Cardio']);
    });

    test('os grupos ficam na ordem padrão, mas a categoria continua sendo o primeiro vinculado', () {
      final exercicio = ExercicioModel.fromMap('ex-1', {
        'nome': 'Remada',
        'equipamentos': {
          'nome': 'Remada Sentada',
          'equipamento_grupo_muscular': [
            {'grupos_musculares': {'nome': 'Cardio'}},
            {'grupos_musculares': {'nome': 'Braços'}},
            {'grupos_musculares': {'nome': 'Pernas'}},
          ],
        },
      });

      expect(exercicio.equipamentoGrupos, ['Pernas', 'Braços', 'Cardio']);
      expect(exercicio.equipamentoCategoria, 'Cardio');
    });

    test('sem equipamento vinculado no map, nome e categoria ficam vazios', () {
      final exercicio = ExercicioModel.fromMap('ex-1', {'nome': 'Caminhada no simulador'});

      expect(exercicio.equipamentoNome, '');
      expect(exercicio.equipamentoCategoria, '');
      expect(exercicio.equipamentoGrupos, isEmpty);
      expect(exercicio.contraindicacoes, isEmpty);
    });
  });

  group('ExercicioModel.toMap', () {
    test('gera apenas as colunas próprias da tabela exercicios', () {
      const exercicio = ExercicioModel(
        id: 'ex-1',
        equipamentoId: 'eq-1',
        nome: 'Caminhada no simulador',
        instrucoesPassoAPasso: 'Passo a passo',
        orientacaoAquecimento: 'Aqueça antes',
        contraindicacoes: ['Hipertensão'],
      );

      final map = exercicio.toMap();

      expect(map['equipamento_id'], 'eq-1');
      expect(map['nome'], 'Caminhada no simulador');
      expect(map.containsKey('contraindicacoes'), isFalse);
    });
  });
}
