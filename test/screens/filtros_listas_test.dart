import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:viver_ativo/models/exercicio_model.dart';
import 'package:viver_ativo/models/treino_model.dart';
import 'package:viver_ativo/screens/exercicios/exercicios_list_screen.dart';
import 'package:viver_ativo/screens/treinos/treinos_list_screen.dart';
import 'package:viver_ativo/services/auth_service.dart';
import 'package:viver_ativo/services/exercicio_repository.dart';
import 'package:viver_ativo/services/treino_repository.dart';
import 'package:viver_ativo/theme/app_theme.dart';

// Repositórios e AuthService falsos: só devolvem os dados da lista, sem Supabase.
class _ExercicioRepoFalso implements ExercicioRepository {
  _ExercicioRepoFalso(this.exercicios);
  final List<ExercicioModel> exercicios;

  @override
  Future<List<ExercicioModel>> buscarExercicios() async => exercicios;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TreinoRepoFalso implements TreinoRepository {
  _TreinoRepoFalso(this.treinos, {this.progresso = const {}});
  final List<TreinoModel> treinos;

  /// treino -> ids dos exercícios já feitos na sessão em andamento.
  final Map<String, Set<String>> progresso;

  @override
  Future<List<TreinoModel>> buscarTreinos() async => treinos;

  @override
  Future<Map<String, Set<String>>> buscarProgressoEmAndamento(String usuarioId) async => progresso;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AuthFalso implements AuthService {
  @override
  String? get currentUserId => 'usuario-1';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ExercicioModel _exercicio(String nome, List<String> grupos) => ExercicioModel(
      id: nome,
      equipamentoId: 'eq',
      nome: nome,
      instrucoesPassoAPasso: '',
      orientacaoAquecimento: '',
      equipamentoNome: 'Equipamento de $nome',
      equipamentoCategoria: grupos.first,
      equipamentoGrupos: grupos,
    );

TreinoModel _treino(String nome, List<String> tipos) => TreinoModel(id: nome, nome: nome, tipos: tipos);

Future<void> _abrir(WidgetTester tester, Widget tela, List<Provider> providers) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: providers,
      child: MaterialApp(theme: AppTheme.theme, home: tela),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _filtro(String rotulo) => find.widgetWithText(ChoiceChip, rotulo);

void main() {
  group('Lista de exercícios: filtro por grupo muscular', () {
    final exercicios = [
      _exercicio('Leg press', ['Pernas', 'Glúteos']),
      _exercicio('Supino', ['Peito', 'Braços']),
      _exercicio('Remada', ['Costas', 'Braços']),
    ];

    Future<void> abrir(WidgetTester tester, List<ExercicioModel> lista) => _abrir(
          tester,
          const ExerciciosListScreen(),
          [Provider<ExercicioRepository>.value(value: _ExercicioRepoFalso(lista))],
        );

    testWidgets('mostra a barra com "Todos" e só os grupos que existem, e todos os exercícios', (tester) async {
      await abrir(tester, exercicios);

      expect(find.text('Filtrar por:'), findsOneWidget);
      for (final rotulo in ['Todos', 'Pernas', 'Costas', 'Braços', 'Peito', 'Glúteos']) {
        expect(_filtro(rotulo), findsOneWidget, reason: rotulo);
      }
      expect(_filtro('Abdômen'), findsNothing);
      for (final nome in ['Leg press', 'Supino', 'Remada']) {
        expect(find.text(nome), findsOneWidget);
      }
    });

    testWidgets('tocar em um grupo mostra só os exercícios dele; "Todos" volta tudo', (tester) async {
      await abrir(tester, exercicios);

      await tester.tap(_filtro('Braços'));
      await tester.pumpAndSettle();
      expect(find.text('Supino'), findsOneWidget);
      expect(find.text('Remada'), findsOneWidget);
      expect(find.text('Leg press'), findsNothing);

      await tester.tap(_filtro('Todos'));
      await tester.pumpAndSettle();
      expect(find.text('Leg press'), findsOneWidget);
    });

    testWidgets('exercício de equipamento com dois grupos aparece nos dois', (tester) async {
      await abrir(tester, exercicios);

      await tester.tap(_filtro('Pernas'));
      await tester.pumpAndSettle();
      expect(find.text('Leg press'), findsOneWidget);

      await tester.tap(_filtro('Glúteos'));
      await tester.pumpAndSettle();
      expect(find.text('Leg press'), findsOneWidget);
      expect(find.text('Supino'), findsNothing);
    });

    testWidgets('com um grupo só, não há o que filtrar e a barra não aparece', (tester) async {
      await abrir(tester, [_exercicio('Leg press', ['Pernas']), _exercicio('Extensora', ['Pernas'])]);

      expect(find.text('Filtrar por:'), findsNothing);
      expect(find.text('Leg press'), findsOneWidget);
      expect(find.text('Extensora'), findsOneWidget);
    });
  });

  group('Lista de treinos: filtro por tipo de treino', () {
    final treinos = [
      _treino('Treino de Pernas e Equilíbrio', ['Pernas', 'Glúteos']),
      _treino('Treino de Parte Superior', ['Braços', 'Costas', 'Ombros', 'Peito']),
      _treino('Treino Cardio Leve', ['Cardio', 'Pernas']),
    ];

    Future<void> abrir(WidgetTester tester, List<TreinoModel> lista) => _abrir(
          tester,
          const TreinosListScreen(),
          [
            Provider<TreinoRepository>.value(value: _TreinoRepoFalso(lista)),
            Provider<AuthService>.value(value: _AuthFalso()),
          ],
        );

    testWidgets('mostra os tipos de cada treino e a barra de filtro', (tester) async {
      await abrir(tester, treinos);

      expect(find.text('Filtrar por:'), findsOneWidget);
      expect(_filtro('Todos'), findsOneWidget);
      expect(_filtro('Cardio'), findsOneWidget);
      expect(find.text('Pernas · Glúteos'), findsOneWidget);
      expect(find.text('Treino de Parte Superior'), findsOneWidget);
    });

    testWidgets('tocar em "Pernas" mostra só os treinos de pernas', (tester) async {
      await abrir(tester, treinos);

      await tester.tap(_filtro('Pernas'));
      await tester.pumpAndSettle();

      expect(find.text('Treino de Pernas e Equilíbrio'), findsOneWidget);
      expect(find.text('Treino Cardio Leve'), findsOneWidget);
      expect(find.text('Treino de Parte Superior'), findsNothing);
    });

    testWidgets('tocar em "Braços" esconde os treinos de pernas', (tester) async {
      await abrir(tester, treinos);

      await tester.tap(_filtro('Braços'));
      await tester.pumpAndSettle();

      expect(find.text('Treino de Parte Superior'), findsOneWidget);
      expect(find.text('Treino de Pernas e Equilíbrio'), findsNothing);

      await tester.tap(_filtro('Todos'));
      await tester.pumpAndSettle();
      expect(find.text('Treino de Pernas e Equilíbrio'), findsOneWidget);
    });

    testWidgets('treinos ainda sem tipo cadastrado continuam na lista, sem barra de filtro', (tester) async {
      await abrir(tester, [_treino('Treino A', []), _treino('Treino B', [])]);

      expect(find.text('Filtrar por:'), findsNothing);
      expect(find.text('Treino A'), findsOneWidget);
      expect(find.text('Treino B'), findsOneWidget);
    });
  });

  group('Lista de treinos: "Em andamento" depois de o administrador mexer no treino', () {
    ExercicioDoTreino ex(String id, int ordem) => ExercicioDoTreino(id: id, nome: id, ordem: ordem);

    Future<void> abrirComProgresso(
      WidgetTester tester,
      List<TreinoModel> lista,
      Map<String, Set<String>> progresso,
    ) =>
        _abrir(
          tester,
          const TreinosListScreen(),
          [
            Provider<TreinoRepository>.value(value: _TreinoRepoFalso(lista, progresso: progresso)),
            Provider<AuthService>.value(value: _AuthFalso()),
          ],
        );

    testWidgets('exercício feito que saiu do treino não conta: "1 de 2", e não "2 de 2"', (tester) async {
      // A pessoa fez "ex-a" e "ex-b"; o administrador tirou "ex-b" do treino, que ficou com "ex-a" e "ex-c".
      final treino = TreinoModel(id: 't-1', nome: 'Treino editado', exercicios: [ex('ex-a', 0), ex('ex-c', 1)]);
      await abrirComProgresso(tester, [treino], {'t-1': {'ex-a', 'ex-b'}});

      expect(find.text('Em andamento: 1 de 2 exercícios'), findsOneWidget);
    });

    testWidgets('se tudo o que foi feito saiu do treino, o "Em andamento" some', (tester) async {
      final treino = TreinoModel(id: 't-1', nome: 'Treino editado', exercicios: [ex('ex-a', 0), ex('ex-c', 1)]);
      await abrirComProgresso(tester, [treino], {'t-1': {'ex-b'}});

      expect(find.textContaining('Em andamento'), findsNothing);
    });
  });
}
