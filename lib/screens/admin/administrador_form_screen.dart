import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../utils/telefone_utils.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

/// RF008 - Cadastrar Administrador (Quadro 27/28, Figura 20).
class AdministradorFormScreen extends StatefulWidget {
  const AdministradorFormScreen({super.key});

  @override
  State<AdministradorFormScreen> createState() => _AdministradorFormScreenState();
}

class _AdministradorFormScreenState extends State<AdministradorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await context.read<AuthService>().criarAdministrador(
            nome: _nomeController.text,
            telefone: _telefoneController.text,
            senha: _senhaController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Administrador cadastrado com sucesso.')),
      );
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Administrador')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Nome Completo',
                  controller: _nomeController,
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe o nome completo' : null,
                ),
                const SizedBox(height: 16),
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
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'A senha deve ter ao menos 6 caracteres' : null,
                ),
                const SizedBox(height: 32),
                // Um botão embaixo do outro: lado a lado, "Salvar Administrador" não cabe e fica cortado.
                PrimaryButton(
                  label: 'Salvar Administrador',
                  loading: _salvando,
                  onPressed: _salvar,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
