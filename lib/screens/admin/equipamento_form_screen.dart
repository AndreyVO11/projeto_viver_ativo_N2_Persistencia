import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/equipamento_model.dart';
import '../../services/equipamento_repository.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/multi_select_chips.dart';
import '../../widgets/primary_button.dart';

/// RF003 - Cadastrar/Editar Equipamento (Quadro 17/18, Figura 10).
///
/// Além dos campos do Quadro 17, este formulário inclui campos extras
/// (Descrição, Para que Serve, Benefícios, Dica de Ouro) para alimentar a
/// tela de detalhes do RF005, que exige mais informação do que o cadastro
/// básico previa.
class EquipamentoFormScreen extends StatefulWidget {
  const EquipamentoFormScreen({super.key, this.equipamento});

  final EquipamentoModel? equipamento;

  @override
  State<EquipamentoFormScreen> createState() => _EquipamentoFormScreenState();
}

class _EquipamentoFormScreenState extends State<EquipamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _paraQueServeController;
  late final TextEditingController _beneficiosController;
  late final TextEditingController _dicaDeOuroController;
  late final TextEditingController _instrucaoController;
  late final TextEditingController _avisoController;

  List<String> _gruposSelecionados = [];
  NivelDificuldade? _nivel;
  File? _imagemSelecionada;
  String _imagemUrlAtual = '';
  bool _salvando = false;

  bool get _editando => widget.equipamento != null;

  @override
  void initState() {
    super.initState();
    final eq = widget.equipamento;
    _nomeController = TextEditingController(text: eq?.nome ?? '');
    _descricaoController = TextEditingController(text: eq?.descricao ?? '');
    _paraQueServeController = TextEditingController(text: eq?.paraQueServe ?? '');
    _beneficiosController = TextEditingController(text: eq?.beneficios.join('\n') ?? '');
    _dicaDeOuroController = TextEditingController(text: eq?.dicaDeOuro ?? '');
    _instrucaoController = TextEditingController();
    _avisoController = TextEditingController();
    _gruposSelecionados = List.from(eq?.gruposMusculares ?? []);
    _nivel = eq?.nivelDificuldade;
    _imagemUrlAtual = eq?.imagemUrl ?? '';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _paraQueServeController.dispose();
    _beneficiosController.dispose();
    _dicaDeOuroController.dispose();
    _instrucaoController.dispose();
    _avisoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarImagem() async {
    final picker = ImagePicker();
    final arquivo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (arquivo != null) {
      setState(() => _imagemSelecionada = File(arquivo.path));
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gruposSelecionados.isEmpty) {
      _mostrarErro('Selecione ao menos um grupo muscular.');
      return;
    }
    if (_nivel == null) {
      _mostrarErro('Selecione o nível de dificuldade.');
      return;
    }
    if (_imagemSelecionada == null && _imagemUrlAtual.isEmpty) {
      _mostrarErro('Selecione uma imagem para o equipamento.');
      return;
    }

    setState(() => _salvando = true);
    try {
      final repositorio = context.read<EquipamentoRepository>();
      final id = widget.equipamento?.id ?? repositorio.novoId();

      var imagemUrl = _imagemUrlAtual;
      if (_imagemSelecionada != null) {
        imagemUrl = await context.read<StorageService>().uploadImagemEquipamento(
              _imagemSelecionada!,
              id,
            );
      }

      final beneficios = _beneficiosController.text
          .split('\n')
          .map((linha) => linha.trim())
          .where((linha) => linha.isNotEmpty)
          .toList();

      final equipamento = EquipamentoModel(
        id: id,
        nome: _nomeController.text,
        imagemUrl: imagemUrl,
        gruposMusculares: _gruposSelecionados,
        nivelDificuldade: _nivel!,
        descricao: _descricaoController.text,
        paraQueServe: _paraQueServeController.text,
        beneficios: beneficios,
        dicaDeOuro: _dicaDeOuroController.text,
      );

      await repositorio.salvar(
        equipamento,
        instrucaoUsoInicial: _editando ? null : _instrucaoController.text,
        avisoSegurancaInicial: _editando ? null : _avisoController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Equipamento salvo com sucesso.')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar Equipamento' : 'Novo Equipamento')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SeletorImagem(
                  imagemSelecionada: _imagemSelecionada,
                  imagemUrlAtual: _imagemUrlAtual,
                  onTap: _selecionarImagem,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Nome do Equipamento',
                  controller: _nomeController,
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe o nome do equipamento' : null,
                ),
                const SizedBox(height: 24),
                MultiSelectChips(
                  label: 'Grupos Musculares',
                  opcoes: gruposMuscularesDisponiveis,
                  selecionados: _gruposSelecionados,
                  onChanged: (novaLista) => setState(() => _gruposSelecionados = novaLista),
                ),
                const SizedBox(height: 24),
                Text('Nível de Dificuldade', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: NivelDificuldade.values.map((nivel) {
                    final marcado = _nivel == nivel;
                    return ChoiceChip(
                      label: Text(
                        nivel.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: marcado ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      selected: marcado,
                      backgroundColor: Colors.white,
                      selectedColor: AppTheme.primary,
                      side: BorderSide(
                        color: marcado ? AppTheme.primary : Colors.grey.shade500,
                        width: marcado ? 1.5 : 1,
                      ),
                      onSelected: (_) => setState(() => _nivel = nivel),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Descrição',
                  controller: _descricaoController,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Para que Serve',
                  controller: _paraQueServeController,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Benefícios (um por linha)',
                  controller: _beneficiosController,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Dica de Ouro',
                  controller: _dicaDeOuroController,
                  maxLines: 2,
                ),
                if (!_editando) ...[
                  const SizedBox(height: 24),
                  AppTextField(
                    label: 'Passo a Passo (Instruções)',
                    controller: _instrucaoController,
                    maxLines: 4,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Informe as instruções de uso' : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Avisos de Segurança',
                    controller: _avisoController,
                    maxLines: 3,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Informe o aviso de segurança' : null,
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    'As instruções de uso e avisos de segurança agora são gerenciados na tela '
                    'de detalhes do equipamento (toque no item da lista em vez do lápis).',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                  ),
                ],
                const SizedBox(height: 32),
                // Um botão embaixo do outro: lado a lado, "Salvar Equipamento" não cabe e fica cortado.
                PrimaryButton(
                  label: 'Salvar Equipamento',
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

class _SeletorImagem extends StatelessWidget {
  const _SeletorImagem({
    required this.imagemSelecionada,
    required this.imagemUrlAtual,
    required this.onTap,
  });

  final File? imagemSelecionada;
  final String imagemUrlAtual;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget conteudo;
    if (imagemSelecionada != null) {
      conteudo = Image.file(imagemSelecionada!, fit: BoxFit.cover);
    } else if (imagemUrlAtual.isNotEmpty) {
      conteudo = Image.network(imagemUrlAtual, fit: BoxFit.cover);
    } else {
      conteudo = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text('Toque para adicionar uma imagem', style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade400),
        ),
        clipBehavior: Clip.antiAlias,
        child: conteudo,
      ),
    );
  }
}
