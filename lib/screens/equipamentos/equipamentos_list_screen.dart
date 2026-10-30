import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../cache/cache_equipamentos.dart';
import '../../models/equipamento_model.dart';
import '../../services/equipamento_repository.dart';
import '../../widgets/empty_state.dart';
import 'equipamento_detalhe_screen.dart';

/// RF004 - Visualizar Lista de Equipamentos (Quadro 19, Figura 11).
class EquipamentosListScreen extends StatefulWidget {
  const EquipamentosListScreen({super.key});

  @override
  State<EquipamentosListScreen> createState() => _EquipamentosListScreenState();
}

class _EquipamentosListScreenState extends State<EquipamentosListScreen> {
  late Future<List<EquipamentoModel>> _futureEquipamentos;
  String? _infoCache;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar({bool atualizar = false}) {
    final cache = context.read<CacheEquipamentos?>();
    final repositorio = context.read<EquipamentoRepository>();
    _futureEquipamentos = (atualizar ? repositorio.invalidarCache() : Future<void>.value())
        .then((_) => repositorio.buscarEquipamentos())
        .then((lista) {
      if (cache?.ultimoCaminho != null) {
        _infoCache =
            'Cache: ${CacheEquipamentos.descricaoCaminho(cache!.ultimoCaminho!)} • ${cache.ultimoTempoMs!.toStringAsFixed(2)} ms';
      }
      return lista;
    });
  }

  /// Puxar para baixo ignora o cache e consulta o Supabase de novo.
  Future<void> _recarregar() async {
    setState(() => _carregar(atualizar: true));
    await _futureEquipamentos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equipamentos')),
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
                    mensagem: 'Nenhum equipamento disponível no momento.',
                    icon: Icons.fitness_center,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _recarregar,
            child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: equipamentos.length + (_infoCache != null ? 1 : 0),
            itemBuilder: (context, index) {
              if (_infoCache != null) {
                if (index == 0) return _InfoCache(texto: _infoCache!);
                index -= 1;
              }
              return _EquipamentoCard(equipamento: equipamentos[index]);
            },
          ));
        },
      ),
    );
  }
}

class _InfoCache extends StatelessWidget {
  const _InfoCache({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Text(texto, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}

class _EquipamentoCard extends StatelessWidget {
  const _EquipamentoCard({required this.equipamento});

  final EquipamentoModel equipamento;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EquipamentoDetalheScreen(equipamentoId: equipamento.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: equipamento.imagemUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: equipamento.imagemUrl,
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
                    if (equipamento.tagCategoria.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          equipamento.tagCategoria,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(equipamento.nome, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      equipamento.descricao.isNotEmpty
                          ? equipamento.descricao
                          : equipamento.paraQueServe,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EquipamentoDetalheScreen(equipamentoId: equipamento.id),
                          ),
                        ),
                        child: const Text('Ver Instrução'),
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

  Widget _placeholder() {
    return Container(
      width: 88,
      height: 88,
      color: Colors.grey.shade300,
      child: const Icon(Icons.fitness_center, color: Colors.grey, size: 36),
    );
  }
}
