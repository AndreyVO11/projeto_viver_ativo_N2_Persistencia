import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/historico_model.dart';
import '../../models/treino_model.dart';
import '../../services/auth_service.dart';
import '../../services/treino_repository.dart';
import '../../utils/filtro_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/filtro_grupo_muscular.dart';
import 'treino_execucao_screen.dart';

/// RF009 - Visualizar Lista de Treinos (Figura 22).
class TreinosListScreen extends StatefulWidget {
  const TreinosListScreen({super.key});

  @override
  State<TreinosListScreen> createState() => _TreinosListScreenState();
}

class _TreinosListScreenState extends State<TreinosListScreen> {
  late Future<List<TreinoModel>> _futureTreinos;
  late Future<Map<String, Set<String>>> _futureProgresso;

  /// Tipo de treino escolhido na barra de filtro; nulo é "Todos".
  String? _tipo;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    final repositorio = context.read<TreinoRepository>();
    _futureTreinos = repositorio.buscarTreinos();
    // Se a consulta do progresso falhar, a lista só não mostra "Em andamento".
    _futureProgresso = repositorio
        .buscarProgressoEmAndamento(context.read<AuthService>().currentUserId!)
        .catchError((_) => <String, Set<String>>{});
  }

  Future<void> _recarregar() async {
    setState(_carregar);
    await _futureTreinos;
  }

  Future<void> _abrirTreino(TreinoModel treino) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TreinoExecucaoScreen(treinoId: treino.id)),
    );
    if (mounted) setState(_carregar); // atualiza o "Em andamento" ao voltar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Treinos')),
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
                  EmptyState(mensagem: 'Nenhum treino disponível no momento.', icon: Icons.fitness_center),
                ],
              ),
            );
          }
          final tipos = gruposPresentes(treinos.map((t) => t.tipos));
          // Se o tipo escolhido deixou de existir (ex.: lista atualizada), volta para "Todos".
          final tipoAtivo = tipos.contains(_tipo) ? _tipo : null;
          final visiveis = filtrarPorGrupo(treinos, tipoAtivo, (t) => t.tipos);
          return Column(
            children: [
              FiltroGrupoMuscular(
                grupos: tipos,
                selecionado: tipoAtivo,
                onChanged: (tipo) => setState(() => _tipo = tipo),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _recarregar,
                  child: FutureBuilder<Map<String, Set<String>>>(
                    future: _futureProgresso,
                    builder: (context, snapshotProgresso) {
                      final progresso = snapshotProgresso.data ?? const <String, Set<String>>{};
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: visiveis.length,
                        itemBuilder: (context, index) {
                          final treino = visiveis[index];
                          // Só conta o que o treino tem hoje (o administrador pode ter tirado ou excluído exercícios).
                          final feitos = SessaoEmAndamentoModel.feitosNoTreino(
                            progresso[treino.id],
                            treino.exercicios.map((e) => e.id),
                          );
                          final descricao = treino.descricao.isNotEmpty
                              ? treino.descricao
                              : '${treino.exercicios.length} exercício(s)';
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.fitness_center)),
                              title: Text(treino.nome),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (treino.tipos.isNotEmpty)
                                    Text(
                                      treino.tipos.join(' · '),
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  if (feitos > 0)
                                    Text(
                                      'Em andamento: $feitos de ${treino.exercicios.length} exercícios',
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  Text(descricao),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _abrirTreino(treino),
                            ),
                          );
                        },
                      );
                    },
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
