import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/treino_model.dart';
import '../../services/auth_service.dart';
import '../../services/treino_repository.dart';
import '../../utils/formatacao_utils.dart';
import '../../widgets/primary_button.dart';
import '../exercicios/exercicio_guia_screen.dart';

/// RF009, fluxo A1 - Executar Treino: lista os exercícios do treino em ordem
/// sequencial, com status pendente/concluído, e registra cada exercício concluído
/// (com o tempo medido) no histórico do usuário.
///
/// O treino continua de onde parou: se a pessoa sair no meio, ao voltar os
/// exercícios já feitos reaparecem concluídos, e o treino só se encerra quando
/// todos forem feitos. Depois de concluído, é possível fazê-lo novamente; a pessoa
/// também pode recomeçar um treino em andamento.
class TreinoExecucaoScreen extends StatefulWidget {
  const TreinoExecucaoScreen({super.key, required this.treinoId});

  final String treinoId;

  @override
  State<TreinoExecucaoScreen> createState() => _TreinoExecucaoScreenState();
}

class _TreinoExecucaoScreenState extends State<TreinoExecucaoScreen> {
  late final Future<TreinoModel?> _futureTreino;

  /// exercício concluído -> segundos gastos nele.
  final Map<String, int> _concluidos = {};
  String? _sessaoId;

  /// Preenchido quando o treino foi retomado de uma sessão anterior.
  DateTime? _retomadoDe;
  bool _parabenizacaoExibida = false;

  @override
  void initState() {
    super.initState();
    _futureTreino = _carregar();
  }

  Future<TreinoModel?> _carregar() async {
    final uid = context.read<AuthService>().currentUserId!;
    final repositorio = context.read<TreinoRepository>();
    final treino = await repositorio.buscarPorId(widget.treinoId);
    if (treino == null) return null;

    final sessao = await repositorio.buscarSessaoEmAndamento(uid, widget.treinoId);
    if (sessao == null) return treino;

    // Só conta o que ainda existe no treino (o administrador pode tê-lo editado).
    final idsDoTreino = treino.exercicios.map((e) => e.id).toSet();
    final feitos = {
      for (final entrada in sessao.duracoes.entries)
        if (idsDoTreino.contains(entrada.key)) entrada.key: entrada.value,
    };

    if (treino.exercicios.isNotEmpty && feitos.length >= treino.exercicios.length) {
      // Já estava tudo feito (ex.: exercícios pendentes foram removidos do treino).
      await repositorio.concluirSessao(sessao.id);
    } else {
      // Sessão aberta mas ainda sem exercícios (ex.: a pessoa tocou em "Recomeçar
      // treino" e saiu): reaproveita, em vez de abrir outra.
      _sessaoId = sessao.id;
      if (feitos.isNotEmpty) {
        _concluidos.addAll(feitos);
        _retomadoDe = sessao.iniciadoEm;
      }
    }
    return treino;
  }

