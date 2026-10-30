import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/usuario_model.dart';
import '../../services/administrador_repository.dart';
import '../../services/auth_service.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import 'administrador_form_screen.dart';

/// RF008 - Manter Administradores (Figura 19), acessível somente ao
/// administrador inicial.
class AdministradoresListScreen extends StatefulWidget {
  const AdministradoresListScreen({super.key});

  @override
  State<AdministradoresListScreen> createState() => _AdministradoresListScreenState();
}

class _AdministradoresListScreenState extends State<AdministradoresListScreen> {
  late Future<List<UsuarioModel>> _futureAdministradores;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _futureAdministradores = context.read<AdministradorRepository>().buscarAdministradores();
  }

  Future<void> _recarregar() async {
    setState(_carregar);
    await _futureAdministradores;
  }

  Future<void> _abrirFormulario() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdministradorFormScreen()),
    );
    if (mounted) await _recarregar();
  }

  Future<void> _excluir(UsuarioModel administrador) async {
    if (administrador.id == context.read<AuthService>().currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você não pode excluir a própria conta.')),
      );
      return;
    }
    final confirmado = await confirmarExclusao(
      context,
      titulo: 'Deseja realmente excluir este administrador?',
    );
    if (!confirmado || !mounted) return;
    await context.read<AdministradorRepository>().excluir(administrador.id);
    if (!mounted) return;
    await _recarregar();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Administrador excluído com sucesso.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Administradores')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Novo Administrador'),
      ),
      body: FutureBuilder<List<UsuarioModel>>(
        future: _futureAdministradores,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final administradores = snapshot.data ?? [];
          if (administradores.isEmpty) {
            return RefreshIndicator(
              onRefresh: _recarregar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  EmptyState(
                    mensagem: 'Nenhum administrador cadastrado ainda.',
                    icon: Icons.admin_panel_settings,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _recarregar,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
              itemCount: administradores.length,
              itemBuilder: (context, index) {
                final administrador = administradores[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: Text(administrador.nome),
                    subtitle: Text(
                      administrador.isAdminInicial
                          ? '${administrador.telefone} • Administrador inicial'
                          : administrador.telefone,
                    ),
                    trailing: administrador.isAdminInicial
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Excluir',
                            onPressed: () => _excluir(administrador),
                          ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
