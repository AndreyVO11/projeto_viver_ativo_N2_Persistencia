import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../utils/telefone_utils.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

/// RF001, fluxo A3 - Recuperar senha. Sem SMS: a pessoa informa o telefone, responde
/// à pergunta padrão cadastrada no seu perfil e define uma nova senha.
class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key});

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telefoneController = TextEditingController();
  final _respostaController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _carregando = false;

  @override
  void dispose() {
    _telefoneController.dispose();
    _respostaController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _redefinir() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);
    try {
      await context.read<AuthService>().redefinirSenha(
            telefone: _telefoneController.text,
            resposta: _respostaController.text,
            novaSenha: _novaSenhaController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha redefinida com sucesso. Entre com a nova senha.')),
      );
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Senha')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Informe o telefone da sua conta e responda à pergunta abaixo para criar uma nova senha.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Número de Telefone',
                  controller: _telefoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [TelefoneInputFormatter()],
                  validator: validarTelefone,
                ),
                const SizedBox(height: 24),
                Text(perguntaRecuperacao, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                AppTextField(
                  label: 'Sua Resposta',
                  controller: _respostaController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a resposta' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Nova Senha',
                  controller: _novaSenhaController,
                  obscureText: true,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'A senha deve ter ao menos 6 caracteres' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Confirmar Nova Senha',
                  controller: _confirmarSenhaController,
                  obscureText: true,
                  validator: (v) =>
                      v != _novaSenhaController.text ? 'As senhas não são iguais' : null,
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Redefinir senha', onPressed: _redefinir, loading: _carregando),
                const SizedBox(height: 16),
                Text(
                  'Só é possível recuperar contas que já cadastraram a resposta de recuperação.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Voltar para o login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
