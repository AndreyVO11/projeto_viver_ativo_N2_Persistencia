import 'package:flutter_test/flutter_test.dart';
import 'package:viver_ativo/models/usuario_model.dart';

void main() {
  group('UsuarioModel.fromMap', () {
    test('lê nome, telefone, is_admin e is_admin_inicial', () {
      final usuario = UsuarioModel.fromMap('uid-1', {
        'nome': 'Andrey',
        'telefone': '64999999999',
        'is_admin': true,
        'is_admin_inicial': true,
      });

      expect(usuario.id, 'uid-1');
      expect(usuario.nome, 'Andrey');
      expect(usuario.telefone, '64999999999');
      expect(usuario.isAdmin, isTrue);
      expect(usuario.isAdminInicial, isTrue);
    });

    test('is_admin e is_admin_inicial são false por padrão quando ausentes', () {
      final usuario = UsuarioModel.fromMap('uid-1', {'nome': 'Andrey', 'telefone': '64999999999'});

      expect(usuario.isAdmin, isFalse);
      expect(usuario.isAdminInicial, isFalse);
    });

    test('extrai as condições de saúde do join usuario_condicao_saude', () {
      final usuario = UsuarioModel.fromMap('uid-1', {
        'nome': 'Andrey',
        'telefone': '64999999999',
        'usuario_condicao_saude': [
          {'condicoes_saude': {'nome': 'Hipertensão'}},
          {'condicoes_saude': {'nome': 'Problemas no joelho'}},
        ],
      });

      expect(usuario.condicoesSaude, ['Hipertensão', 'Problemas no joelho']);
    });

    test('"Nenhuma" gravada em registro antigo não vira condição de saúde', () {
      final usuario = UsuarioModel.fromMap('u-1', {
        'nome': 'Maria',
        'usuario_condicao_saude': [
          {'condicoes_saude': {'nome': 'Nenhuma'}},
        ],
      });

      expect(usuario.condicoesSaude, isEmpty);
    });

    test('sem vínculos de condição de saúde retorna lista vazia (não nula)', () {
      final usuario = UsuarioModel.fromMap('uid-1', {'nome': 'Andrey', 'telefone': '64999999999'});

      expect(usuario.condicoesSaude, isEmpty);
    });
  });

  group('UsuarioModel.toMap / copyWith', () {
    test('toMap gera as colunas snake_case da tabela usuarios', () {
      const usuario = UsuarioModel(
        id: 'uid-1',
        nome: 'Andrey',
        telefone: '64999999999',
        isAdmin: true,
        isAdminInicial: false,
      );

      final map = usuario.toMap();

      expect(map, {
        'nome': 'Andrey',
        'telefone': '64999999999',
        'is_admin': true,
        'is_admin_inicial': false,
      });
    });

    test('copyWith altera só os campos informados', () {
      const original = UsuarioModel(id: 'uid-1', nome: 'Andrey', telefone: '64999999999');

      final atualizado = original.copyWith(nome: 'Andrey Vieira');

      expect(atualizado.id, original.id);
      expect(atualizado.nome, 'Andrey Vieira');
      expect(atualizado.telefone, original.telefone);
    });
  });
}
