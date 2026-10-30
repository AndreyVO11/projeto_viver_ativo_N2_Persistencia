import 'package:flutter_test/flutter_test.dart';
import 'package:viver_ativo/models/historico_model.dart';

void main() {
  testesSessaoEmAndamento();

  group('ExecucaoModel.fromMap', () {
    test('lê o exercício, o treino, a duração e a data', () {
      final execucao = ExecucaoModel.fromMap({
        'id': 'ex-1',
        'exercicio_nome': 'Pedalada leve',
        'treino_nome': 'Treino Iniciante',
        'duracao_segundos': 222,
        'concluido_em': '2026-10-17T13:45:00+00:00',
      });

      expect(execucao.exercicioNome, 'Pedalada leve');
      expect(execucao.treinoNome, 'Treino Iniciante');
      expect(execucao.duracaoSegundos, 222);
      expect(execucao.concluidoEm.toUtc(), DateTime.utc(2026, 10, 17, 13, 45));
    });

    test('registro antigo, sem duração nem nome, continua legível', () {
      final execucao = ExecucaoModel.fromMap({
        'id': 'ex-2',
        'exercicio_nome': null,
        'treino_nome': null,
        'duracao_segundos': null,
        'concluido_em': '2026-10-16T22:26:41.203425+00:00',
      });

      expect(execucao.duracaoSegundos, isNull);
      expect(execucao.exercicioNome, 'Exercício removido');
      expect(execucao.treinoNome, '');
    });
  });

  group('SessaoTreinoModel.fromMap (histórico de treinos)', () {
    Map<String, dynamic> sessao({String? concluidoEm}) => {
          'id': 's-1',
          'treino_nome': 'Treino Iniciante',
          'total_exercicios': 3,
          'iniciado_em': '2026-10-17T13:00:00+00:00',
          'concluido_em': concluidoEm,
          'historico_execucoes': <Map<String, dynamic>>[
            {
              'id': 'b',
              'exercicio_nome': 'Segundo',
              'treino_nome': 'Treino Iniciante',
              'duracao_segundos': 120,
              'concluido_em': '2026-10-17T13:05:00+00:00',
            },
            {
              'id': 'a',
              'exercicio_nome': 'Primeiro',
              'treino_nome': 'Treino Iniciante',
              'duracao_segundos': 60,
              'concluido_em': '2026-10-17T13:02:00+00:00',
            },
          ],
        };

    test('ordena os exercícios na ordem em que foram feitos', () {
      final s = SessaoTreinoModel.fromMap(sessao());
      expect(s.execucoes.map((e) => e.exercicioNome), ['Primeiro', 'Segundo']);
    });

    test('soma o tempo e conta os exercícios concluídos', () {
      final s = SessaoTreinoModel.fromMap(sessao());
      expect(s.duracaoTotalSegundos, 180);
      expect(s.exerciciosConcluidos, 2);
      expect(s.totalExercicios, 3);
    });

    test('sessão sem data de conclusão é parcial; com data, concluída', () {
      expect(SessaoTreinoModel.fromMap(sessao()).concluida, isFalse);
      expect(SessaoTreinoModel.fromMap(sessao(concluidoEm: '2026-10-17T13:10:00+00:00')).concluida, isTrue);
    });

    test('exercício sem tempo medido não entra na soma', () {
      final dados = sessao();
      (dados['historico_execucoes'] as List).add({
        'id': 'c',
        'exercicio_nome': 'Terceiro',
        'treino_nome': 'Treino Iniciante',
        'duracao_segundos': null,
        'concluido_em': '2026-10-17T13:08:00+00:00',
      });
      expect(SessaoTreinoModel.fromMap(dados).duracaoTotalSegundos, 180);
    });

    test('sessão sem exercícios retorna lista vazia', () {
      final s = SessaoTreinoModel.fromMap({
        'id': 's-2',
        'treino_nome': 'Vazio',
        'total_exercicios': 1,
        'iniciado_em': '2026-10-17T13:00:00+00:00',
        'concluido_em': null,
      });
      expect(s.execucoes, isEmpty);
    });
  });
}

