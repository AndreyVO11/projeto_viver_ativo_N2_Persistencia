import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:viver_ativo/models/exercicio_model.dart';
import 'package:viver_ativo/screens/admin/exercicio_form_screen.dart';
import 'package:viver_ativo/services/exercicio_repository.dart';
import 'package:viver_ativo/theme/app_theme.dart';

class _ExercicioRepoFalso implements ExercicioRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // Exercício já cadastrado, sem foto (evita carregar imagem da rede nos testes).
  ExercicioModel exercicio({List<String> contraindicacoes = const []}) => ExercicioModel(
        id: 'ex-1',
        equipamentoId: 'eq-1',
        nome: 'Pedalada leve',
        instrucoesPassoAPasso: 'Pedale devagar.',
        orientacaoAquecimento: 'Caminhe 5 minutos.',
        contraindicacoes: contraindicacoes,
      );

  Future<void> abrir(WidgetTester tester, ExercicioModel? existente) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      Provider<ExercicioRepository>.value(
        value: _ExercicioRepoFalso(),
        child: MaterialApp(theme: AppTheme.theme, home: ExercicioFormScreen(exercicio: existente)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder chip(String rotulo) => find.widgetWithText(FilterChip, rotulo);
  bool marcado(WidgetTester tester, String rotulo) => tester.widget<FilterChip>(chip(rotulo)).selected;

  Future<void> salvar(WidgetTester tester) async {
    final botao = find.text('Salvar Exercício');
    await tester.ensureVisible(botao);
    await tester.tap(botao);
    await tester.pumpAndSettle();
  }

  const avisoObrigatorio = 'Selecione as contraindicações do exercício ou marque "Nenhuma".';

  testWidgets('exercício novo começa sem nenhuma opção marcada', (tester) async {
    await abrir(tester, null);

    expect(marcado(tester, 'Nenhuma'), isFalse);
    expect(marcado(tester, 'Hipertensão'), isFalse);
  });

  testWidgets('exercício já cadastrado sem contraindicações mostra "Nenhuma" marcada', (tester) async {
    await abrir(tester, exercicio());

    expect(marcado(tester, 'Nenhuma'), isTrue);
  });

  testWidgets('exercício com contraindicações mostra só elas marcadas', (tester) async {
    await abrir(tester, exercicio(contraindicacoes: ['Artrose', 'Problemas no joelho']));

    expect(marcado(tester, 'Artrose'), isTrue);
    expect(marcado(tester, 'Problemas no joelho'), isTrue);
    expect(marcado(tester, 'Nenhuma'), isFalse);
  });

  testWidgets('sem marcar nada (nem "Nenhuma"), não salva e avisa que o campo é obrigatório', (tester) async {
    await abrir(tester, exercicio());

    await tester.tap(chip('Nenhuma')); // desmarca
    await tester.pump();
    await salvar(tester);

    expect(find.text(avisoObrigatorio), findsOneWidget);
  });

  testWidgets('com "Nenhuma" marcada o campo obrigatório está atendido (o próximo aviso é a foto)', (tester) async {
    await abrir(tester, exercicio());

    await salvar(tester);

    expect(find.text(avisoObrigatorio), findsNothing);
    expect(find.text('Selecione uma foto para o exercício.'), findsOneWidget);
  });
}
