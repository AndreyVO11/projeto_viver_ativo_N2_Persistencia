import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../utils/telefone_utils.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'cadastro_screen.dart';
import 'recuperar_senha_screen.dart';

/// RF002 - Autenticar Usuário (Quadro 10/11, Figura 7), com o fluxo A3 de
/// recuperação de senha ("Esqueci minha senha").
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;

  @override
  void dispose() {
    _telefoneController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);
    try {
      await context.read<AuthService>().login(
            telefone: _telefoneController.text,
            senha: _senhaController.text,
          );
      // AuthGate cuida do redirecionamento após o login bem-sucedido.
    } on AuthException catch (e) {
      _mostrarErro(e.message);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.fitness_center, size: 72, color: Color(0xFF1B5E20)),
                  const SizedBox(height: 16),
                  Text(
                    'Viver Ativo',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    label: 'Número de Telefone',
                    controller: _telefoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [TelefoneInputFormatter()],
                    validator: validarTelefone,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Senha',
                    controller: _senhaController,
                    obscureText: true,
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe a senha' : null,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(label: 'Entrar', onPressed: _entrar, loading: _carregando),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RecuperarSenhaScreen()),
                    ),
                    child: const Text('Esqueci minha senha'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CadastroScreen()),
                    ),
                    child: const Text('Crie sua conta agora'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
