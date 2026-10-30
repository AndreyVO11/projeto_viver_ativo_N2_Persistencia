/// Duração em segundos no formato do cronômetro: 03:42 ou, passando de uma
/// hora, 1:02:05.
String formatarDuracao(int segundos) {
  final total = segundos < 0 ? 0 : segundos;
  final horas = total ~/ 3600;
  final minutos = (total % 3600) ~/ 60;
  final restante = total % 60;
  final mm = minutos.toString().padLeft(2, '0');
  final ss = restante.toString().padLeft(2, '0');
  return horas > 0 ? '$horas:$mm:$ss' : '$mm:$ss';
}

/// 17/10/2026
String formatarData(DateTime data) {
  final local = data.toLocal();
  final dd = local.day.toString().padLeft(2, '0');
  final mm = local.month.toString().padLeft(2, '0');
  return '$dd/$mm/${local.year}';
}

/// 17/10/2026 às 13:45
String formatarDataHora(DateTime data) {
  final local = data.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '${formatarData(local)} às $hh:$min';
}
