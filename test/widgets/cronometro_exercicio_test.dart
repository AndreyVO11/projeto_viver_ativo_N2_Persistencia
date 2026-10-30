import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viver_ativo/theme/app_theme.dart';
import 'package:viver_ativo/widgets/cronometro_exercicio.dart';

void main() {
  late DateTime relogio;
  int? segundosEntregues;

  Future<void> montar(WidgetTester tester) async {
    relogio = DateTime(2026, 10, 17, 13, 0, 0);
    segundosEntregues = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: CronometroExercicio(
              agora: () => relogio,
              onConcluir: (segundos) => segundosEntregues = segundos,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> passar(WidgetTester tester, int segundos) async {
    relogio = relogio.add(Duration(seconds: segundos));
    await tester.pump(Duration(seconds: segundos));
  }

  testWidgets('começa só com o botão Iniciar Exercício, sem Concluir', (tester) async {
    await montar(tester);

    expect(find.text('Iniciar Exercício'), findsOneWidget);
    expect(find.text('Concluir Exercício'), findsNothing);
  });

  testWidgets('ao iniciar, o cronômetro conta o tempo e aparece Concluir', (tester) async {
    await montar(tester);

    await tester.tap(find.text('Iniciar Exercício'));
    await tester.pump();
    expect(find.text('00:00'), findsOneWidget);

    await passar(tester, 3);
    expect(find.text('00:03'), findsOneWidget);
    expect(find.text('Concluir Exercício'), findsOneWidget);
    expect(find.text('Pausar'), findsOneWidget);
  });

  testWidgets('concluir entrega o tempo medido, em segundos', (tester) async {
    await montar(tester);
    await tester.tap(find.text('Iniciar Exercício'));
    await tester.pump();
    await passar(tester, 75);

    await tester.tap(find.text('Concluir Exercício'));
    await tester.pump();

    expect(segundosEntregues, 75);
  });

  testWidgets('o tempo em pausa não é contado e Retomar continua de onde parou', (tester) async {
    await montar(tester);
    await tester.tap(find.text('Iniciar Exercício'));
    await tester.pump();
    await passar(tester, 10);

    await tester.tap(find.text('Pausar'));
    await tester.pump();
    expect(find.text('Em pausa'), findsOneWidget);
    await passar(tester, 30); // 30 s parado: não conta
    expect(find.text('00:10'), findsOneWidget);

    await tester.tap(find.text('Retomar'));
    await tester.pump();
    await passar(tester, 5);
    expect(find.text('00:15'), findsOneWidget);

    await tester.tap(find.text('Concluir Exercício'));
    await tester.pump();
    expect(segundosEntregues, 15);
  });
}
