import 'package:flutter_test/flutter_test.dart';
import 'package:viver_ativo/models/instrucao_model.dart';

void main() {
  group('InstrucaoModel', () {
    test('fromMap lê os campos da tabela equipamento_instrucoes', () {
      final instrucao = InstrucaoModel.fromMap({
        'id': 'instr-1',
        'equipamento_id': 'eq-1',
        'instrucao_uso': 'Segure-se nas barras de apoio',
        'aviso_seguranca': 'Não use em caso de dor',
      });

      expect(instrucao.id, 'instr-1');
      expect(instrucao.equipamentoId, 'eq-1');
      expect(instrucao.instrucaoUso, 'Segure-se nas barras de apoio');
      expect(instrucao.avisoSeguranca, 'Não use em caso de dor');
    });

    test('toMap gera as colunas snake_case (sem o id, gerado pelo banco)', () {
      const instrucao = InstrucaoModel(
        id: 'instr-1',
        equipamentoId: 'eq-1',
        instrucaoUso: 'Passo a passo',
        avisoSeguranca: 'Aviso',
      );

      expect(instrucao.toMap(), {
        'equipamento_id': 'eq-1',
        'instrucao_uso': 'Passo a passo',
        'aviso_seguranca': 'Aviso',
      });
    });
  });
}
