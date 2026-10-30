import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Seleção múltipla em formato de chip, usada para Grupos Musculares
/// (RF003) e Condições de Saúde (RF001).
///
/// [opcaoExclusiva] (ex.: "Nenhuma") não convive com as outras: marcá-la desmarca
/// as demais, e marcar qualquer outra desmarca ela.
class MultiSelectChips extends StatelessWidget {
  const MultiSelectChips({
    super.key,
    required this.label,
    required this.opcoes,
    required this.selecionados,
    required this.onChanged,
    this.opcaoExclusiva,
  });

  final String label;
  final List<String> opcoes;
  final List<String> selecionados;
  final ValueChanged<List<String>> onChanged;
  final String? opcaoExclusiva;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: opcoes.map((opcao) {
            final marcado = selecionados.contains(opcao);
            return FilterChip(
              label: Text(
                opcao,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: marcado ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
              selected: marcado,
              showCheckmark: true,
              checkmarkColor: AppTheme.primary,
              backgroundColor: Colors.white,
              selectedColor: AppTheme.primaryLight.withValues(alpha: 0.25),
              side: BorderSide(
                color: marcado ? AppTheme.primary : Colors.grey.shade500,
                width: marcado ? 1.5 : 1,
              ),
              onSelected: (marcar) {
                var novaLista = List<String>.from(selecionados);
                if (marcar) {
                  if (opcaoExclusiva != null) {
                    if (opcao == opcaoExclusiva) {
                      novaLista = [];
                    } else {
                      novaLista.remove(opcaoExclusiva);
                    }
                  }
                  novaLista.add(opcao);
                } else {
                  novaLista.remove(opcao);
                }
                onChanged(novaLista);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
