import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/equipamento_model.dart';
import '../../models/exercicio_model.dart';
import '../../services/equipamento_repository.dart';
import '../../services/exercicio_repository.dart';
import '../exercicios/exercicio_guia_screen.dart';

/// RF005 - Visualizar Detalhes do Equipamento (Quadro 20, Figura 12).
class EquipamentoDetalheScreen extends StatelessWidget {
  const EquipamentoDetalheScreen({super.key, required this.equipamentoId});

  final String equipamentoId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Equipamento')),
      body: FutureBuilder<EquipamentoModel?>(
        future: context.read<EquipamentoRepository>().buscarPorId(equipamentoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final equipamento = snapshot.data;
          if (equipamento == null) {
            return const Center(child: Text('Equipamento não encontrado.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BadgeNivel(nivel: equipamento.nivelDificuldade.label),
                const SizedBox(height: 12),
                Text(equipamento.nome, style: Theme.of(context).textTheme.titleLarge),
                if (equipamento.descricao.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(equipamento.descricao, style: Theme.of(context).textTheme.bodyLarge),
                ],
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: equipamento.imagemUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: equipamento.imagemUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                        ),
                ),
                if (equipamento.paraQueServe.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SecaoTitulo('Para que serve'),
                  const SizedBox(height: 8),
                  Text(equipamento.paraQueServe, style: Theme.of(context).textTheme.bodyLarge),
                ],
                if (equipamento.beneficios.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SecaoTitulo('Benefícios'),
                  const SizedBox(height: 8),
                  ...equipamento.beneficios.map(
                    (beneficio) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(beneficio, style: Theme.of(context).textTheme.bodyLarge),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (equipamento.dicaDeOuro.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Dica de Ouro: ${equipamento.dicaDeOuro}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // RF007 - cada equipamento pode ter várias instruções/avisos.
                const SizedBox(height: 24),
                _SecaoTitulo('Instruções de Uso'),
                ...equipamento.instrucoes.map(
                  (instrucao) => Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(instrucao.instrucaoUso, style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Aviso de Segurança: ${instrucao.avisoSeguranca}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // RF006 - exercícios vinculados a este equipamento.
                const SizedBox(height: 24),
                _SecaoTitulo('Exercícios com este equipamento'),
                const SizedBox(height: 8),
                FutureBuilder<List<ExercicioModel>>(
                  future: context.read<ExercicioRepository>().buscarPorEquipamento(equipamentoId),
                  builder: (context, snapshotExercicios) {
                    if (snapshotExercicios.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final exercicios = snapshotExercicios.data ?? [];
                    if (exercicios.isEmpty) {
                      return Text(
                        'Nenhum exercício cadastrado para este equipamento ainda.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                      );
                    }
                    return Column(
                      children: exercicios
                          .map(
                            (exercicio) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.directions_run),
                                title: Text(exercicio.nome),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ExercicioGuiaScreen(exercicioId: exercicio.id),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SecaoTitulo extends StatelessWidget {
  const _SecaoTitulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(texto, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _BadgeNivel extends StatelessWidget {
  const _BadgeNivel({required this.nivel});
  final String nivel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        nivel,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}
