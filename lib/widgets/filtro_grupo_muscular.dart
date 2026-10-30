import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Barra de filtro por grupo muscular (Pernas, Braços, ...), usada nas listas de
/// exercícios e de treinos. É uma única escolha: "Todos" (sem filtro) ou um grupo.
/// As opções rolam na horizontal; com menos de dois grupos não há o que filtrar e a
/// barra não aparece.
class FiltroGrupoMuscular extends StatelessWidget {
  const FiltroGrupoMuscular({
    super.key,
    required this.grupos,
    required this.selecionado,
    required this.onChanged,
  });

  final List<String> grupos;

  /// Grupo escolhido; nulo é a opção "Todos".
  final String? selecionado;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (grupos.length < 2) return const SizedBox.shrink();

    return Material(
      color: AppTheme.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Filtrar por:', style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _chip(label: 'Todos', marcado: selecionado == null, onTap: () => onChanged(null)),
                  for (final grupo in grupos) ...[
                    const SizedBox(width: 8),
                    _chip(label: grupo, marcado: selecionado == grupo, onTap: () => onChanged(grupo)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({required String label, required bool marcado, required VoidCallback onTap}) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: marcado ? Colors.white : AppTheme.textPrimary,
        ),
      ),
      selected: marcado,
      showCheckmark: false,
      selectedColor: AppTheme.primary,
      backgroundColor: Colors.white,
      side: BorderSide(color: marcado ? AppTheme.primary : Colors.grey.shade500),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      onSelected: (_) => onTap(),
    );
  }
}
