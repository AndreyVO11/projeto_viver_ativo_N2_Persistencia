import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/instrucao_model.dart';
import '../../services/instrucao_repository.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

/// RF007 - Cadastrar/Editar Instrução de Uso e Aviso de Segurança (Quadro 25/26).
class InstrucaoFormScreen extends StatefulWidget {
  const InstrucaoFormScreen({super.key, required this.equipamentoId, this.instrucao});

  final String equipamentoId;
  final InstrucaoModel? instrucao;

  @override
  State<InstrucaoFormScreen> createState() => _InstrucaoFormScreenState();
}

class _InstrucaoFormScreenState extends State<InstrucaoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _instrucaoController;
  late final TextEditingController _avisoController;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _instrucaoController = TextEditingController(text: widget.instrucao?.instrucaoUso ?? '');
    _avisoController = TextEditingController(text: widget.instrucao?.avisoSeguranca ?? '');
  }

  @override
  void dispose() {
    _instrucaoController.dispose();
    _avisoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final instrucao = InstrucaoModel(
        id: widget.instrucao?.id ?? '',
        equipamentoId: widget.equipamentoId,
        instrucaoUso: _instrucaoController.text,
        avisoSeguranca: _avisoController.text,
      );
      await context.read<InstrucaoRepository>().salvar(instrucao);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Instrução salva com sucesso.')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.instrucao == null ? 'Nova Instrução' : 'Editar Instrução')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Instrução de Uso',
                  controller: _instrucaoController,
                  maxLines: 4,
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe a instrução de uso' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Aviso de Segurança',
                  controller: _avisoController,
                  maxLines: 3,
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe o aviso de segurança' : null,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PrimaryButton(label: 'Salvar', loading: _salvando, onPressed: _salvar),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
