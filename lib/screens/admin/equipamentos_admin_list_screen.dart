import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/equipamento_model.dart';
import '../../services/equipamento_repository.dart';
import '../../services/exercicio_repository.dart';
import '../../utils/exclusao_utils.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import 'equipamento_admin_detalhe_screen.dart';
import 'equipamento_form_screen.dart';

/// RF003 - Manter Equipamentos (Quadro 16, Figura 8/9).
class EquipamentosAdminListScreen extends StatefulWidget {
  const EquipamentosAdminListScreen({super.key});

  @override
  State<EquipamentosAdminListScreen> createState() => _EquipamentosAdminListScreenState();
}

class _EquipamentosAdminListScreenState extends State<EquipamentosAdminListScreen> {
  late Future<List<EquipamentoModel>> _futureEquipamentos;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _futureEquipamentos = context.read<EquipamentoRepository>().buscarEquipamentos();
  }

  Future<void> _recarregar() async {
    setState(_carregar);
    await _futureEquipamentos;
  }

  Future<void> _abrirFormulario([EquipamentoModel? equipamento]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EquipamentoFormScreen(equipamento: equipamento)),
    );
    if (mounted) await _recarregar();
  }

  Future<void> _abrirDetalhes(EquipamentoModel equipamento) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EquipamentoAdminDetalheScreen(equipamentoId: equipamento.id)),
    );
    if (mounted) await _recarregar();
  }

  Future<void> _excluir(EquipamentoModel equipamento) async {
    final repositorio = context.read<EquipamentoRepository>();
    final exercicios = context.read<ExercicioRepository>();

    // Os exercícios vinculados são excluídos junto: o aviso mostra quais são.
    List<String>? nomes;
    try {
      nomes = [for (final e in await exercicios.buscarPorEquipamento(equipamento.id)) e.nome];
    } catch (_) {
      nomes = null; // sem a lista, o aviso diz em geral que eles também serão excluídos
    }
    if (!mounted) return;

    final confirmado = await confirmarExclusao(
      context,
      titulo: 'Deseja realmente excluir este equipamento?',
      mensagem: mensagemExclusaoEquipamento(nomes),
    );
    if (!confirmado || !mounted) return;
    await repositorio.excluir(equipamento.id);
    if (!mounted) return;
    await _recarregar();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Equipamento excluído com sucesso.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Equipamentos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Novo Equipamento'),
      ),
      body: FutureBuilder<List<EquipamentoModel>>(
        future: _futureEquipamentos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final equipamentos = snapshot.data ?? [];
          if (equipamentos.isEmpty) {
            return RefreshIndicator(
              onRefresh: _recarregar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  EmptyState(
                    mensagem: 'Nenhum equipamento cadastrado ainda.',
                    icon: Icons.fitness_center,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _recarregar,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
              itemCount: equipamentos.length,
              itemBuilder: (context, index) {
                final equipamento = equipamentos[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    onTap: () => _abrirDetalhes(equipamento),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: equipamento.imagemUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: equipamento.imagemUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.fitness_center, color: Colors.grey),
                            ),
                    ),
                    title: Text(equipamento.nome),
                    subtitle:
                        Text('${equipamento.tagCategoria} • ${equipamento.nivelDificuldade.label}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Editar',
                          onPressed: () => _abrirFormulario(equipamento),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Excluir',
                          onPressed: () => _excluir(equipamento),
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
