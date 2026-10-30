import 'package:supabase_flutter/supabase_flutter.dart';

import 'fonte_equipamentos.dart';

/// Fonte da verdade usada pelo app: a mesma consulta com join que o
/// EquipamentoRepository sempre fez, agora atrás da camada de cache.
class FonteEquipamentosSupabase implements FonteEquipamentos {
  FonteEquipamentosSupabase({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const selectCompleto = '''
    id, nome, imagem_url, nivel_dificuldade, descricao, para_que_serve, dica_de_ouro,
    equipamento_grupo_muscular ( grupos_musculares ( nome ) ),
    equipamento_beneficios ( descricao, ordem ),
    equipamento_instrucoes ( id, equipamento_id, instrucao_uso, aviso_seguranca )
  ''';

  @override
  Future<List<Map<String, dynamic>>> listar() async {
    final linhas = await _client.from('equipamentos').select(selectCompleto).order('nome');
    return [for (final linha in linhas) Map<String, dynamic>.from(linha)];
  }
}
