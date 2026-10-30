import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viver_ativo/widgets/multi_select_chips.dart';

void main() {
  late List<String> selecionados;

  Future<void> montar(WidgetTester tester, {String? opcaoExclusiva, List<String> inicial = const []}) async {
    selecionados = List.from(inicial);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => MultiSelectChips(
              label: 'Condições',
              opcoes: const ['Nenhuma', 'Artrose', 'Diabetes'],
              selecionados: selecionados,
              opcaoExclusiva: opcaoExclusiva,
              onChanged: (lista) => setState(() => selecionados = lista),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> tocar(WidgetTester tester, String rotulo) async {
    await tester.tap(find.widgetWithText(FilterChip, rotulo));
    await tester.pump();
  }

  testWidgets('sem opção exclusiva, as opções se acumulam', (tester) async {
    await montar(tester);

    await tocar(tester, 'Nenhuma');
    await tocar(tester, 'Artrose');

    expect(selecionados, ['Nenhuma', 'Artrose']);
  });

  testWidgets('marcar a opção exclusiva desmarca as outras', (tester) async {
    await montar(tester, opcaoExclusiva: 'Nenhuma', inicial: ['Artrose', 'Diabetes']);

    await tocar(tester, 'Nenhuma');

    expect(selecionados, ['Nenhuma']);
  });

  testWidgets('marcar outra opção desmarca a exclusiva', (tester) async {
    await montar(tester, opcaoExclusiva: 'Nenhuma', inicial: ['Nenhuma']);

    await tocar(tester, 'Artrose');
    expect(selecionados, ['Artrose']);

    await tocar(tester, 'Diabetes');
    expect(selecionados, ['Artrose', 'Diabetes']);
  });

  testWidgets('desmarcar tudo deixa a lista vazia', (tester) async {
    await montar(tester, opcaoExclusiva: 'Nenhuma', inicial: ['Nenhuma']);

    await tocar(tester, 'Nenhuma');

    expect(selecionados, isEmpty);
  });
}
