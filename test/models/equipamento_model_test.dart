import 'package:flutter_test/flutter_test.dart';
import 'package:viver_ativo/models/equipamento_model.dart';

void main() {
  group('NivelDificuldadeLabel', () {
    test('label retorna o texto exibido em cada tela (Quadro 17)', () {
      expect(NivelDificuldade.facil.label, 'Fácil');
      expect(NivelDificuldade.medio.label, 'Médio');
      expect(NivelDificuldade.dificil.label, 'Difícil');
    });

    test('fromLabel reconhece os três valores do domínio da tela', () {
      expect(NivelDificuldadeLabel.fromLabel('Médio'), NivelDificuldade.medio);
      expect(NivelDificuldadeLabel.fromLabel('Difícil'), NivelDificuldade.dificil);
      expect(NivelDificuldadeLabel.fromLabel('Fácil'), NivelDificuldade.facil);
    });

    test('fromLabel usa Fácil como padrão para valor desconhecido ou nulo', () {
      expect(NivelDificuldadeLabel.fromLabel(null), NivelDificuldade.facil);
      expect(NivelDificuldadeLabel.fromLabel('valor-invalido'), NivelDificuldade.facil);
    });
  });

  group('EquipamentoModel.fromMap', () {
    test('lê os campos simples da tabela equipamentos', () {
      final equipamento = EquipamentoModel.fromMap('eq-1', {
        'nome': 'Simulador de Caminhada',
        'imagem_url': 'https://exemplo.com/foto.jpg',
        'nivel_dificuldade': 'Fácil',
        'descricao': 'Descrição',
        'para_que_serve': 'Para que serve',
        'dica_de_ouro': 'Dica',
      });

      expect(equipamento.id, 'eq-1');
      expect(equipamento.nome, 'Simulador de Caminhada');
      expect(equipamento.imagemUrl, 'https://exemplo.com/foto.jpg');
      expect(equipamento.nivelDificuldade, NivelDificuldade.facil);
      expect(equipamento.descricao, 'Descrição');
      expect(equipamento.paraQueServe, 'Para que serve');
      expect(equipamento.dicaDeOuro, 'Dica');
    });

    test('extrai os grupos musculares do join equipamento_grupo_muscular', () {
      final equipamento = EquipamentoModel.fromMap('eq-1', {
        'nome': 'Simulador de Caminhada',
        'nivel_dificuldade': 'Fácil',
        'equipamento_grupo_muscular': [
          {'grupos_musculares': {'nome': 'Pernas'}},
          {'grupos_musculares': {'nome': 'Cardio'}},
        ],
      });

      expect(equipamento.gruposMusculares, ['Pernas', 'Cardio']);
      // RF004, Quadro 19 - a categoria da listagem é o primeiro grupo vinculado.
      expect(equipamento.tagCategoria, 'Pernas');
    });

    test('ordena os benefícios do join equipamento_beneficios pelo campo ordem', () {
      final equipamento = EquipamentoModel.fromMap('eq-1', {
        'nome': 'Simulador de Caminhada',
        'nivel_dificuldade': 'Fácil',
        'equipamento_beneficios': [
          {'descricao': 'Segundo benefício', 'ordem': 1},
          {'descricao': 'Primeiro benefício', 'ordem': 0},
        ],
      });

      expect(equipamento.beneficios, ['Primeiro benefício', 'Segundo benefício']);
    });

    test('lê as instruções do join equipamento_instrucoes (RF007)', () {
      final equipamento = EquipamentoModel.fromMap('eq-1', {
        'nome': 'Simulador de Caminhada',
        'nivel_dificuldade': 'Fácil',
        'equipamento_instrucoes': [
          {
            'id': 'instr-1',
            'equipamento_id': 'eq-1',
            'instrucao_uso': 'Passo a passo',
            'aviso_seguranca': 'Aviso',
          },
        ],
      });

      expect(equipamento.instrucoes, hasLength(1));
      expect(equipamento.instrucoes.first.instrucaoUso, 'Passo a passo');
      expect(equipamento.instrucoes.first.avisoSeguranca, 'Aviso');
    });

    test('campos ausentes no map não quebram o parse (valores padrão)', () {
      final equipamento = EquipamentoModel.fromMap('eq-1', {'nivel_dificuldade': 'Fácil'});

      expect(equipamento.nome, '');
      expect(equipamento.gruposMusculares, isEmpty);
      expect(equipamento.beneficios, isEmpty);
      expect(equipamento.instrucoes, isEmpty);
      expect(equipamento.tagCategoria, '');
    });
  });

  group('EquipamentoModel.toMap', () {
    test('gera apenas as colunas próprias da tabela equipamentos (snake_case)', () {
      const equipamento = EquipamentoModel(
        id: 'eq-1',
        nome: 'Simulador de Caminhada',
        imagemUrl: 'https://exemplo.com/foto.jpg',
        gruposMusculares: ['Pernas'],
        nivelDificuldade: NivelDificuldade.medio,
      );

      final map = equipamento.toMap();

      expect(map['nome'], 'Simulador de Caminhada');
      expect(map['imagem_url'], 'https://exemplo.com/foto.jpg');
      expect(map['nivel_dificuldade'], 'Médio');
      // Relacionamentos N:N/1:N são sincronizados pelo repositório, não pelo toMap.
      expect(map.containsKey('gruposMusculares'), isFalse);
      expect(map.containsKey('instrucoes'), isFalse);
    });
  });
}
