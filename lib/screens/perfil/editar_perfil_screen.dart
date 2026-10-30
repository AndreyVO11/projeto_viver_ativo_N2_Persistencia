import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/usuario_model.dart';
import '../../services/auth_service.dart';
import '../../services/usuario_repository.dart';
import '../../utils/contraindicacao_utils.dart';
import '../../utils/telefone_utils.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/multi_select_chips.dart';
import '../../widgets/primary_button.dart';

/// RF001, fluxo A1 - Editar informações do cadastro (Quadro 14/15, Figura 6).
/// Alterar o telefone troca também o número usado para entrar no aplicativo.
///
/// Além do nome e do telefone do DERS (Quadro 14), mostra as condições de saúde, para
/// que o aviso de contraindicação (RF006, A3.1) acompanhe mudanças depois do cadastro.
class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  late final String _uid;
  late final Future<UsuarioModel?> _futureUsuario;
  String _telefoneAtual = '';
  List<String> _condicoes = [];
  bool _carregando = false;
  bool _camposPreenchidos = false;

  @override
  void initState() {
    super.initState();
    _uid = context.read<AuthService>().currentUserId!;
    _futureUsuario = context.read<UsuarioRepository>().buscarUsuario(_uid);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);
    try {
      final novoTelefone = normalizarTelefone(_telefoneController.text);
      if (novoTelefone != _telefoneAtual) {
        await context.read<AuthService>().alterarTelefoneLogin(novoTelefone);
      }
      if (!mounted) return;
      await context.read<UsuarioRepository>().atualizarPerfil(
            _uid,
            nome: _nomeController.text,
            condicoesSaude: semNenhuma(_condicoes),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alterações salvas com sucesso.')),
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
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: FutureBuilder<UsuarioModel?>(
        future: _futureUsuario,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final usuario = snapshot.data!;
          if (!_camposPreenchidos) {
            _nomeController.text = usuario.nome;
            _telefoneAtual = normalizarTelefone(usuario.telefone);
            _telefoneController.text = formatarTelefone(usuario.telefone);
            _condicoes = usuario.condicoesSaude.isEmpty ? [condicaoNenhuma] : List.from(usuario.condicoesSaude);
            _camposPreenchidos = true;
          }

          return SafeArea(
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
                      validator: validarTelefone,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ao alterar o telefone, você passará a entrar no aplicativo com o novo número.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 24),
                    MultiSelectChips(
                      label: 'Condições de Saúde',
                      opcoes: condicoesSaudeDisponiveis,
                      opcaoExclusiva: condicaoNenhuma,
                      selecionados: _condicoes,
                      onChanged: (novaLista) => setState(() => _condicoes = novaLista),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Usadas para avisar quando um exercício não é indicado para você.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 24),
                    // Um botão embaixo do outro: lado a lado, "Salvar Alterações" não cabe e fica cortado.
                    PrimaryButton(
                      label: 'Salvar Alterações',
                      loading: _carregando,
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
          );
        },
      ),
    );
  }
}
