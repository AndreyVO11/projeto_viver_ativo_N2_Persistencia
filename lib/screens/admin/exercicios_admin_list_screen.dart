import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exercicio_model.dart';
import '../../services/exercicio_repository.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import 'exercicio_form_screen.dart';

/// RF006 - Manter Exercício, tela "Gerenciar Exercícios" (Figura 13).
class ExerciciosAdminListScreen extends StatefulWidget {
  const ExerciciosAdminListScreen({super.key});

  @override
  State<ExerciciosAdminListScreen> createState() => _ExerciciosAdminListScreenState();
}

class _ExerciciosAdminListScreenState extends State<ExerciciosAdminListScreen> {
  late Future<List<ExercicioModel>> _futureExercicios;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _futureExercicios = context.read<ExercicioRepository>().buscarExercicios();
  }

  Future<void> _recarregar() async {
    setState(_carregar);
    await _futureExercicios;
  }

  Future<void> _abrirFormulario([ExercicioModel? exercicio]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExercicioFormScreen(exercicio: exercicio)),
    );
    if (mounted) await _recarregar();
  }

  Future<void> _excluir(ExercicioModel exercicio) async {
    final confirmado = await confirmarExclusao(
      context,
      titulo: 'Deseja realmente excluir este exercício?',
    );
    if (!confirmado || !mounted) return;
    await context.read<ExercicioRepository>().excluir(exercicio.id);
    if (!mounted) return;
    await _recarregar();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercício excluído com sucesso.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Exercícios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Novo Exercício'),
      ),
      body: FutureBuilder<List<ExercicioModel>>(
        future: _futureExercicios,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final exercicios = snapshot.data ?? [];
          if (exercicios.isEmpty) {
            return RefreshIndicator(
              onRefresh: _recarregar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  EmptyState(
                    mensagem: 'Nenhum exercício cadastrado ainda.',
                    icon: Icons.directions_run,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _recarregar,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
              itemCount: exercicios.length,
              itemBuilder: (context, index) {
                final exercicio = exercicios[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: exercicio.midiaUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: exercicio.midiaUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.directions_run, color: Colors.grey),
                            ),
                    ),
                    title: Text(exercicio.nome),
                    subtitle: Text('Equipamento: ${exercicio.equipamentoNome}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Editar',
                          onPressed: () => _abrirFormulario(exercicio),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Excluir',
                          onPressed: () => _excluir(exercicio),
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
