import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:viver_ativo/models/treino_model.dart';
import 'package:viver_ativo/screens/admin/treino_form_screen.dart';
import 'package:viver_ativo/services/treino_repository.dart';
import 'package:viver_ativo/theme/app_theme.dart';

class _TreinoRepoFalso implements TreinoRepository {
  TreinoModel? salvo;

  @override
  String novoId() => 'novo-id';

  @override
  Future<void> salvar(TreinoModel treino) async => salvo = treino;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _TreinoRepoFalso repositorio;

  Future<void> abrir(WidgetTester tester, {TreinoModel? treino}) async {
    // Tela larga: a fonte dos testes (Ahem) é bem mais larga que a real e estoura telas pequenas.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    repositorio = _TreinoRepoFalso();
    await tester.pumpWidget(
      Provider<TreinoRepository>.value(
        value: repositorio,
        child: MaterialApp(theme: AppTheme.theme, home: TreinoFormScreen(treino: treino)),
      ),
    );
    await tester.pumpAndSettle();
  }

  const treinoExistente = TreinoModel(
    id: 'tr-1',
    nome: 'Treino de Pernas e Equilíbrio',
    exercicios: [ExercicioDoTreino(id: 'ex-1', nome: 'Leg press', ordem: 0)],
    tipos: ['Pernas'],
  );

  Finder chip(String rotulo) => find.widgetWithText(FilterChip, rotulo);

  testWidgets('mostra os tipos disponíveis e os do treino já marcados', (tester) async {
    await abrir(tester, treino: treinoExistente);

    expect(find.text('Tipo do Treino'), findsOneWidget);
    for (final rotulo in ['Pernas', 'Costas', 'Braços', 'Peito', 'Abdômen', 'Ombros', 'Glúteos', 'Cardio']) {
      expect(chip(rotulo), findsOneWidget, reason: rotulo);
    }
    expect(tester.widget<FilterChip>(chip('Pernas')).selected, isTrue);
    expect(tester.widget<FilterChip>(chip('Braços')).selected, isFalse);
  });

  testWidgets('sem nenhum tipo marcado, não salva e avisa', (tester) async {
    await abrir(tester, treino: treinoExistente);

    await tester.tap(chip('Pernas')); // desmarca o único tipo
    await tester.pump();
    await tester.tap(find.text('Salvar Treino'));
    await tester.pumpAndSettle();

    expect(find.text('Selecione ao menos um tipo de treino.'), findsOneWidget);
    expect(repositorio.salvo, isNull);
  });

  testWidgets('salva o treino com os tipos escolhidos', (tester) async {
    await abrir(tester, treino: treinoExistente);

    await tester.tap(chip('Glúteos'));
    await tester.pump();
    await tester.tap(find.text('Salvar Treino'));
    await tester.pumpAndSettle();

    expect(repositorio.salvo, isNotNull);
    expect(repositorio.salvo!.id, 'tr-1');
    expect(repositorio.salvo!.tipos, ['Pernas', 'Glúteos']);
  });
}
