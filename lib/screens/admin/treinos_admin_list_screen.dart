import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/treino_model.dart';
import '../../services/treino_repository.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import 'treino_form_screen.dart';

/// RF009 - Manter Treino, tela "Gerenciar Treinos" (Figura 21).
class TreinosAdminListScreen extends StatefulWidget {
  const TreinosAdminListScreen({super.key});

  @override
  State<TreinosAdminListScreen> createState() => _TreinosAdminListScreenState();
}

class _TreinosAdminListScreenState extends State<TreinosAdminListScreen> {
  late Future<List<TreinoModel>> _futureTreinos;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _futureTreinos = context.read<TreinoRepository>().buscarTreinos();
  }

  Future<void> _recarregar() async {
    setState(_carregar);
    await _futureTreinos;
  }

  Future<void> _abrirFormulario([TreinoModel? treino]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TreinoFormScreen(treino: treino)),
    );
    if (mounted) await _recarregar();
  }

  Future<void> _excluir(TreinoModel treino) async {
    final confirmado = await confirmarExclusao(
      context,
      titulo: 'Deseja realmente excluir este treino?',
    );
    if (!confirmado || !mounted) return;
    await context.read<TreinoRepository>().excluir(treino.id);
    if (!mounted) return;
    await _recarregar();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treino excluído com sucesso.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Treinos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Novo Treino'),
      ),
      body: FutureBuilder<List<TreinoModel>>(
        future: _futureTreinos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final treinos = snapshot.data ?? [];
          if (treinos.isEmpty) {
            return RefreshIndicator(
              onRefresh: _recarregar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  EmptyState(mensagem: 'Nenhum treino cadastrado ainda.', icon: Icons.fitness_center),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _recarregar,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
              itemCount: treinos.length,
              itemBuilder: (context, index) {
                final treino = treinos[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.fitness_center)),
                    title: Text(treino.nome),
                    subtitle: Text('${treino.exercicios.length} exercício(s)'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Editar',
                          onPressed: () => _abrirFormulario(treino),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Excluir',
                          onPressed: () => _excluir(treino),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
