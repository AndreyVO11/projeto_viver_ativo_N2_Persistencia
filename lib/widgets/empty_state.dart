import 'package:flutter/material.dart';

/// Estado vazio (RF004 A1 - "Nenhum equipamento disponível no momento.").
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.mensagem, this.icon = Icons.info_outline});

  final String mensagem;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
