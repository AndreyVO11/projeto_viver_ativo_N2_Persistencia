import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercicio_model.dart';
import '../services/exercicio_repository.dart';

/// RF009, Quadro 30 - "Exercícios Vinculados": caixa de seleção com busca,
/// usada no formulário de treino. [idsExcluidos] evita listar exercícios já
/// adicionados ao treino.
Future<ExercicioModel?> selecionarExercicio(BuildContext context, {List<String> idsExcluidos = const []}) {
  return showModalBottomSheet<ExercicioModel>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ExercicioSelectorSheet(idsExcluidos: idsExcluidos),
  );
}

class _ExercicioSelectorSheet extends StatefulWidget {
  const _ExercicioSelectorSheet({required this.idsExcluidos});

  final List<String> idsExcluidos;

  @override
  State<_ExercicioSelectorSheet> createState() => _ExercicioSelectorSheetState();
}

class _ExercicioSelectorSheetState extends State<_ExercicioSelectorSheet> {
  late Future<List<ExercicioModel>> _futureExercicios;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _futureExercicios = context.read<ExercicioRepository>().buscarExercicios();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.75,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Adicionar Exercício', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar exercício...',
                  ),
                  onChanged: (valor) => setState(() => _busca = valor.toLowerCase()),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<List<ExercicioModel>>(
                    future: _futureExercicios,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final exercicios = (snapshot.data ?? [])
                          .where((e) => !widget.idsExcluidos.contains(e.id))
                          .where((e) => e.nome.toLowerCase().contains(_busca))
                          .toList();
                      if (exercicios.isEmpty) {
                        return const Center(child: Text('Nenhum exercício encontrado.'));
                      }
                      return ListView.builder(
                        itemCount: exercicios.length,
                        itemBuilder: (context, index) {
                          final exercicio = exercicios[index];
                          return ListTile(
                            leading: const Icon(Icons.directions_run),
                            title: Text(exercicio.nome),
                            subtitle: Text(exercicio.equipamentoNome),
                            onTap: () => Navigator.of(context).pop(exercicio),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
