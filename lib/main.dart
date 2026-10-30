import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cache/cache_equipamentos.dart';
import 'cache/fonte_equipamentos_supabase.dart';
import 'screens/home/auth_gate.dart';
import 'services/administrador_repository.dart';
import 'services/auth_service.dart';
import 'services/equipamento_repository.dart';
import 'services/exercicio_repository.dart';
import 'services/historico_repository.dart';
import 'services/instrucao_repository.dart';
import 'services/storage_service.dart';
import 'services/treino_repository.dart';
import 'services/usuario_repository.dart';
import 'supabase_config.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.anonKey);
  // Projeto N2: cache de leitura da lista de equipamentos (arquivo JSON + memória).
  final pasta = await getApplicationSupportDirectory();
  final cache = CacheEquipamentos(
    fonte: FonteEquipamentosSupabase(),
    caminhoArquivo: '${pasta.path}/cache_equipamentos.json',
    registrar: debugPrint,
  );
  runApp(ViverAtivoApp(cache: cache));
}

class ViverAtivoApp extends StatelessWidget {
  const ViverAtivoApp({super.key, this.cache});

  final CacheEquipamentos? cache;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CacheEquipamentos?>.value(value: cache),
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => UsuarioRepository()),
        Provider(create: (_) => EquipamentoRepository(cache: cache)),
        Provider(create: (_) => InstrucaoRepository(cache: cache)),
        Provider(create: (_) => ExercicioRepository()),
        Provider(create: (_) => AdministradorRepository()),
        Provider(create: (_) => TreinoRepository()),
        Provider(create: (_) => HistoricoRepository()),
        Provider(create: (_) => StorageService()),
      ],
      child: MaterialApp(
        title: 'Viver Ativo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const AuthGate(),
      ),
    );
  }
}
