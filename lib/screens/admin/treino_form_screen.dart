import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/equipamento_model.dart';
import '../../models/treino_model.dart';
import '../../services/treino_repository.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/exercicio_selector_sheet.dart';
import '../../widgets/multi_select_chips.dart';
import '../../widgets/primary_button.dart';

/// RF009 - Cadastrar/Editar Treino (Quadro 30, Figura 21).
class TreinoFormScreen extends StatefulWidget {
  const TreinoFormScreen({super.key, this.treino});

  final TreinoModel? treino;

  @override
  State<TreinoFormScreen> createState() => _TreinoFormScreenState();
}

class _TreinoFormScreenState extends State<TreinoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _descricaoController;
  late List<ExercicioDoTreino> _exercicios;
  late List<String> _tipos;
  bool _salvando = false;

  bool get _editando => widget.treino != null;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.treino?.nome ?? '');
    _descricaoController = TextEditingController(text: widget.treino?.descricao ?? '');
    _exercicios = List.from(widget.treino?.exercicios ?? const []);
    _tipos = List.from(widget.treino?.tipos ?? const []);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _adicionarExercicio() async {
    final exercicio = await selecionarExercicio(
      context,
      idsExcluidos: _exercicios.map((e) => e.id).toList(),
    );
    if (exercicio != null) {
      setState(() {
        _exercicios.add(ExercicioDoTreino(id: exercicio.id, nome: exercicio.nome, ordem: _exercicios.length));
      });
    }
  }

  void _removerExercicio(int index) {
    setState(() => _exercicios.removeAt(index));
  }

  void _reordenar(int oldIndex, int newIndex) {
    // `onReorderItem` (substituto do `onReorder`, depreciado) já entrega o
    // newIndex ajustado para a remoção do item em oldIndex.
    setState(() {
      final item = _exercicios.removeAt(oldIndex);
      _exercicios.insert(newIndex, item);
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tipos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos um tipo de treino.')),
      );
      return;
    }
    if (_exercicios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O treino deve conter ao menos um exercício.')),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      final repositorio = context.read<TreinoRepository>();
      final id = widget.treino?.id ?? repositorio.novoId();
      final treino = TreinoModel(
        id: id,
        nome: _nomeController.text,
        descricao: _descricaoController.text,
        exercicios: [
          for (var i = 0; i < _exercicios.length; i++)
            ExercicioDoTreino(id: _exercicios[i].id, nome: _exercicios[i].nome, ordem: i),
        ],
        tipos: _tipos,
      );
      await repositorio.salvar(treino);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treino salvo com sucesso.')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar Treino' : 'Novo Treino')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: 'Nome do Treino',
                      controller: _nomeController,
                      validator: (v) => (v == null || v.isEmpty) ? 'Informe o nome do treino' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Descrição',
                      controller: _descricaoController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    MultiSelectChips(
                      label: 'Tipo do Treino',
                      opcoes: gruposMuscularesDisponiveis,
                      selecionados: _tipos,
                      onChanged: (novaLista) => setState(() => _tipos = novaLista),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Exercícios Vinculados', style: Theme.of(context).textTheme.titleMedium),
                        TextButton.icon(
                          // O tema dá largura mínima infinita aos botões de texto; dentro de um
                          // Row isso quebra o layout.
                          style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                          onPressed: _adicionarExercicio,
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar'),
                        ),
                      ],
                    ),
                    if (_exercicios.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Nenhum exercício adicionado ainda. Arraste para reordenar.'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _exercicios.length,
                  onReorderItem: _reordenar,
                  itemBuilder: (context, index) {
                    final exercicio = _exercicios[index];
                    return Card(
                      key: ValueKey(exercicio.id),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(exercicio.nome),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Remover',
                          onPressed: () => _removerExercicio(index),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
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
                        label: 'Salvar Treino',
                        loading: _salvando,
                        onPressed: _salvar,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
