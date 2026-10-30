import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/usuario_model.dart';
import '../../services/auth_service.dart';
import '../../utils/contraindicacao_utils.dart';
import '../../utils/telefone_utils.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/multi_select_chips.dart';
import '../../widgets/primary_button.dart';

/// RF001 - Manter Usuários, fluxo básico de cadastro (Quadro 12/13, Figura 4).
/// O telefone é pedido duas vezes e conferido numa janela de confirmação, porque
/// ele é o identificador de acesso: um erro de digitação deixaria a conta
/// inacessível. A resposta da pergunta padrão permite recuperar a senha (A3).
class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _confirmarTelefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _respostaController = TextEditingController();
  // Valor padrão do DERS (Quadro 12): "Nenhuma". Ela não é gravada, só as condições de verdade.
  List<String> _condicoesSelecionadas = [condicaoNenhuma];
  bool _carregando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _confirmarTelefoneController.dispose();
    _senhaController.dispose();
    _respostaController.dispose();
    super.dispose();
  }

  Future<bool> _confirmarNumero() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirme seu número'),
        content: Text(
          'Seu telefone é ${formatarTelefone(_telefoneController.text)}?\n\n'
          'Ele será usado para entrar no aplicativo. Se estiver errado, você não '
          'conseguirá acessar sua conta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Corrigir'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Está correto'),
          ),
        ],
      ),
    );
    return confirmado ?? false;
  }

  Future<void> _avisarContaCadastrada() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 56),
        title: const Text('Conta cadastrada!'),
        content: const Text(
          'Sua conta foi criada com sucesso.\n\n'
          'Agora entre no aplicativo com o seu número de telefone e a senha que você acabou de criar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ir para o login'),
          ),
        ],
      ),
    );
  }

  Future<void> _criarConta() async {
    if (!_formKey.currentState!.validate()) return;
    if (!await _confirmarNumero() || !mounted) return;
    setState(() => _carregando = true);
    try {
      await context.read<AuthService>().cadastrar(
            nome: _nomeController.text,
            telefone: _telefoneController.text,
            senha: _senhaController.text,
            respostaRecuperacao: _respostaController.text,
            condicoesSaude: semNenhuma(_condicoesSelecionadas),
          );
      if (!mounted) return;
      setState(() => _carregando = false); // não deixa o botão girando atrás do pop-up
      await _avisarContaCadastrada();
      // A sessão do cadastro já foi encerrada: a base da navegação continua sendo a
      // tela de login, para onde esta tela de cadastro volta.
      if (mounted) Navigator.of(context).popUntil((rota) => rota.isFirst);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      if (e.message.contains('Deseja fazer login')) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
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
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe seu nome completo' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Número de Telefone',
                  controller: _telefoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [TelefoneInputFormatter()],
                  helperText: 'Com DDD. Ele será usado para entrar no aplicativo.',
                  validator: validarTelefone,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Confirmar Número de Telefone',
                  controller: _confirmarTelefoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [TelefoneInputFormatter()],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Confirme o número de telefone';
                    if (normalizarTelefone(v) != normalizarTelefone(_telefoneController.text)) {
                      return 'Os números de telefone não são iguais';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Senha',
                  controller: _senhaController,
                  obscureText: true,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'A senha deve ter ao menos 6 caracteres' : null,
                ),
                const SizedBox(height: 24),
                Text('Recuperação de Senha', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Caso esqueça a senha, você poderá criar uma nova respondendo à pergunta abaixo. '
                  'Escolha uma resposta de que você sempre vai se lembrar.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(perguntaRecuperacao, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                AppTextField(
                  label: 'Sua Resposta',
                  controller: _respostaController,
                  validator: (v) =>
                      (v == null || v.trim().length < 3) ? 'Informe a resposta (mínimo de 3 letras)' : null,
                ),
                const SizedBox(height: 24),
                MultiSelectChips(
                  label: 'Condições de Saúde',
                  opcoes: condicoesSaudeDisponiveis,
                  opcaoExclusiva: condicaoNenhuma,
                  selecionados: _condicoesSelecionadas,
                  onChanged: (novaLista) => setState(() => _condicoesSelecionadas = novaLista),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Criar minha conta',
                  onPressed: _criarConta,
                  loading: _carregando,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Já tem uma conta? Entre agora'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
