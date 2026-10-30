import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'home_screen.dart';

/// Decide entre a tela de login e a tela inicial, conforme o estado de
/// autenticação (equivalente ao "primeiro acesso" do RF001/RF002).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return StreamBuilder<bool>(
      stream: auth.authStateChanges,
      initialData: auth.currentUserId != null,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final logado = snapshot.data ?? false;
        return logado ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
