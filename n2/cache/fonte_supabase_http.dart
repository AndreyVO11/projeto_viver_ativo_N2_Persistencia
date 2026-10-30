import 'dart:convert';
import 'dart:io';

import 'package:viver_ativo/cache/fonte_equipamentos.dart';

/// Implementação real: PostgREST do Supabase via dart:io (mesma consulta do
/// EquipamentoRepository.buscarEquipamentos()).
class FonteSupabaseHttp implements FonteEscritaEquipamentos {
  FonteSupabaseHttp({HttpClient? http}) : _http = http ?? HttpClient();

  static const _base = 'https://pxeqekmtjcedtjznyjgw.supabase.co/rest/v1';
  static const _key = 'sb_publishable_CmdJJ0CYW2LxTFPiMCxUwQ_VOwhsBnm';
  static const _select =
      'id,nome,imagem_url,nivel_dificuldade,descricao,para_que_serve,dica_de_ouro,'
      'equipamento_grupo_muscular(grupos_musculares(nome)),'
      'equipamento_beneficios(descricao,ordem),'
      'equipamento_instrucoes(id,equipamento_id,instrucao_uso,aviso_seguranca)';
  static const _colunasProprias = {
    'nome', 'imagem_url', 'nivel_dificuldade', 'descricao', 'para_que_serve', 'dica_de_ouro',
  };

  final HttpClient _http;

  Future<String> _enviar(String metodo, Uri uri, {Object? corpo, bool retornar = false}) async {
    final req = await _http.openUrl(metodo, uri);
    req.headers.set('apikey', _key);
    req.headers.set('Authorization', 'Bearer $_key');
    if (retornar) req.headers.set('Prefer', 'return=representation');
    if (corpo != null) {
      req.headers.contentType = ContentType('application', 'json', charset: 'utf-8');
      req.add(utf8.encode(jsonEncode(corpo)));
    }
    final resp = await req.close();
    final texto = await resp.transform(utf8.decoder).join();
    if (resp.statusCode >= 300) throw HttpException('HTTP ${resp.statusCode}: $texto', uri: uri);
    return texto;
  }

  @override
  Future<List<Map<String, dynamic>>> listar() async {
    final uri = Uri.parse('$_base/equipamentos').replace(queryParameters: {'select': _select, 'order': 'nome'});
    final lista = jsonDecode(await _enviar('GET', uri)) as List;
    return lista.cast<Map<String, dynamic>>();
  }

  @override
  Future<void> atualizar(Map<String, dynamic> equipamento) async {
    final id = equipamento['id'] as String;
    final corpo = {for (final e in equipamento.entries) if (_colunasProprias.contains(e.key)) e.key: e.value};
    await _enviar('PATCH', Uri.parse('$_base/equipamentos?id=eq.$id'), corpo: corpo);
  }

  /// Cria uma linha de equipamento (usado só pelo roteiro de demonstração, com dado de teste).
  Future<String> inserir(Map<String, dynamic> equipamento) async {
    final resp = await _enviar('POST', Uri.parse('$_base/equipamentos'), corpo: equipamento, retornar: true);
    return (jsonDecode(resp) as List).first['id'] as String;
  }

  @override
  Future<void> excluir(String id) => _enviar('DELETE', Uri.parse('$_base/equipamentos?id=eq.$id'));

  void fechar() => _http.close();
}
