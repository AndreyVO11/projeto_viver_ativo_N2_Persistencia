// Baseline do ponto de dor: listar equipamentos (tela "Equipamentos", RF004).
// Reproduz exatamente a consulta do EquipamentoRepository.buscarEquipamentos():
// um GET no PostgREST do Supabase com join em 3 relações, ordenado por nome.
//
// Uso: dart run n2/benchmark_baseline.dart [N]   (padrão: N = 1000)
import 'dart:convert';
import 'dart:io';

const _base = 'https://pxeqekmtjcedtjznyjgw.supabase.co/rest/v1';
const _key = 'sb_publishable_CmdJJ0CYW2LxTFPiMCxUwQ_VOwhsBnm';

const _select = '''
    id, nome, imagem_url, nivel_dificuldade, descricao, para_que_serve, dica_de_ouro,
    equipamento_grupo_muscular ( grupos_musculares ( nome ) ),
    equipamento_beneficios ( descricao, ordem ),
    equipamento_instrucoes ( id, equipamento_id, instrucao_uso, aviso_seguranca )
  ''';

Future<List<int>> _get(HttpClient http, Uri uri) async {
  final req = await http.getUrl(uri);
  req.headers.set('apikey', _key);
  req.headers.set('Authorization', 'Bearer $_key');
  final resp = await req.close();
  final bytes = await resp.fold<List<int>>([], (a, b) => a..addAll(b));
  if (resp.statusCode != 200) {
    throw HttpException('HTTP ${resp.statusCode}: ${utf8.decode(bytes)}');
  }
  return bytes;
}

Future<void> main(List<String> args) async {
  final n = args.isNotEmpty ? int.parse(args.first) : 1000;
  final http = HttpClient();
  final uri = Uri.parse('$_base/equipamentos').replace(
    queryParameters: {'select': _select.replaceAll(RegExp(r'\s+'), ''), 'order': 'nome'},
  );

  // Tamanho dos dados envolvidos.
  Future<int> linhas(String tabela) async =>
      (jsonDecode(utf8.decode(await _get(http, Uri.parse('$_base/$tabela?select=id')))) as List).length;
  final tamanho = {
    'equipamentos': await linhas('equipamentos'),
    'exercicios': await linhas('exercicios'),
    'treinos': await linhas('treinos'),
  };

  // Aquecimento (não entra na média): abre a conexão TLS.
  for (var i = 0; i < 5; i++) {
    await _get(http, uri);
  }

  final tempos = <double>[];
  var bytesResposta = 0;
  final total = Stopwatch()..start();
  for (var i = 0; i < n; i++) {
    final sw = Stopwatch()..start();
    final corpo = await _get(http, uri);
    sw.stop();
    bytesResposta = corpo.length;
    tempos.add(sw.elapsedMicroseconds / 1000.0);
  }
  total.stop();

  final ordenado = [...tempos]..sort();
  double pct(double p) => ordenado[((ordenado.length - 1) * p).round()];
  final media = total.elapsedMicroseconds / 1000.0 / n;

  final resultado = {
    'operacao': 'GET /equipamentos com join (listar equipamentos)',
    'N': n,
    'tempo_total_s': double.parse((total.elapsedMilliseconds / 1000).toStringAsFixed(2)),
    'tempo_medio_ms': double.parse(media.toStringAsFixed(2)),
    'mediana_ms': double.parse(pct(0.5).toStringAsFixed(2)),
    'p95_ms': double.parse(pct(0.95).toStringAsFixed(2)),
    'min_ms': double.parse(ordenado.first.toStringAsFixed(2)),
    'max_ms': double.parse(ordenado.last.toStringAsFixed(2)),
    'bytes_por_resposta': bytesResposta,
    'linhas_no_banco': tamanho,
    'data': DateTime.now().toIso8601String(),
  };
  http.close();
  final json = const JsonEncoder.withIndent('  ').convert(resultado);
  File('n2/baseline_resultado.json').writeAsStringSync(json);
  stdout.writeln(json);
}
