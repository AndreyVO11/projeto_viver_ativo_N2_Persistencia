import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Upload de imagens de equipamento (RF003, Quadro 17 - campo "Imagem do
/// Equipamento") para o bucket público "equipamentos" do Supabase Storage.
class StorageService {
  StorageService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _bucket = 'equipamentos';

  Future<String> uploadImagemEquipamento(File arquivo, String equipamentoId) {
    return _upload(arquivo, 'equipamentos/$equipamentoId');
  }

  /// RF006, Quadro 21 - Foto do exercício (reaproveita o mesmo bucket dos
  /// equipamentos, sob o prefixo "exercicios/", para não exigir criar outro
  /// bucket no Supabase).
  Future<String> uploadImagemExercicio(File arquivo, String exercicioId) {
    return _upload(arquivo, 'exercicios/$exercicioId');
  }

  Future<String> _upload(File arquivo, String caminhoSemExtensao) async {
    final extensao = arquivo.path.split('.').last;
    final caminho = '$caminhoSemExtensao.$extensao';
    await _client.storage.from(_bucket).upload(
          caminho,
          arquivo,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from(_bucket).getPublicUrl(caminho);
  }
}
