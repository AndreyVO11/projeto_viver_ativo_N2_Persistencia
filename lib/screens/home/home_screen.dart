import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/usuario_model.dart';
import '../../services/auth_service.dart';
import '../../services/usuario_repository.dart';
import '../admin/administradores_list_screen.dart';
import '../admin/equipamentos_admin_list_screen.dart';
import '../admin/exercicios_admin_list_screen.dart';
import '../admin/treinos_admin_list_screen.dart';
import '../equipamentos/equipamentos_list_screen.dart';
import '../exercicios/exercicios_list_screen.dart';
import '../historico/historico_screen.dart';
import '../perfil/editar_perfil_screen.dart';
import '../perfil/resposta_recuperacao_screen.dart';
import '../treinos/treinos_list_screen.dart';

/// Tela inicial com saudação e acesso às configurações (Figura 5).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<UsuarioModel?> _futureUsuario;
  late Future<bool> _futureTemResposta;

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
  }

  void _carregarUsuario() {
    final auth = context.read<AuthService>();
    _futureUsuario = _buscarComTentativas(context.read<UsuarioRepository>(), auth.currentUserId!);
    // Se a consulta falhar, o aviso simplesmente não é exibido.
    _futureTemResposta = auth.temRespostaRecuperacao().catchError((_) => true);
  }

  /// Logo após o cadastro o perfil ainda pode estar sendo gravado; tenta de novo
  /// por alguns instantes antes de desistir.
  Future<UsuarioModel?> _buscarComTentativas(UsuarioRepository repositorio, String uid) async {
    for (var tentativa = 0; tentativa < 4; tentativa++) {
      final usuario = await repositorio.buscarUsuario(uid);
      if (usuario != null) return usuario;
      await Future.delayed(const Duration(milliseconds: 600));
    }
    return null;
  }

  Future<void> _abrirRespostaRecuperacao() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RespostaRecuperacaoScreen()),
    );
    if (mounted) setState(_carregarUsuario);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return FutureBuilder<UsuarioModel?>(
      future: _futureUsuario,
      builder: (context, snapshot) {
        final usuario = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Viver Ativo'),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.settings),
                tooltip: 'Configurações',
                onSelected: (opcao) async {
                  switch (opcao) {
                    case 'perfil':
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditarPerfilScreen()),
                      );
                      setState(_carregarUsuario);
                      break;
                    case 'recuperacao':
                      await _abrirRespostaRecuperacao();
                      break;
                    case 'sair':
                      auth.logout();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'perfil', child: Text('Editar Perfil')),
                  PopupMenuItem(value: 'recuperacao', child: Text('Resposta de Recuperação')),
                  PopupMenuItem(value: 'sair', child: Text('Sair')),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    usuario == null ? 'Olá!' : 'Olá, ${usuario.nome.split(' ').first}!',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'O que você deseja fazer hoje?',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  FutureBuilder<bool>(
                    future: _futureTemResposta,
                    builder: (context, snapshotResposta) {
                      if (snapshotResposta.data != false) return const SizedBox(height: 32);
                      return Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 32),
                        child: Card(
                          color: Colors.amber.shade50,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _abrirRespostaRecuperacao,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(Icons.shield_outlined, size: 36, color: Colors.amber.shade800),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Proteja sua conta: cadastre a resposta de recuperação de senha.',
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  _MenuCard(
                    icon: Icons.fitness_center,
                    titulo: 'Equipamentos',
                    subtitulo: 'Veja como usar os aparelhos da academia',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EquipamentosListScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MenuCard(
                    icon: Icons.directions_run,
                    titulo: 'Exercícios',
                    subtitulo: 'Veja o passo a passo dos exercícios',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ExerciciosListScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MenuCard(
                    icon: Icons.checklist,
                    titulo: 'Treinos',
                    subtitulo: 'Siga uma sequência de exercícios com acompanhamento',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TreinosListScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MenuCard(
                    icon: Icons.history,
                    titulo: 'Meu Histórico',
                    subtitulo: 'Veja os treinos e exercícios que você já fez',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoricoScreen()),
                    ),
                  ),
                  if (usuario?.isAdmin ?? false) ...[
                    const SizedBox(height: 16),
                    _MenuCard(
                      icon: Icons.admin_panel_settings,
                      titulo: 'Administrar Equipamentos',
                      subtitulo: 'Cadastrar, editar e excluir equipamentos',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EquipamentosAdminListScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _MenuCard(
                      icon: Icons.playlist_add_check,
                      titulo: 'Gerenciar Exercícios',
                      subtitulo: 'Cadastrar, editar e excluir exercícios',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ExerciciosAdminListScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _MenuCard(
                      icon: Icons.checklist_rtl,
                      titulo: 'Gerenciar Treinos',
                      subtitulo: 'Cadastrar, editar e excluir treinos',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TreinosAdminListScreen()),
                      ),
                    ),
                  ],
                  if (usuario?.isAdminInicial ?? false) ...[
                    const SizedBox(height: 16),
                    _MenuCard(
                      icon: Icons.manage_accounts,
                      titulo: 'Gerenciar Administradores',
                      subtitulo: 'Cadastrar e excluir outros administradores',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdministradoresListScreen()),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitulo, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
