import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/formatacao_utils.dart';
import 'primary_button.dart';

/// Painel fixo do guia de execução quando o exercício é feito dentro de um treino
/// (RF009, fluxo A1): "Iniciar Exercício" dispara o cronômetro, que pode ser
/// pausado, e "Concluir Exercício" entrega o tempo medido.
///
/// O tempo é calculado pelo relógio (e não somando "ticks"), então não se perde se
/// o aplicativo ficar um instante parado. [agora] existe para os testes.
class CronometroExercicio extends StatefulWidget {
  const CronometroExercicio({super.key, required this.onConcluir, this.agora = DateTime.now});

  final void Function(int segundos) onConcluir;
  final DateTime Function() agora;

  @override
  State<CronometroExercicio> createState() => _CronometroExercicioState();
}

class _CronometroExercicioState extends State<CronometroExercicio> {
  Timer? _timer;
  bool _iniciado = false;
  DateTime? _inicioDoTrecho;
  Duration _acumulado = Duration.zero;

  bool get _emAndamento => _inicioDoTrecho != null;

  int get _segundos {
    final trecho = _emAndamento ? widget.agora().difference(_inicioDoTrecho!) : Duration.zero;
    return (_acumulado + trecho).inSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciar() {
    setState(() {
      _iniciado = true;
      _inicioDoTrecho = widget.agora();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _alternarPausa() {
    setState(() {
      if (_emAndamento) {
        _acumulado += widget.agora().difference(_inicioDoTrecho!);
        _inicioDoTrecho = null;
      } else {
        _inicioDoTrecho = widget.agora();
      }
    });
  }

  void _concluir() {
    final segundos = _segundos;
    _timer?.cancel();
    widget.onConcluir(segundos);
  }

  Future<bool> _confirmarSaida() async {
    final sair = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do exercício?'),
        content: const Text('O tempo marcado será perdido e o exercício não será registrado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar exercício'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return sair ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return PopScope(
      canPop: !_iniciado,
      onPopInvokedWithResult: (jaSaiu, _) async {
        if (jaSaiu) return;
        final sair = await _confirmarSaida();
        if (sair && context.mounted) Navigator.of(context).pop();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))],
        ),
        child: SafeArea(
          top: false,
          child: _iniciado ? _painelEmAndamento(tema) : _painelInicial(),
        ),
      ),
    );
  }

  Widget _painelInicial() {
    return PrimaryButton(label: 'Iniciar Exercício', icon: Icons.play_arrow, onPressed: _iniciar);
  }

  Widget _painelEmAndamento(ThemeData tema) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _emAndamento ? 'Tempo do exercício' : 'Em pausa',
                    style: tema.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                  ),
                  Text(
                    formatarDuracao(_segundos),
                    style: tema.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _emAndamento ? tema.colorScheme.primary : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            // Largura definida: o tema dá aos botões largura mínima infinita.
            SizedBox(
              width: 170,
              child: OutlinedButton.icon(
                onPressed: _alternarPausa,
                icon: Icon(_emAndamento ? Icons.pause : Icons.play_arrow),
                label: Text(_emAndamento ? 'Pausar' : 'Retomar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PrimaryButton(label: 'Concluir Exercício', icon: Icons.check_circle, onPressed: _concluir),
      ],
    );
  }
}