  Future<void> _abrirExercicio(TreinoModel treino, ExercicioDoTreino exercicio) async {
    final jaConcluido = _concluidos.containsKey(exercicio.id);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExercicioGuiaScreen(
          exercicioId: exercicio.id,
          // Exercício já feito: só consulta o guia, sem cronômetro nem novo registro.
          onConcluir: jaConcluido ? null : (segundos) => _concluirExercicio(treino, exercicio, segundos),
        ),
      ),
    );
  }

  Future<void> _concluirExercicio(TreinoModel treino, ExercicioDoTreino exercicio, int segundos) async {
    final uid = context.read<AuthService>().currentUserId!;
    final repositorio = context.read<TreinoRepository>();
    try {
      _sessaoId ??= await repositorio.iniciarSessao(
        usuarioId: uid,
        treinoId: treino.id,
        treinoNome: treino.nome,
        totalExercicios: treino.exercicios.length,
      );
      await repositorio.registrarExecucao(
        sessaoId: _sessaoId!,
        usuarioId: uid,
        treinoId: treino.id,
        treinoNome: treino.nome,
        exercicioId: exercicio.id,
        exercicioNome: exercicio.nome,
        duracaoSegundos: segundos,
      );
      if (!mounted) return;
      setState(() => _concluidos[exercicio.id] = segundos);
      if (_concluidos.length == treino.exercicios.length) {
        await repositorio.concluirSessao(_sessaoId!);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível registrar o exercício. Tente novamente.')),
        );
      }
    }
  }

  void _comecarDoZero({String? sessaoId}) {
    setState(() {
      _concluidos.clear();
      _sessaoId = sessaoId;
      _retomadoDe = null;
      _parabenizacaoExibida = false;
    });
  }

  /// O que já foi feito continua no histórico (como treino parcial); só a execução
  /// atual volta ao zero. A sessão nova é aberta já, para que a anterior deixe de
  /// ser a "em andamento" mesmo que a pessoa saia sem fazer nenhum exercício.
  Future<void> _confirmarRecomecar(TreinoModel treino) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recomeçar o treino?'),
        content: const Text(
          'Os exercícios que você já fez continuam salvos no histórico, como treino parcial. '
          'O treino começará do primeiro exercício.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar de onde parei'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Recomeçar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    final uid = context.read<AuthService>().currentUserId!;
    final repositorio = context.read<TreinoRepository>();
    try {
      final novaSessao = await repositorio.iniciarSessao(
        usuarioId: uid,
        treinoId: treino.id,
        treinoNome: treino.nome,
        totalExercicios: treino.exercicios.length,
      );
      if (mounted) _comecarDoZero(sessaoId: novaSessao);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível recomeçar o treino. Tente novamente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Executar Treino')),
      body: FutureBuilder<TreinoModel?>(
        future: _futureTreino,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final treino = snapshot.data;
          if (treino == null) {
            return const Center(child: Text('Treino não encontrado.'));
          }

          final concluidosNesteTreino =
              treino.exercicios.where((e) => _concluidos.containsKey(e.id)).length;
          final treinoCompleto =
              treino.exercicios.isNotEmpty && concluidosNesteTreino == treino.exercicios.length;
          final emAndamento = concluidosNesteTreino > 0 && !treinoCompleto;

          if (treinoCompleto && !_parabenizacaoExibida) {
            _parabenizacaoExibida = true;
            final tempoTotal = _concluidos.values.fold(0, (soma, s) => soma + s);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  icon: const Icon(Icons.celebration, color: Colors.amber, size: 48),
                  title: const Text('Parabéns!'),
                  content: Text(
                    'Você concluiu o treino "${treino.nome}" com sucesso.\n'
                    'Tempo total: ${formatarDuracao(tempoTotal)}.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            });
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(treino.nome, style: Theme.of(context).textTheme.titleLarge),
                    if (treino.descricao.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(treino.descricao, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '$concluidosNesteTreino de ${treino.exercicios.length} exercícios concluídos',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                    ),
                    if (_retomadoDe != null && emAndamento) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Text(
                          'Treino em andamento, iniciado em ${formatarDataHora(_retomadoDe!)}. '
                          'Continue de onde parou.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                    if (emAndamento)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _confirmarRecomecar(treino),
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Recomeçar treino'),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: treino.exercicios.length + (treinoCompleto ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == treino.exercicios.length) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
                        child: PrimaryButton(
                          label: 'Fazer o treino novamente',
                          icon: Icons.replay,
                          onPressed: _comecarDoZero,
                        ),
                      );
                    }
                    final exercicio = treino.exercicios[index];
                    final segundos = _concluidos[exercicio.id];
                    final concluido = segundos != null;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: concluido ? Colors.green : Colors.grey.shade300,
                          child: concluido
                              ? const Icon(Icons.check, color: Colors.white)
                              : Text('${index + 1}'),
                        ),
                        title: Text(exercicio.nome),
                        subtitle: Text(concluido ? 'Concluído · ${formatarDuracao(segundos)}' : 'Pendente'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _abrirExercicio(treino, exercicio),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
