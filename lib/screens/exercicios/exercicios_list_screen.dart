import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exercicio_model.dart';
import '../../services/exercicio_repository.dart';
import '../../utils/filtro_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/filtro_grupo_muscular.dart';
import 'exercicio_guia_screen.dart';

/// RF006 - Visualizar Lista de Exercícios (Figura 15).
class ExerciciosListScreen extends StatefulWidget {
  const ExerciciosListScreen({super.key});

  @override
  State<ExerciciosListScreen> createState() => _ExerciciosListScreenState();
}

class _ExerciciosListScreenState extends State<ExerciciosListScreen> {
  late Future<List<ExercicioModel>> _futureExercicios;

  /// Grupo muscular escolhido na barra de filtro; nulo é "Todos".
  String? _grupo;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercícios')),
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
                    mensagem: 'Nenhum exercício disponível no momento.',
                    icon: Icons.directions_run,
                  ),
                ],
              ),
            );
          }
          final grupos = gruposPresentes(exercicios.map((e) => e.equipamentoGrupos));
          // Se o grupo escolhido deixou de existir (ex.: lista atualizada), volta para "Todos".
          final grupoAtivo = grupos.contains(_grupo) ? _grupo : null;
          final visiveis = filtrarPorGrupo(exercicios, grupoAtivo, (e) => e.equipamentoGrupos);
          return Column(
            children: [
              FiltroGrupoMuscular(
                grupos: grupos,
                selecionado: grupoAtivo,
                onChanged: (grupo) => setState(() => _grupo = grupo),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _recarregar,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: visiveis.length,
                    itemBuilder: (context, index) => _ExercicioCard(exercicio: visiveis[index]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExercicioCard extends StatelessWidget {
  const _ExercicioCard({required this.exercicio});

  final ExercicioModel exercicio;

  /// Todos os grupos do equipamento (é por eles que a lista é filtrada); se o
  /// modelo só trouxe a categoria, mostra ela.
  List<String> get grupos => exercicio.equipamentoGrupos.isNotEmpty
      ? exercicio.equipamentoGrupos
      : [if (exercicio.equipamentoCategoria.isNotEmpty) exercicio.equipamentoCategoria];

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ExercicioGuiaScreen(exercicioId: exercicio.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: exercicio.midiaUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: exercicio.midiaUrl,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (grupos.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [for (final grupo in grupos) _etiqueta(context, grupo)],
                      ),
                    const SizedBox(height: 6),
                    Text(exercicio.nome, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Equipamento: ${exercicio.equipamentoNome}',
                      style: Theme.of(context).textTheme.bodyMedium,
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

  Widget _etiqueta(BuildContext context, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 88,
      height: 88,
      color: Colors.grey.shade300,
      child: const Icon(Icons.directions_run, color: Colors.grey, size: 36),
    );
  }
}
