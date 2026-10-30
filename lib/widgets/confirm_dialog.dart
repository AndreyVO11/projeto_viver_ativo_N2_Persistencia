import 'package:flutter/material.dart';

/// Diálogo de confirmação de exclusão (RF003 A2, RF001 A2, etc.), com o texto
/// padrão usado em todos os fluxos de exclusão do DERS.
Future<bool> confirmarExclusao(
  BuildContext context, {
  required String titulo,
  String mensagem = 'Esta ação não pode ser desfeita.',
}) async {
  final resultado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      // Rola quando a mensagem é longa (ex.: lista de exercícios que serão excluídos junto).
      content: SingleChildScrollView(child: Text(mensagem)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Excluir', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  return resultado ?? false;
}