void testesSessaoEmAndamento() {
  group('SessaoEmAndamentoModel.fromMap (retomar o treino de onde parou)', () {
    test('mapeia cada exercício já feito para o tempo gasto', () {
      final s = SessaoEmAndamentoModel.fromMap({
        'id': 's-1',
        'iniciado_em': '2026-10-17T13:00:00+00:00',
        'historico_execucoes': [
          {'exercicio_id': 'ex-1', 'duracao_segundos': 60},
          {'exercicio_id': 'ex-2', 'duracao_segundos': 90},
        ],
      });

      expect(s.id, 's-1');
      expect(s.duracoes, {'ex-1': 60, 'ex-2': 90});
    });

    test('exercício excluído pelo administrador (id nulo) é ignorado', () {
      final s = SessaoEmAndamentoModel.fromMap({
        'id': 's-1',
        'iniciado_em': '2026-10-17T13:00:00+00:00',
        'historico_execucoes': [
          {'exercicio_id': null, 'duracao_segundos': 60},
          {'exercicio_id': 'ex-2', 'duracao_segundos': null},
        ],
      });

      expect(s.duracoes, {'ex-2': 0});
    });

    test('sessão sem exercícios feitos retorna mapa vazio', () {
      final s = SessaoEmAndamentoModel.fromMap({'id': 's-1', 'iniciado_em': '2026-10-17T13:00:00+00:00'});
      expect(s.duracoes, isEmpty);
    });
  });

  group('SessaoEmAndamentoModel.daSessaoMaisRecente', () {
    test('sem nenhuma sessão, não há treino em andamento', () {
      expect(SessaoEmAndamentoModel.daSessaoMaisRecente(null), isNull);
    });

    test('sessão mais recente já concluída: não há treino em andamento', () {
      final s = SessaoEmAndamentoModel.daSessaoMaisRecente({
        'id': 's-1',
        'iniciado_em': '2026-10-17T13:00:00+00:00',
        'concluido_em': '2026-10-17T13:20:00+00:00',
        'historico_execucoes': [
          {'exercicio_id': 'ex-1', 'duracao_segundos': 60},
        ],
      });
      expect(s, isNull);
    });

    test('sessão mais recente aberta: devolve o que já foi feito', () {
      final s = SessaoEmAndamentoModel.daSessaoMaisRecente({
        'id': 's-1',
        'iniciado_em': '2026-10-17T13:00:00+00:00',
        'concluido_em': null,
        'historico_execucoes': [
          {'exercicio_id': 'ex-1', 'duracao_segundos': 60},
        ],
      });
      expect(s, isNotNull);
      expect(s!.duracoes, {'ex-1': 60});
    });
  });

  group('SessaoEmAndamentoModel.progressoPorTreino (lista de treinos)', () {
    Map<String, dynamic> sessao(String treino, {String? concluidoEm, int feitos = 1}) => {
          'treino_id': treino,
          'concluido_em': concluidoEm,
          'historico_execucoes': [for (var i = 0; i < feitos; i++) <String, dynamic>{'exercicio_id': 'ex$i'}],
        };

    test('guarda os exercícios feitos de cada treino em andamento', () {
      final progresso = SessaoEmAndamentoModel.progressoPorTreino([
        sessao('t-1', feitos: 4),
        sessao('t-2', feitos: 1),
      ]);
      expect(progresso, {
        't-1': {'ex0', 'ex1', 'ex2', 'ex3'},
        't-2': {'ex0'},
      });
    });

    test('execução de exercício excluído (exercicio_id nulo) não entra no progresso', () {
      final progresso = SessaoEmAndamentoModel.progressoPorTreino([
        {
          'treino_id': 't-1',
          'concluido_em': null,
          'historico_execucoes': [
            <String, dynamic>{'exercicio_id': 'ex0'},
            <String, dynamic>{'exercicio_id': null},
          ],
        },
        {
          // só havia exercício excluído: não há o que mostrar como "em andamento"
          'treino_id': 't-2',
          'concluido_em': null,
          'historico_execucoes': [<String, dynamic>{'exercicio_id': null}],
        },
      ]);
      expect(progresso, {'t-1': {'ex0'}});
    });

    test('sessão antiga aberta não volta como em andamento depois de o treino ser refeito', () {
      // Da mais recente para a mais antiga: a última vez foi concluída; a anterior ficou parcial.
      final progresso = SessaoEmAndamentoModel.progressoPorTreino([
        sessao('t-1', feitos: 5, concluidoEm: '2026-10-18T01:59:18+00:00'),
        sessao('t-1', feitos: 1),
      ]);
      expect(progresso, isEmpty);
    });

    test('ao recomeçar, vale a sessão nova e não a que ficou pela metade', () {
      final progresso = SessaoEmAndamentoModel.progressoPorTreino([
        sessao('t-1', feitos: 2),
        sessao('t-1', feitos: 4),
      ]);
      expect(progresso, {'t-1': {'ex0', 'ex1'}});
    });

    test('sessão recém-aberta, sem exercício feito, apaga o "em andamento" da anterior', () {
      final progresso = SessaoEmAndamentoModel.progressoPorTreino([
        sessao('t-1', feitos: 0),
        sessao('t-1', feitos: 3),
      ]);
      expect(progresso, isEmpty);
    });

    test('sessão de treino excluído (treino_id nulo) é ignorada', () {
      final progresso = SessaoEmAndamentoModel.progressoPorTreino([
        {
          'treino_id': null,
          'concluido_em': null,
          'historico_execucoes': [<String, dynamic>{'exercicio_id': 'ex0'}],
        },
      ]);
      expect(progresso, isEmpty);
    });
  });

  group('SessaoEmAndamentoModel.feitosNoTreino (rótulo "Em andamento: X de N")', () {
    test('conta só os exercícios feitos que o treino ainda tem', () {
      // O administrador tirou "ex-b" do treino depois de a pessoa já tê-lo feito.
      expect(SessaoEmAndamentoModel.feitosNoTreino({'ex-a', 'ex-b'}, ['ex-a', 'ex-c', 'ex-d']), 1);
    });

    test('sem sessão em andamento, nada foi feito', () {
      expect(SessaoEmAndamentoModel.feitosNoTreino(null, ['ex-a', 'ex-b']), 0);
    });

    test('se tudo o que foi feito saiu do treino, o resultado é zero e o rótulo some', () {
      expect(SessaoEmAndamentoModel.feitosNoTreino({'ex-b'}, ['ex-a', 'ex-c']), 0);
    });
  });
}
