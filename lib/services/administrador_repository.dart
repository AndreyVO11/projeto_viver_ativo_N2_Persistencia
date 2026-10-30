import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/usuario_model.dart';

/// RF008 - Manter Administradores.
class AdministradorRepository {
  AdministradorRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<UsuarioModel>> buscarAdministradores() async {
    final linhas = await _client
        .from('usuarios')
        .select('id, nome, telefone, is_admin, is_admin_inicial')
        .eq('is_admin', true)
        .order('nome');
    return linhas.map((linha) => UsuarioModel.fromMap(linha['id'] as String, linha)).toList();
  }

  /// RF008, fluxo A2 - Excluir Administrador.
  ///
  /// Remove apenas o perfil em `usuarios` (o que já revoga o acesso do
  /// administrador às funcionalidades do app). Excluir a conta do Supabase
  /// Auth em si exigiria a service_role key, que não é embutida no cliente
  /// por segurança — fica como possível melhoria futura via uma Edge Function.
  Future<void> excluir(String uid) => _client.from('usuarios').delete().eq('id', uid);
}
