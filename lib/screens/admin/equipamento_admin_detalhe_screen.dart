import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/equipamento_model.dart';
import '../../models/exercicio_model.dart';
import '../../models/instrucao_model.dart';
import '../../services/equipamento_repository.dart';
import '../../services/exercicio_repository.dart';
import '../../services/instrucao_repository.dart';
import '../../widgets/confirm_dialog.dart';
import 'equipamento_form_screen.dart';
import 'exercicio_form_screen.dart';
import 'instrucao_form_screen.dart';

/// RF007 - Manter Instrução de Uso e Aviso de Segurança: tela de detalhes do
/// equipamento (admin), com a seção "Instruções e Segurança" (Figura 17) e os
/// exercícios vinculados a este equipamento (RF006).
class EquipamentoAdminDetalheScreen extends StatefulWidget {
  const EquipamentoAdminDetalheScreen({super.key, required this.equipamentoId});

  final String equipamentoId;

  @override
  State<EquipamentoAdminDetalheScreen> createState() => _EquipamentoAdminDetalheScreenState();
}

class _EquipamentoAdminDetalheScreenState extends State<EquipamentoAdminDetalheScreen> {
  late Future<EquipamentoModel?> _futureEquipamento;
  late Future<List<ExercicioModel>> _futureExercicios;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _futureEquipamento = context.read<EquipamentoRepository>().buscarPorId(widget.equipamentoId);
    _futureExercicios = context.read<ExercicioRepository>().buscarPorEquipamento(widget.equipamentoId);
  }

  Future<void> _recarregar() async {
    setState(_carregar);
    await Future.wait([_futureEquipamento, _futureExercicios]);
  }

  Future<void> _abrirFormularioInstrucao(List<InstrucaoModel> instrucoesAtuais,
      [InstrucaoModel? instrucao]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InstrucaoFormScreen(equipamentoId: widget.equipamentoId, instrucao: instrucao),
      ),
    );
    if (mounted) await _recarregar();
  }

  Future<void> _excluirInstrucao(InstrucaoModel instrucao) async {
    final confirmado = await confirmarExclusao(
      context,
      titulo: 'Deseja realmente excluir esta instrução?',
    );
    if (!confirmado || !mounted) return;
    try {
      await context.read<InstrucaoRepository>().excluir(instrucao.id, widget.equipamentoId);
      if (!mounted) return;
      await _recarregar();
    } on StateError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _abrirFormularioExercicio(EquipamentoModel equipamento, [ExercicioModel? exercicio]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExercicioFormScreen(exercicio: exercicio, equipamentoInicial: equipamento),
      ),
    );
    if (mounted) await _recarregar();
  }

  Future<void> _excluirExercicio(ExercicioModel exercicio) async {
    final confirmado = await confirmarExclusao(
      context,
      titulo: 'Deseja realmente excluir este exercício?',
    );
    if (!confirmado || !mounted) return;
    await context.read<ExercicioRepository>().excluir(exercicio.id);
    if (mounted) await _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Equipamento')),
      body: FutureBuilder<EquipamentoModel?>(
        future: _futureEquipamento,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final equipamento = snapshot.data;
          if (equipamento == null) {
            return const Center(child: Text('Equipamento não encontrado.'));
          }

          return RefreshIndicator(
            onRefresh: _recarregar,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(equipamento.nome, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '${equipamento.tagCategoria} • ${equipamento.nivelDificuldade.label}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EquipamentoFormScreen(equipamento: equipamento),
                      ),
                    );
                    if (mounted) await _recarregar();
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar Dados do Equipamento'),
                ),

                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text('Instruções e Segurança', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                      onPressed: () => _abrirFormularioInstrucao(equipamento.instrucoes),
                      icon: const Icon(Icons.add),
                      label: const Text('Nova Instrução'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (equipamento.instrucoes.isEmpty)
                  const Text('Nenhuma instrução cadastrada ainda.')
                else
                  ...equipamento.instrucoes.map(
                    (instrucao) => Card(
                      child: ListTile(
                        title: Text(instrucao.instrucaoUso, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          'Aviso: ${instrucao.avisoSeguranca}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Editar',
                              onPressed: () =>
                                  _abrirFormularioInstrucao(equipamento.instrucoes, instrucao),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Excluir',
                              onPressed: () => _excluirInstrucao(instrucao),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Exercícios', style: Theme.of(context).textTheme.titleMedium),
                    TextButton.icon(
                      style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                      onPressed: () => _abrirFormularioExercicio(equipamento),
                      icon: const Icon(Icons.add),
                      label: const Text('Novo Exercício'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<ExercicioModel>>(
                  future: _futureExercicios,
                  builder: (context, snapshotExercicios) {
                    if (snapshotExercicios.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final exercicios = snapshotExercicios.data ?? [];
                    if (exercicios.isEmpty) {
                      return const Text('Nenhum exercício cadastrado ainda.');
                    }
                    return Column(
                      children: exercicios
                          .map(
                            (exercicio) => Card(
                              child: ListTile(
                                title: Text(exercicio.nome),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      tooltip: 'Editar',
                                      onPressed: () =>
                                          _abrirFormularioExercicio(equipamento, exercicio),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Excluir',
                                      onPressed: () => _excluirExercicio(exercicio),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
