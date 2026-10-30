import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../utils/telefone_utils.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

/// RF001, fluxo A3 - cadastro/troca da resposta de recuperação de senha de quem já
/// tem conta (contas antigas e contas criadas por um administrador não têm resposta).
class RespostaRecuperacaoScreen extends StatefulWidget {
  const RespostaRecuperacaoScreen({super.key});

  @override
  State<RespostaRecuperacaoScreen> createState() => _RespostaRecuperacaoScreenState();
}

class _RespostaRecuperacaoScreenState extends State<RespostaRecuperacaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _respostaController = TextEditingController();
  late final Future<bool> _futureTemResposta;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _futureTemResposta = context.read<AuthService>().temRespostaRecuperacao();
  }

  @override
  void dispose() {
    _respostaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await context.read<AuthService>().definirRespostaRecuperacao(_respostaController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resposta de recuperação salva com sucesso.')),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a resposta. Tente novamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resposta de Recuperação')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FutureBuilder<bool>(
                  future: _futureTemResposta,
                  builder: (context, snapshot) {
                    final tem = snapshot.data == true;
                    return Text(
                      tem
                          ? 'Sua resposta de recuperação já está cadastrada. Se quiser, você pode trocá-la abaixo.'
                          : 'Você ainda não cadastrou a resposta de recuperação. Sem ela, não é possível '
                              'criar uma nova senha caso você a esqueça.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    );
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    'Esta resposta serve para criar uma nova senha caso você a esqueça. Para isso, saia da '
                    'conta e toque em “Esqueci minha senha” na tela de login.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 24),
                Text(perguntaRecuperacao, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                AppTextField(
                  label: 'Sua Resposta',
                  controller: _respostaController,
                  validator: (v) =>
                      (v == null || v.trim().length < 3) ? 'Informe a resposta (mínimo de 3 letras)' : null,
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Salvar Resposta', onPressed: _salvar, loading: _salvando),
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
