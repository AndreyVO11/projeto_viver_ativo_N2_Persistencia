import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/equipamento_model.dart';
import '../../models/exercicio_model.dart';
import '../../models/usuario_model.dart';
import '../../services/exercicio_repository.dart';
import '../../services/storage_service.dart';
import '../../utils/contraindicacao_utils.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/equipamento_selector_sheet.dart';
import '../../widgets/multi_select_chips.dart';
import '../../widgets/primary_button.dart';

/// RF006 - Cadastrar/Editar Exercício (Quadro 21/22, Figura 14).
class ExercicioFormScreen extends StatefulWidget {
  const ExercicioFormScreen({super.key, this.exercicio, this.equipamentoInicial});

  final ExercicioModel? exercicio;

  /// Pré-seleciona o equipamento quando o formulário é aberto a partir da
  /// tela de detalhes de um equipamento específico.
  final EquipamentoModel? equipamentoInicial;

  @override
  State<ExercicioFormScreen> createState() => _ExercicioFormScreenState();
}

class _ExercicioFormScreenState extends State<ExercicioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _instrucoesController;
  late final TextEditingController _aquecimentoController;

  String? _equipamentoId;
  String _equipamentoNome = '';
  List<String> _contraindicacoesSelecionadas = [];
  File? _midiaSelecionada;
  String _midiaUrlAtual = '';
  bool _salvando = false;

  bool get _editando => widget.exercicio != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.exercicio;
    _nomeController = TextEditingController(text: ex?.nome ?? '');
    _instrucoesController = TextEditingController(text: ex?.instrucoesPassoAPasso ?? '');
    _aquecimentoController = TextEditingController(text: ex?.orientacaoAquecimento ?? '');
    // Campo obrigatório (Quadro 21): começa em branco no exercício novo; um exercício já
    // cadastrado sem contraindicações aparece com "Nenhuma" marcada.
    _contraindicacoesSelecionadas = ex == null
        ? []
        : (ex.contraindicacoes.isEmpty ? [condicaoNenhuma] : List.from(ex.contraindicacoes));
    _midiaUrlAtual = ex?.midiaUrl ?? '';
    _equipamentoId = ex?.equipamentoId ?? widget.equipamentoInicial?.id;
    _equipamentoNome = ex?.equipamentoNome ?? widget.equipamentoInicial?.nome ?? '';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _instrucoesController.dispose();
    _aquecimentoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarMidia() async {
    final picker = ImagePicker();
    final arquivo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (arquivo != null) {
      setState(() => _midiaSelecionada = File(arquivo.path));
    }
  }

  Future<void> _selecionarEquipamento() async {
    final equipamento = await selecionarEquipamento(context);
    if (equipamento != null) {
      setState(() {
        _equipamentoId = equipamento.id;
        _equipamentoNome = equipamento.nome;
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_equipamentoId == null) {
      _mostrarErro('É necessário vincular o exercício a um equipamento para continuar.');
      return;
    }
    if (_contraindicacoesSelecionadas.isEmpty) {
      _mostrarErro('Selecione as contraindicações do exercício ou marque "Nenhuma".');
      return;
    }
    if (_midiaSelecionada == null && _midiaUrlAtual.isEmpty) {
      _mostrarErro('Selecione uma foto para o exercício.');
      return;
    }

    setState(() => _salvando = true);
    try {
      final repositorio = context.read<ExercicioRepository>();
      final id = widget.exercicio?.id ?? repositorio.novoId();

      var midiaUrl = _midiaUrlAtual;
      if (_midiaSelecionada != null) {
        midiaUrl = await context.read<StorageService>().uploadImagemExercicio(
              _midiaSelecionada!,
              id,
            );
      }

      final exercicio = ExercicioModel(
        id: id,
        equipamentoId: _equipamentoId!,
        nome: _nomeController.text,
        midiaUrl: midiaUrl,
        instrucoesPassoAPasso: _instrucoesController.text,
        orientacaoAquecimento: _aquecimentoController.text,
        contraindicacoes: semNenhuma(_contraindicacoesSelecionadas),
      );

      await repositorio.salvar(exercicio);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercício salvo com sucesso.')),
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
      appBar: AppBar(title: Text(_editando ? 'Editar Exercício' : 'Novo Exercício')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SeletorMidia(
                  midiaSelecionada: _midiaSelecionada,
                  midiaUrlAtual: _midiaUrlAtual,
                  onTap: _selecionarMidia,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Nome do Exercício',
                  controller: _nomeController,
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe o nome do exercício' : null,
                ),
                const SizedBox(height: 24),
                Text('Equipamento', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _selecionarEquipamento,
                  icon: const Icon(Icons.search),
                  label: Text(_equipamentoNome.isEmpty ? 'Selecionar equipamento' : _equipamentoNome),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Instruções Passo a Passo',
                  controller: _instrucoesController,
                  maxLines: 4,
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe as instruções' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Orientações de Aquecimento',
                  controller: _aquecimentoController,
                  maxLines: 3,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Informe as orientações de aquecimento' : null,
                ),
                const SizedBox(height: 24),
                MultiSelectChips(
                  label: 'Segurança e Contraindicações',
                  opcoes: condicoesSaudeDisponiveis,
                  opcaoExclusiva: condicaoNenhuma,
                  selecionados: _contraindicacoesSelecionadas,
                  onChanged: (novaLista) =>
                      setState(() => _contraindicacoesSelecionadas = novaLista),
                ),
                const SizedBox(height: 8),
                Text(
                  'Marque as condições de saúde para as quais o exercício não é indicado '
                  '(o usuário com uma delas recebe um aviso), ou "Nenhuma".',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
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
                      child: PrimaryButton(
                        label: 'Salvar Exercício',
                        loading: _salvando,
                        onPressed: _salvar,
                      ),
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

class _SeletorMidia extends StatelessWidget {
  const _SeletorMidia({
    required this.midiaSelecionada,
    required this.midiaUrlAtual,
    required this.onTap,
  });

  final File? midiaSelecionada;
  final String midiaUrlAtual;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget conteudo;
    if (midiaSelecionada != null) {
      conteudo = Image.file(midiaSelecionada!, fit: BoxFit.cover);
    } else if (midiaUrlAtual.isNotEmpty) {
      conteudo = Image.network(midiaUrlAtual, fit: BoxFit.cover);
    } else {
      conteudo = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text('Toque para adicionar uma foto', style: TextStyle(color: Colors.grey)),
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
