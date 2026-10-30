// Smoke test básico: garante que a tela de login (RF002) renderiza os
// campos e botões essenciais sem depender do Supabase estar configurado.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:viver_ativo/screens/auth/login_screen.dart';
import 'package:viver_ativo/theme/app_theme.dart';

void main() {
  testWidgets('LoginScreen exibe campos e botão de entrar', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.theme, home: const LoginScreen()));

    expect(find.text('Número de Telefone'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Entrar'), findsOneWidget);
    expect(find.text('Esqueci minha senha'), findsOneWidget);
    expect(find.text('Crie sua conta agora'), findsOneWidget);
  });
}
