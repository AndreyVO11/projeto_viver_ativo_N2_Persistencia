import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exercicio_model.dart';
import '../../models/usuario_model.dart';
import '../../services/auth_service.dart';
import '../../services/exercicio_repository.dart';
import '../../services/usuario_repository.dart';
import '../../utils/contraindicacao_utils.dart';
import '../../widgets/cronometro_exercicio.dart';
import '../../widgets/primary_button.dart';

/// RF006 - Guia de execução do exercício (Figura 16), com o fluxo A3/A3.1:
/// cruza as condições de saúde do usuário com as contraindicações cadastradas
/// e exibe um aviso bloqueante antes de liberar o guia, se houver correspondência.
class ExercicioGuiaScreen extends StatefulWidget {
  const ExercicioGuiaScreen({super.key, required this.exercicioId, this.onConcluir});

  final String exercicioId;

  /// RF009 - quando informado (execução de um treino), o guia exibe o cronômetro
  /// ("Iniciar Exercício" / "Concluir Exercício") e entrega o tempo medido, em
  /// segundos. Na navegação direta pelo RF006 (fora de um treino), fica nulo e o
  /// painel não aparece.
  final void Function(int segundos)? onConcluir;

  @override
  State<ExercicioGuiaScreen> createState() => _ExercicioGuiaScreenState();
}

class _ExercicioGuiaScreenState extends State<ExercicioGuiaScreen> {
  late final Future<_DadosGuia> _futureDados;
  bool _avisoConfirmado = false;

  @override
  void initState() {
    super.initState();
    _futureDados = _carregar();
  }

  Future<_DadosGuia> _carregar() async {
    final uid = context.read<AuthService>().currentUserId!;
    final exercicioRepository = context.read<ExercicioRepository>();
    final usuarioRepository = context.read<UsuarioRepository>();
    final exercicio = await exercicioRepository.buscarPorId(widget.exercicioId);
    final usuario = await usuarioRepository.buscarUsuario(uid);
    return _DadosGuia(exercicio: exercicio, usuario: usuario);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guia de Execução')),
      body: FutureBuilder<_DadosGuia>(
        future: _futureDados,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final exercicio = snapshot.data?.exercicio;
          final usuario = snapshot.data?.usuario;
          if (exercicio == null) {
            return const Center(child: Text('Exercício não encontrado.'));
          }

          // Fluxo A3.1 - cruza condições de saúde do usuário com as
          // contraindicações do exercício.
          final contraindicacoesEncontradas = contraindicacoesAplicaveis(
            condicoesSaudeUsuario: usuario?.condicoesSaude ?? const [],
            contraindicacoesExercicio: exercicio.contraindicacoes,
          );
          final precisaAviso = contraindicacoesEncontradas.isNotEmpty && !_avisoConfirmado;

          if (precisaAviso) {
            return _AvisoContraindicacao(
              contraindicacoes: contraindicacoesEncontradas,
              onContinuar: () => setState(() => _avisoConfirmado = true),
              onVoltar: () => Navigator.of(context).pop(),
            );
          }

          final conteudo = SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercicio.nome, style: Theme.of(context).textTheme.titleLarge),
                if (exercicio.equipamentoNome.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Equipamento: ${exercicio.equipamentoNome}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                  ),
                ],
                if (exercicio.midiaUrl.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: exercicio.midiaUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                // RN005 - aquecimento prévio obrigatório, sempre visível antes
                // de qualquer instrução de exercício.
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.self_improvement, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Antes de começar: faça um aquecimento prévio de no mínimo 5 minutos.\n'
                          '${exercicio.orientacaoAquecimento}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Passo a Passo', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(exercicio.instrucoesPassoAPasso, style: Theme.of(context).textTheme.bodyLarge),
                if (exercicio.contraindicacoes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.red),
                            const SizedBox(width: 8),
                            Text('Dicas de Segurança', style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Contraindicado para: ${exercicio.contraindicacoes.join(', ')}.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          );

          if (widget.onConcluir == null) return conteudo;
          return Column(
            children: [
              Expanded(child: conteudo),
              CronometroExercicio(
                onConcluir: (segundos) {
                  widget.onConcluir!(segundos);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DadosGuia {
  final ExercicioModel? exercicio;
  final UsuarioModel? usuario;
  const _DadosGuia({required this.exercicio, required this.usuario});
}

/// RF006, fluxo A3.1 - Exibir Aviso de Contraindicação (Quadro 22/23).
class _AvisoContraindicacao extends StatelessWidget {
  const _AvisoContraindicacao({
    required this.contraindicacoes,
    required this.onContinuar,
    required this.onVoltar,
  });

  final List<String> contraindicacoes;
  final VoidCallback onContinuar;
  final VoidCallback onVoltar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Atenção',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Este exercício pode não ser indicado para quem tem: '
              '${contraindicacoes.join(', ')}. Consulte um profissional de saúde antes de '
              'continuar, se essa for sua condição.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Entendi, continuar', onPressed: onContinuar),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onVoltar, child: const Text('Voltar')),
          ],
        ),
      ),
    );
  }
}
