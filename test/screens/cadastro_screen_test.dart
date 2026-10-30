import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:viver_ativo/screens/auth/cadastro_screen.dart';
import 'package:viver_ativo/services/auth_service.dart';
import 'package:viver_ativo/theme/app_theme.dart';

/// AuthService que não fala com o Supabase (nem cria um cliente de verdade, que
/// deixaria timers pendentes): só conta os cadastros ou devolve o erro configurado.
class _AuthFalso implements AuthService {
  _AuthFalso({this.erro});

  final AuthException? erro;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  int cadastrosFeitos = 0;
  List<String>? condicoesRecebidas;

  @override
  Future<void> cadastrar({
    required String nome,
    required String telefone,
    required String senha,
    required String respostaRecuperacao,
    required List<String> condicoesSaude,
  }) async {
    if (erro != null) throw erro!;
    cadastrosFeitos++;
    condicoesRecebidas = condicoesSaude;
  }
}

void main() {
  Future<void> abrirCadastro(WidgetTester tester, _AuthFalso auth) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      Provider<AuthService>.value(
        value: auth,
        child: MaterialApp(
          theme: AppTheme.theme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CadastroScreen()),
                  ),
                  child: const Text('TELA DE LOGIN'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('TELA DE LOGIN'));
    await tester.pumpAndSettle();
  }

  Future<void> preencher(WidgetTester tester, String rotulo, String texto) async {
    await tester.enterText(find.widgetWithText(TextFormField, rotulo), texto);
  }

  Future<void> preencherFormulario(WidgetTester tester) async {
    await preencher(tester, 'Nome Completo', 'Maria da Silva');
    await preencher(tester, 'Número de Telefone', '64999998888');
    await preencher(tester, 'Confirmar Número de Telefone', '64999998888');
    await preencher(tester, 'Senha', 'senha123');
    await preencher(tester, 'Sua Resposta', 'Ana Souza');
  }

  testWidgets('conta criada: avisa com um pop-up e volta para a tela de login', (tester) async {
    final auth = _AuthFalso();
    await abrirCadastro(tester, auth);

    await preencherFormulario(tester);
    await tester.tap(find.text('Criar minha conta'));
    await tester.pumpAndSettle();

    // Confere o número antes de criar.
    expect(find.text('Confirme seu número'), findsOneWidget);
    await tester.tap(find.text('Está correto'));
    await tester.pumpAndSettle();

    expect(auth.cadastrosFeitos, 1);
    expect(find.text('Conta cadastrada!'), findsOneWidget);
    expect(find.textContaining('Agora entre no aplicativo'), findsOneWidget);
    // Ainda está no cadastro, por trás do pop-up: só sai depois de a pessoa tocar no botão.
    expect(find.byType(CadastroScreen), findsOneWidget);

    await tester.tap(find.text('Ir para o login'));
    await tester.pumpAndSettle();

    expect(find.byType(CadastroScreen), findsNothing);
    expect(find.text('TELA DE LOGIN'), findsOneWidget);
  });

  Finder chip(String rotulo) => find.widgetWithText(FilterChip, rotulo);

  Future<void> confirmarCadastro(WidgetTester tester) async {
    await tester.tap(find.text('Criar minha conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Está correto'));
    await tester.pumpAndSettle();
  }

  testWidgets('"Nenhuma" já vem marcada e, sem mexer, nenhuma condição é gravada', (tester) async {
    final auth = _AuthFalso();
    await abrirCadastro(tester, auth);
    await preencherFormulario(tester);
    await tester.ensureVisible(chip('Nenhuma'));

    expect(tester.widget<FilterChip>(chip('Nenhuma')).selected, isTrue);

    await confirmarCadastro(tester);

    expect(auth.condicoesRecebidas, isEmpty);
  });

  testWidgets('marcar condições desmarca "Nenhuma" e só as condições são gravadas', (tester) async {
    final auth = _AuthFalso();
    await abrirCadastro(tester, auth);
    await preencherFormulario(tester);

    await tester.ensureVisible(chip('Hipertensão'));
    await tester.tap(chip('Hipertensão'));
    await tester.pump();
    await tester.tap(chip('Diabetes'));
    await tester.pump();

    expect(tester.widget<FilterChip>(chip('Nenhuma')).selected, isFalse);

    await confirmarCadastro(tester);

    expect(auth.condicoesRecebidas, ['Hipertensão', 'Diabetes']);
  });

  testWidgets('o pop-up de conta cadastrada não fecha ao tocar fora dele', (tester) async {
    await abrirCadastro(tester, _AuthFalso());
    await preencherFormulario(tester);
    await tester.tap(find.text('Criar minha conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Está correto'));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.text('Conta cadastrada!'), findsOneWidget);
  });

  testWidgets('se o cadastro falhar, não aparece o pop-up de sucesso', (tester) async {
    await abrirCadastro(tester, _AuthFalso(erro: AuthException('Não foi possível concluir o cadastro. Tente novamente.')));
    await preencherFormulario(tester);
    await tester.tap(find.text('Criar minha conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Está correto'));
    await tester.pumpAndSettle();

    expect(find.text('Conta cadastrada!'), findsNothing);
    expect(find.text('Não foi possível concluir o cadastro. Tente novamente.'), findsOneWidget);
    expect(find.byType(CadastroScreen), findsOneWidget);
  });
}
