import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/equipamento_model.dart';
import '../services/equipamento_repository.dart';

/// RF006, Quadro 21 - "Selecionar Equipamento": caixa de seleção com busca,
/// usada no formulário de exercício (todo exercício é vinculado a exatamente
/// um equipamento).
Future<EquipamentoModel?> selecionarEquipamento(BuildContext context) {
  return showModalBottomSheet<EquipamentoModel>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _EquipamentoSelectorSheet(),
  );
}

class _EquipamentoSelectorSheet extends StatefulWidget {
  const _EquipamentoSelectorSheet();

  @override
  State<_EquipamentoSelectorSheet> createState() => _EquipamentoSelectorSheetState();
}

class _EquipamentoSelectorSheetState extends State<_EquipamentoSelectorSheet> {
  late Future<List<EquipamentoModel>> _futureEquipamentos;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _futureEquipamentos = context.read<EquipamentoRepository>().buscarEquipamentos();
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
                Text('Selecionar Equipamento', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar equipamento...',
                  ),
                  onChanged: (valor) => setState(() => _busca = valor.toLowerCase()),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<List<EquipamentoModel>>(
                    future: _futureEquipamentos,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final equipamentos = (snapshot.data ?? [])
                          .where((e) => e.nome.toLowerCase().contains(_busca))
                          .toList();
                      if (equipamentos.isEmpty) {
                        return const Center(child: Text('Nenhum equipamento encontrado.'));
                      }
                      return ListView.builder(
                        itemCount: equipamentos.length,
                        itemBuilder: (context, index) {
                          final equipamento = equipamentos[index];
                          return ListTile(
                            leading: const Icon(Icons.fitness_center),
                            title: Text(equipamento.nome),
                            onTap: () => Navigator.of(context).pop(equipamento),
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
