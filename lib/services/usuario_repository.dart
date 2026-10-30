import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/usuario_model.dart';

class UsuarioRepository {
  UsuarioRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _selectComCondicoes = '''
    id, nome, telefone, is_admin, is_admin_inicial,
    usuario_condicao_saude ( condicoes_saude ( nome ) )
  ''';

  Future<UsuarioModel?> buscarUsuario(String uid) async {
    final linha = await _client
        .from('usuarios')
        .select(_selectComCondicoes)
        .eq('id', uid)
        .maybeSingle();
    if (linha == null) return null;
    return UsuarioModel.fromMap(uid, linha);
  }

  /// RF001, fluxo A1 - Editar informações do cadastro. O telefone (que também é o
  /// identificador de login) é alterado por `AuthService.alterarTelefoneLogin`.
  ///
  /// [condicoesSaude] são só as condições de verdade (sem "Nenhuma"): a lista inteira
  /// substitui a anterior, o que permite atualizar o perfil quando a saúde muda.
  Future<void> atualizarPerfil(
    String uid, {
    required String nome,
    required List<String> condicoesSaude,
  }) async {
    await _client.from('usuarios').update({'nome': nome}).eq('id', uid);

    await _client.from('usuario_condicao_saude').delete().eq('usuario_id', uid);
    if (condicoesSaude.isNotEmpty) {
      final condicoes = await _client
          .from('condicoes_saude')
          .select('id')
          .inFilter('nome', condicoesSaude);
      if (condicoes.isNotEmpty) {
        await _client.from('usuario_condicao_saude').insert([
          for (final condicao in condicoes)
            {'usuario_id': uid, 'condicao_saude_id': condicao['id']},
        ]);
      }
    }
  }
}
