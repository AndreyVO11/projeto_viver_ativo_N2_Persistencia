import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/historico_model.dart';
import '../../services/auth_service.dart';
import '../../services/historico_repository.dart';
import '../../utils/formatacao_utils.dart';
import '../../widgets/empty_state.dart';

/// Histórico do usuário: treinos feitos e exercícios concluídos, com data e tempo.
class HistoricoScreen extends StatelessWidget {
  const HistoricoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meu Histórico'),
          // Cores explícitas: o padrão usa o verde do tema, que some sobre a barra verde.
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            tabs: [Tab(text: 'Treinos'), Tab(text: 'Exercícios')],
          ),
        ),
        body: const TabBarView(children: [_AbaTreinos(), _AbaExercicios()]),
      ),
    );
  }
}

class _AbaTreinos extends StatefulWidget {
  const _AbaTreinos();

  @override
  State<_AbaTreinos> createState() => _AbaTreinosState();
}

class _AbaTreinosState extends State<_AbaTreinos> {
  late Future<List<SessaoTreinoModel>> _future;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    final uid = context.read<AuthService>().currentUserId!;
    _future = context.read<HistoricoRepository>().buscarSessoes(uid);
  }

  Future<void> _recarregar() async {
    setState(_carregar);
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SessaoTreinoModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final sessoes = snapshot.data ?? [];
        if (sessoes.isEmpty) {
          return RefreshIndicator(
            onRefresh: _recarregar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                EmptyState(mensagem: 'Você ainda não fez nenhum treino.', icon: Icons.history),
              ],
            ),
          );
        }
        final concluidas = sessoes.where((s) => s.concluida).length;
        final tempoTotal = sessoes.fold(0, (soma, s) => soma + s.duracaoTotalSegundos);
        return RefreshIndicator(
          onRefresh: _recarregar,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sessoes.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Text(
                    '$concluidas treino(s) concluído(s) · tempo total ${formatarDuracao(tempoTotal)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                );
              }
              return _SessaoCard(sessao: sessoes[index - 1]);
            },
          ),
        );
      },
    );
  }
}

class _SessaoCard extends StatelessWidget {
  const _SessaoCard({required this.sessao});

  final SessaoTreinoModel sessao;

  @override
  Widget build(BuildContext context) {
    final situacao = sessao.concluida
        ? 'Concluído'
        : 'Parcial: ${sessao.exerciciosConcluidos} de ${sessao.totalExercicios} exercícios';
    return Card(
      child: ExpansionTile(
        leading: Icon(
          sessao.concluida ? Icons.check_circle : Icons.timelapse,
          color: sessao.concluida ? Colors.green : Colors.orange,
          size: 32,
        ),
        title: Text(sessao.treinoNome, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
          '${formatarDataHora(sessao.iniciadoEm)}\n$situacao · ${formatarDuracao(sessao.duracaoTotalSegundos)}',
        ),
        children: [
          for (final execucao in sessao.execucoes)
            ListTile(
              leading: const Icon(Icons.check, color: Colors.green),
              title: Text(execucao.exercicioNome, style: Theme.of(context).textTheme.bodyLarge),
              trailing: Text(
                execucao.duracaoSegundos == null ? '—' : formatarDuracao(execucao.duracaoSegundos!),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
        ],
      ),
    );
  }
}

class _AbaExercicios extends StatefulWidget {
  const _AbaExercicios();

  @override
  State<_AbaExercicios> createState() => _AbaExerciciosState();
}

class _AbaExerciciosState extends State<_AbaExercicios> {
  late Future<List<ExecucaoModel>> _future;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    final uid = context.read<AuthService>().currentUserId!;
    _future = context.read<HistoricoRepository>().buscarExecucoes(uid);
  }

  Future<void> _recarregar() async {
    setState(_carregar);
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ExecucaoModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final execucoes = snapshot.data ?? [];
        if (execucoes.isEmpty) {
          return RefreshIndicator(
            onRefresh: _recarregar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                EmptyState(mensagem: 'Nenhum exercício concluído ainda.', icon: Icons.directions_run),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _recarregar,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: execucoes.length,
            itemBuilder: (context, index) {
              final execucao = execucoes[index];
              final detalhe = execucao.treinoNome.isEmpty
                  ? formatarDataHora(execucao.concluidoEm)
                  : '${execucao.treinoNome} · ${formatarDataHora(execucao.concluidoEm)}';
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                  title: Text(execucao.exercicioNome, style: Theme.of(context).textTheme.titleMedium),
                  subtitle: Text(detalhe),
                  trailing: Text(
                    execucao.duracaoSegundos == null ? '—' : formatarDuracao(execucao.duracaoSegundos!),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
