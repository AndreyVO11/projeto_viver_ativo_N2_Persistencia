import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:viver_ativo/models/usuario_model.dart';
import 'package:viver_ativo/screens/perfil/editar_perfil_screen.dart';
import 'package:viver_ativo/services/auth_service.dart';
import 'package:viver_ativo/services/usuario_repository.dart';
import 'package:viver_ativo/theme/app_theme.dart';

class _UsuarioRepoFalso implements UsuarioRepository {
  _UsuarioRepoFalso(this.usuario);
  final UsuarioModel usuario;
  String? nomeSalvo;
  List<String>? condicoesSalvas;

  @override
  Future<UsuarioModel?> buscarUsuario(String uid) async => usuario;

  @override
  Future<void> atualizarPerfil(String uid, {required String nome, required List<String> condicoesSaude}) async {
    nomeSalvo = nome;
    condicoesSalvas = condicoesSaude;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AuthFalso implements AuthService {
  @override
  String? get currentUserId => 'u-1';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _UsuarioRepoFalso repositorio;

  Future<void> abrir(WidgetTester tester, List<String> condicoes) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    repositorio = _UsuarioRepoFalso(
      UsuarioModel(id: 'u-1', nome: 'Maria da Silva', telefone: '64999998888', condicoesSaude: condicoes),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthService>.value(value: _AuthFalso()),
          Provider<UsuarioRepository>.value(value: repositorio),
        ],
        child: MaterialApp(
          theme: AppTheme.theme,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditarPerfilScreen()),
                ),
                child: const Text('ABRIR'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ABRIR'));
    await tester.pumpAndSettle();
  }

  Finder chip(String rotulo) => find.widgetWithText(FilterChip, rotulo);
  bool marcado(WidgetTester tester, String rotulo) => tester.widget<FilterChip>(chip(rotulo)).selected;

  testWidgets('mostra as condições de saúde que a pessoa já tem', (tester) async {
    await abrir(tester, ['Artrose', 'Diabetes']);

    expect(find.text('Condições de Saúde'), findsOneWidget);
    expect(marcado(tester, 'Artrose'), isTrue);
    expect(marcado(tester, 'Diabetes'), isTrue);
    expect(marcado(tester, 'Hipertensão'), isFalse);
    expect(marcado(tester, 'Nenhuma'), isFalse);
  });

  testWidgets('quem não tem nenhuma condição vê "Nenhuma" marcada', (tester) async {
    await abrir(tester, []);

    expect(marcado(tester, 'Nenhuma'), isTrue);
  });

  testWidgets('altera as condições e salva só as de verdade', (tester) async {
    await abrir(tester, ['Artrose']);

    await tester.tap(chip('Hipertensão'));
    await tester.pump();
    await tester.tap(find.text('Salvar Alterações'));
    await tester.pumpAndSettle();

    expect(repositorio.condicoesSalvas, ['Artrose', 'Hipertensão']);
    expect(repositorio.nomeSalvo, 'Maria da Silva');
  });

  testWidgets('marcar "Nenhuma" limpa as condições (a saúde melhorou)', (tester) async {
    await abrir(tester, ['Artrose', 'Diabetes']);

    await tester.tap(chip('Nenhuma'));
    await tester.pump();
    await tester.tap(find.text('Salvar Alterações'));
    await tester.pumpAndSettle();

    expect(repositorio.condicoesSalvas, isEmpty);
  });
}
