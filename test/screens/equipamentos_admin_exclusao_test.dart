import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:viver_ativo/models/equipamento_model.dart';
import 'package:viver_ativo/models/exercicio_model.dart';
import 'package:viver_ativo/screens/admin/equipamentos_admin_list_screen.dart';
import 'package:viver_ativo/services/equipamento_repository.dart';
import 'package:viver_ativo/services/exercicio_repository.dart';
import 'package:viver_ativo/theme/app_theme.dart';

// Repositórios falsos: sem Supabase. O de equipamentos anota o que foi excluído.
class _EquipamentoRepoFalso implements EquipamentoRepository {
  _EquipamentoRepoFalso(this.lista);
  final List<EquipamentoModel> lista;
  final excluidos = <String>[];

  @override
  Future<List<EquipamentoModel>> buscarEquipamentos() async => List.of(lista);

  @override
  Future<void> excluir(String id) async {
    excluidos.add(id);
    lista.removeWhere((e) => e.id == id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ExercicioRepoFalso implements ExercicioRepository {
  _ExercicioRepoFalso(this.nomes, {this.falha = false});
  final List<String> nomes;
  final bool falha;

  @override
  Future<List<ExercicioModel>> buscarPorEquipamento(String equipamentoId) async {
    if (falha) throw Exception('sem conexão');
    return [
      for (final nome in nomes)
        ExercicioModel(
          id: nome,
          equipamentoId: equipamentoId,
          nome: nome,
          instrucoesPassoAPasso: '',
          orientacaoAquecimento: '',
        ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _equipamento = EquipamentoModel(
  id: 'eq-1',
  nome: 'Supino Sentado',
  imagemUrl: '',
  gruposMusculares: ['Peito'],
  nivelDificuldade: NivelDificuldade.facil,
);

void main() {
  Future<_EquipamentoRepoFalso> abrir(
    WidgetTester tester,
    _ExercicioRepoFalso exercicios,
  ) async {
    // Tela larga: a fonte dos testes (Ahem) é bem mais larga que a real.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final equipamentos = _EquipamentoRepoFalso([_equipamento]);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<EquipamentoRepository>.value(value: equipamentos),
          Provider<ExercicioRepository>.value(value: exercicios),
        ],
        child: MaterialApp(theme: AppTheme.theme, home: const EquipamentosAdminListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return equipamentos;
  }

  Future<void> tocarExcluir(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Excluir'));
    await tester.pumpAndSettle();
  }

  group('Excluir equipamento: o aviso mostra os exercícios que serão excluídos junto', () {
    testWidgets('lista o nome de cada exercício vinculado', (tester) async {
      await abrir(tester, _ExercicioRepoFalso(['Supino Reto', 'Supino Inclinado']));
      await tocarExcluir(tester);

      expect(find.text('Deseja realmente excluir este equipamento?'), findsOneWidget);
      expect(find.textContaining('Os 2 exercícios abaixo também serão excluídos'), findsOneWidget);
      expect(find.textContaining('• Supino Reto'), findsOneWidget);
      expect(find.textContaining('• Supino Inclinado'), findsOneWidget);
      expect(find.textContaining('O histórico de quem já fez esses exercícios será mantido.'), findsOneWidget);
    });

    testWidgets('"Cancelar" fecha o aviso e não exclui nada', (tester) async {
      final equipamentos = await abrir(tester, _ExercicioRepoFalso(['Supino Reto']));
      await tocarExcluir(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(equipamentos.excluidos, isEmpty);
      expect(find.text('Supino Sentado'), findsOneWidget);
    });

    testWidgets('"Excluir" no aviso exclui o equipamento e mostra a confirmação', (tester) async {
      final equipamentos = await abrir(tester, _ExercicioRepoFalso(['Supino Reto']));
      await tocarExcluir(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Excluir'));
      await tester.pumpAndSettle();

      expect(equipamentos.excluidos, ['eq-1']);
      expect(find.text('Equipamento excluído com sucesso.'), findsOneWidget);
    });

    testWidgets('equipamento sem exercícios: o aviso diz que não há exercícios vinculados', (tester) async {
      await abrir(tester, _ExercicioRepoFalso([]));
      await tocarExcluir(tester);

      expect(find.textContaining('Este equipamento não tem exercícios vinculados.'), findsOneWidget);
    });

    testWidgets('se a consulta dos exercícios falhar, o aviso continua e diz isso em geral', (tester) async {
      await abrir(tester, _ExercicioRepoFalso([], falha: true));
      await tocarExcluir(tester);

      expect(find.textContaining('Os exercícios vinculados a este equipamento também serão excluídos'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Excluir'), findsOneWidget);
    });
  });
}
